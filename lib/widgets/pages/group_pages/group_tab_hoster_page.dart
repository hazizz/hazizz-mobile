import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mobile/blocs/group/group_bloc.dart';
import 'package:mobile/communication/pojos/PojoGroup.dart';
import 'package:mobile/dialogs/dialog_collection.dart';
import 'package:mobile/dialogs/report_dialog.dart';
import 'package:mobile/widgets/flushbars.dart';
import 'package:mobile/widgets/hazizz_back_button.dart';
import 'package:mobile/custom/hazizz_localizations.dart';
import 'package:mobile/theme/hazizz_theme.dart';
import 'group_members_page.dart';
import 'group_subjects_page.dart';
import 'group_tasks_page.dart';
import 'package:mobile/extension_methods/duration_extension.dart';

enum VisitorEnum{
  member,
  newComer,
  notNewComer,
}

class GroupTabHosterPage extends StatefulWidget {

  final PojoGroup group;

  final VisitorEnum visitorEnum;


  GroupTabHosterPage({Key key, @required this.group, @required this.visitorEnum}) : super(key: key);


  @override
  _GroupTabHosterPage createState() => _GroupTabHosterPage();

}

class _GroupTabHosterPage extends State<GroupTabHosterPage> with SingleTickerProviderStateMixin{

  String title = "sad";

  TabController _tabController;

  GroupTasksPage tasksTabPage;
  GroupSubjectsPage  subjectsTabPage;
  GroupMembersPage membersTabPage;

  bool shownVisitorState = false;


  GroupBlocs groupBlocs;


  void _handleTabSelection() {
    setState(() {

    });
  }

  GlobalKey<ScaffoldState> scaffoldState = new GlobalKey();


  @override
  void initState() {
    groupBlocs = new GroupBlocs();
    groupBlocs.newGroup(widget.group);

    tasksTabPage = GroupTasksPage();
    subjectsTabPage = GroupSubjectsPage(groupSubjectsBloc: groupBlocs.groupSubjectsBloc);
    membersTabPage = GroupMembersPage(groupMembersBloc: groupBlocs.groupMembersBloc);

    _tabController = new TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabSelection);



    if(widget.visitorEnum == VisitorEnum.newComer){
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await showJoinedGroupDialog(context, group: widget.group);
        showSubscribeToSubjectDialog(context);
      }
      );
    }else if(widget.visitorEnum == VisitorEnum.notNewComer){

      WidgetsBinding.instance.addPostFrameCallback((_) {
        scaffoldState.currentState.showSnackBar(SnackBar(
          content: Text(localize(context, key: "already_in_group")),
          duration: 3.seconds,
        ));
      });
    }

    /*
    WelcomeManager.getMembers().then((isNewComer){
      if(isNewComer){
        WidgetsBinding.instance.addPostFrameCallback((_) {
          FeatureDiscovery.discoverFeatures(
            context,
            ['discover_group_invite'],
          );
        });
      }
    });
    */



    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    title = "${localize(context, key: "group")}: ${widget.group.name}";
    return Scaffold(
      key: scaffoldState,
     // backgroundColor: widget.color,
      appBar: AppBar(
        leading: HazizzBackButton(),
        title: Padding(
          padding: const EdgeInsets.only(top: 3.0, ),
          child: AutoSizeText(title, style: TextStyle(fontWeight: FontWeight.w700, fontFamily: "Nunito", fontSize: 20), maxLines: 1, maxFontSize: 21, minFontSize: 12,),
        ),
        bottom: TabBar(controller: _tabController, tabs: [
          Tab(text: tasksTabPage.getTabName(context), icon: Icon(FontAwesomeIcons.bookOpen),),
          Tab(text: subjectsTabPage.getTabName(context), icon: Icon(FontAwesomeIcons.solidCalendarAlt)),//, icon: Icon(Icons.scatter_plot)),
          Tab(text: membersTabPage.getTabName(context), icon: Icon(FontAwesomeIcons.users)),//, icon: Icon(Icons.group))

          ]
        ),
        actions: <Widget>[



          PopupMenuButton(
            icon: Icon(FontAwesomeIcons.ellipsisV, size: 20,),
            onSelected: (value) async {
              if(value == "report"){
                bool success = await showReportDialog(context, reportType: ReportTypeEnum.GROUP, id: widget.group.id, name: widget.group.name);
                if(success != null && success){
                  showReportSuccessFlushBar(context, what: localize(context, key: "group"));

                }
              }else if(value == "invite"){
                showInviteDialog(context, group: groupBlocs.group);
              }else if(value == "leave"){
                bool success = await showSureToLeaveGroupDialog(context, groupId: groupBlocs.group.id);
                if(success != null && success){
                  Navigator.pop(context);
                }
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                PopupMenuItem(
                  value: "invite",
                  child: Text(localize(context, key: "invite_others"),
                  ),
                ),
                PopupMenuItem(
                  value: "report",
                  child: Text(localize(context, key: "report"),
                    style: TextStyle(color: HazizzTheme.red),
                  ),
                ),
                PopupMenuItem(
                  value: "leave",
                  child: Text(localize(context, key: "leave"),
                    style: TextStyle(color: HazizzTheme.red),
                  ),
                )
              ];
            },
          ),


          /*
          DescribedFeatureOverlay(
              child: IconButton(
                icon: Icon(FontAwesomeIcons.userPlus),
                onPressed: (){
                  showInviteDialog(context, group: groupBlocs.group);
                },
              ),

              /*
              doAction: (func){
                func();
                HazizzLogger.printLog("CLICKED564: ${func}");
              },
              */
              featureId: 'discover_group_invite',
              icon: FontAwesomeIcons.userPlus,
              color: HazizzTheme.purple,
              contentLocation: ContentOrientation.above, // look at note
              title: locText(context, key: "discover_title_group_invite"),
              description: locText(context, key: "discover_description_group_invite")
          ),
          */
        ],
      ),

      body:
        Stack(
          children: <Widget>[
            TabBarView(
                controller: _tabController,
                children: [
                  tasksTabPage,
                  subjectsTabPage,
                  membersTabPage
                ]
            ),
            /*
            Builder(
              builder: (context){
                HazizzLogger.printLog("GOT HEREEEE0: ");

                if(!shownVisitorState){
                  if(widget.visitorEnum == VisitorEnum.newComer){
                    HazizzLogger.printLog("GOT HEREEEE1");
                  //  Toast.show("Welcome to new group", context, duration: 1);
                    showJoinedGroupDialog(context, group: widget.group);

                  }else if(widget.visitorEnum == VisitorEnum.notNewComer){
                    HazizzLogger.printLog("GOT HEREEEE2");
                  //  showJoinedGroupDialog(context, group: widget.group);
                    SchedulerBinding.instance.addPostFrameCallback((_) =>
                        showJoinedGroupDialog(context, group: widget.group)

                    );

                  //  SnackBar(content: Text("You are already a member of this group"));
                   // Toast.show("You are already a member of this group", context, duration: 1);
                  }


                  SchedulerBinding.instance.addPostFrameCallback((_) =>
                      setState(() {
                        shownVisitorState = true;
                      })
                  );

                }
                return Container();

              },
            )
            */
          ],
        )
    );
  }
}
