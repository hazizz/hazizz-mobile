import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mobile/blocs/other/comment_section_bloc.dart';
import 'package:mobile/blocs/main_tab/main_tab_blocs.dart';
import 'package:mobile/blocs/other/view_task_bloc.dart';
import 'package:mobile/blocs/tasks/tasks_bloc.dart';
import 'package:mobile/communication/pojos/PojoTag.dart';
import 'package:flutter/material.dart';
import 'package:mobile/communication/pojos/task/PojoTask.dart';
import 'package:mobile/communication/requests/request_collection.dart';
import 'package:mobile/custom/hazizz_logger.dart';
import 'package:mobile/dialogs/dialog_collection.dart';
import 'package:mobile/dialogs/report_dialog.dart';
import 'package:mobile/enums/group_permissions_enum.dart';
import 'package:mobile/managers/deep_link_controller.dart';
import 'package:mobile/managers/google_drive_manager.dart';
import 'package:mobile/managers/firebase_analytics.dart';
import 'package:mobile/storage/cache_manager.dart';
import 'package:mobile/widgets/comment_section_widget.dart';
import 'package:mobile/widgets/flushbars.dart';
import 'package:mobile/widgets/hazizz_back_button.dart';
import 'package:mobile/widgets/image_viewer_widget.dart';
import 'package:mobile/widgets/tag_chip.dart';
import 'package:share/share.dart';
import 'package:snappable/snappable.dart';
import 'package:mobile/custom/hazizz_localizations.dart';
import 'package:mobile/communication/hazizz_response.dart';
import 'package:mobile/theme/hazizz_theme.dart';
import 'package:mobile/communication/request_sender.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mobile/extension_methods/datetime_extension.dart';
import 'package:mobile/extension_methods/duration_extension.dart';
import "package:mobile/extension_methods/string_first_upper_extension.dart";

class ViewTaskPage extends StatefulWidget {

  final CommentSectionWidget commentSectionWidget = CommentSectionWidget();

  final bool fromId;
  final int taskId;
  final PojoTask pojoTask;

  ViewTaskPage.fromId({Key key, this.taskId})
    : assert(taskId != null),
      fromId = true, pojoTask = null,
      super(key: key);

  ViewTaskPage.fromPojo({Key key, this.pojoTask})
    : assert(pojoTask != null),
      fromId = false, taskId = pojoTask.id,
      super(key: key)
  {
    HazizzLogger.printLog("created ViewTaskPage.fromPojo");
  }

  @override
  _ViewTaskPage createState() => _ViewTaskPage();
}

class _ViewTaskPage extends State<ViewTaskPage> {

  final ScrollController _scrollController = ScrollController();

  static final AppBar appBar = AppBar(
    title: Text("what's my purpose?"),
  );

  static final double padding = 4;


  bool completed = true;
  bool isFirstTime = true;

  String _subject = "";
  String _deadline = "";
  String _description = "";
  String _title = "";
  PojoTag mainTag;

  List<PojoTask> taskData = [];

  bool showComments = false;

  PojoTask pojoTask;
  PojoTask originalPojoTask;

  Image img;

  @override
  void initState() {

    void _initializeWidgetData(PojoTask pTask){
      pojoTask = pTask;
      originalPojoTask = pojoTask;
      FirebaseAnalyticsManager.logOpenedViewTaskPage(pojoTask);
      if(pojoTask.creator.id == CacheManager.getMyIdSafely){
        setState(() {
          canModify = true;
        });
      }
      if(pojoTask.permission == GroupPermissionsEnum.OWNER
          || pojoTask.permission == GroupPermissionsEnum.MODERATOR
      ){
        setState(() {
          canModify = true;
        });
      }

      ViewTaskBloc().reCreate(pojoTask: pojoTask);
    }

    if(widget.fromId){
      getResponse(GetTaskByTaskId(pTaskId: widget.taskId)).then((hazizzResponse){
        if(hazizzResponse.isSuccessful){
          _initializeWidgetData(hazizzResponse.convertedData);
        }else if(hazizzResponse.pojoError != null){
          if(hazizzResponse.pojoError.errorCode == 11){
            setState(() {
              noPermission = true;
            });
          }
        }
      });
    }else{
      _initializeWidgetData(widget.pojoTask);
    }

    super.initState();
  }



  void _processData(BuildContext context, PojoTask pojoTask){
    originalPojoTask = pojoTask;
    setState(() {
      _subject = pojoTask.subject != null ? pojoTask.subject.name : null;
      if(pojoTask.tags != null){
        for(PojoTag t in pojoTask.tags){
          for(PojoTag defT in PojoTag.defaultTags){
            if(t.name ==  defT.name){
              mainTag = t;
            }
          }
        }
      }

      DateTime dateDeadline =  pojoTask.dueDate;
      _deadline = dateDeadline.hazizzShowDateFormat;//"${dateDeadline.day}.${dateDeadline.month}.${dateDeadline.year}";
      _description = pojoTask.description;
      _title = pojoTask.title;

      tagWidgets = [];

      if(pojoTask.tags != null){
        for(PojoTag t in pojoTask.tags){
          if(mainTag == null ||  t.name != mainTag.name){
            tagWidgets.add(
              TagChip(child: Text(t.getDisplayName(context), style: TextStyle(fontSize: 19, ),),
                hasCloseButton: false,
              )
            );
          }
        }
      }

      if(isFirstTime){
        completed = pojoTask.completed;
        isFirstTime = false;
      }
    });
  }

  List<Widget> tagWidgets;

  bool canModify = false;

  final snapKey = GlobalKey<SnappableState>();
  
  bool noPermission = false;

  @override
  Widget build(BuildContext context) {

    if(pojoTask != null) {
      _processData(context, pojoTask);
    }

    return WillPopScope(
      onWillPop: (){
        Navigator.pop(context, pojoTask);
        return Future.value(false);
      },
      child: Scaffold(
        appBar: AppBar(
          leading: HazizzBackButton(onPressed: (){
            Navigator.pop(context, pojoTask);
          },),
          title: Text(localize(context, key: "view_task")),
          actions: <Widget>[
            Builder(
              builder: (context){
                if(pojoTask == null || originalPojoTask.assignation.name.toLowerCase() == "thera") return Container();
                return PopupMenuButton(
                  icon: Icon(FontAwesomeIcons.ellipsisV, size: 20,),
                  onSelected: (value) async {
                    if(value == "report"){
                      bool success = await showReportDialog(context, reportType: ReportTypeEnum.TASK, id: originalPojoTask.id, name: "");
                      if(success != null && success){
                        showReportSuccessFlushBar(context, what: localize(context, key: "task"));
                      }
                    }else if(value == "share"){
                      await Share.share(
                        localize(context, key: "invite_to_task_text_title",
                        args: [DeepLinkController.createLinkToTask(pojoTask.id)])
                      );
                    }
                    else if(value == "snap"){
                      snapKey.currentState.snap();
                    }
                  },
                  itemBuilder: (BuildContext context) {
                    return [
                      PopupMenuItem(
                        value: "share",
                        child: Text(localize(context, key: "share"),
                        ),
                      ),
                      PopupMenuItem(
                        value: "report",
                        child: Text(localize(context, key: "report"),
                          style: TextStyle(color: HazizzTheme.red),
                        ),
                      )
                    ];
                  },
                );
              },
            )
          ],
        ),
        body:Snappable(
          key: snapKey,
          child: RefreshIndicator(
            onRefresh: () async{
             // widget.commentSectionWidget.commentBlocs.commentSectionBloc.add(CommentSectionFetchEvent());
              ViewTaskBloc().commentBlocs.commentSectionBloc.add(CommentSectionFetchEvent());

            },
            child: Builder(
              builder: (context){
                if(noPermission) return Text(localize(context, key: "no_permission_to_view"));
                else if(pojoTask == null) return Center(child:  CircularProgressIndicator(),);
                return Stack(
                    children: [ListView(
                      cacheExtent: 100000000,
                      addAutomaticKeepAlives: true,
                      controller: _scrollController,
                      children: [
                        ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: MediaQuery.of(context).size.height-appBar.preferredSize.height - padding*3 - 16,
                          //  maxHeight: (MediaQuery.of(context).size.height-appBar.preferredSize.height - padding*3)*2,
                            minWidth: MediaQuery.of(context).size.width,
                            maxWidth: MediaQuery.of(context).size.width,
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(padding),
                            child: Card(
                              margin: EdgeInsets.only(bottom: 0),
                              clipBehavior: Clip.antiAliasWithSaveLayer,
                              elevation: 100,
                              child:new Column(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Column(
                                      children: <Widget>[
                                        Container(
                                            color: mainTag != null ? mainTag.getColor(): Theme.of(context).primaryColor,
                                            child: Stack(
                                              children: <Widget>[
                                                Positioned(
                                                  right: 0,
                                                  bottom: 0,
                                                  child: Padding(
                                                    padding: const EdgeInsets.only(right: 6, bottom: 6),
                                                    child: Builder(builder: (context){
                                                      HazizzLogger.printLog("redrawing coz completed: $completed");
                                                      if(completed == null) return Container();

                                                      return Transform.scale(
                                                        scale: 1.36,
                                                        child: Checkbox(
                                                            activeColor: mainTag.name != "_HOMEWORK" ? Colors.green : Colors.black54,
                                                            value: completed,
                                                            onChanged: (val) async {
                                                              setState(() {
                                                                completed = val;
                                                                pojoTask.completed = false;
                                                              });
                                                              HazizzResponse hazizzResponse = await RequestSender().getResponse(
                                                                SetTaskCompleted(pTaskId: pojoTask.id, setCompleted: completed)
                                                              );
                                                              if(hazizzResponse.isError){
                                                                setState(() {
                                                                  completed = !completed;
                                                                  pojoTask.completed = !completed;
                                                                });
                                                              }
                                                            }),
                                                      );
                                                    }),
                                                  ),
                                                ),
                                                Column(
                                                  children: <Widget>[
                                                    Builder(
                                                      builder: (context){
                                                        if(mainTag != null){
                                                          return Padding(
                                                            padding: const EdgeInsets.only(left: 20.0, right: 20.0),
                                                            child: new Row(
                                                              mainAxisAlignment: MainAxisAlignment.center,
                                                              children: [
                                                                new Flexible(
                                                                    child: Text(mainTag.getDisplayName(context),
                                                                      style: TextStyle(
                                                                          fontSize: 32,
                                                                          fontWeight: FontWeight.w800
                                                                      ),
                                                                    )
                                                                ),
                                                              ],
                                                            ),
                                                          );
                                                        }
                                                        return Container();
                                                      },
                                                    ),
                                                    Wrap(
                                                      alignment: WrapAlignment.start,
                                                      spacing: 8,
                                                      crossAxisAlignment: WrapCrossAlignment.center,
                                                      children: tagWidgets,
                                                    ),

                                                    GestureDetector(
                                                      onTap: (){
                                                        showUserInformationDialog(context, creator: pojoTask.creator);
                                                      },
                                                      child: Padding(
                                                        padding: const EdgeInsets.only(left: 16.0, right: 20.0, bottom: 2),
                                                        child: new Row(
                                                          mainAxisAlignment: MainAxisAlignment.start,
                                                          children: [
                                                            Padding(
                                                              padding: const EdgeInsets.only(right: 8.0, left: 3, bottom: 4),
                                                              child: Icon(FontAwesomeIcons.userAlt),
                                                            ),
                                                            new Flexible(
                                                              child: Text(pojoTask.creator.displayName,
                                                                style: TextStyle(fontSize: 19),
                                                              )
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),

                                                    Builder(
                                                      builder: (context){
                                                        if(pojoTask.group != null){
                                                          return GestureDetector(
                                                            onTap: (){
                                                              Navigator.pushNamed(context, "/group/groupId", arguments: originalPojoTask.group);
                                                            },
                                                            child: Padding(
                                                              padding: const EdgeInsets.only(left: 16.0, right: 20.0, bottom: 2),
                                                              child: new Row(
                                                                mainAxisAlignment: MainAxisAlignment.start,
                                                                children: [
                                                                  Padding(
                                                                    padding: const EdgeInsets.only(right: 11.0),
                                                                    child: Icon(FontAwesomeIcons.users),
                                                                  ),
                                                                  new Flexible(
                                                                      child: Text(pojoTask.group.name,
                                                                        style: TextStyle(
                                                                            fontSize: 19
                                                                        ),
                                                                      )
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          );
                                                        }
                                                        return Container();
                                                      },
                                                    ),

                                                    Padding(
                                                      padding: const EdgeInsets.only(left: 16.0, bottom: 4),
                                                      child: new Row(
                                                        mainAxisAlignment: MainAxisAlignment.start,
                                                        children: [
                                                          Padding(
                                                            padding: const EdgeInsets.only(right: 8.0, left: 3),
                                                            child: Icon(FontAwesomeIcons.calendarTimes),
                                                          ),

                                                          new Flexible(
                                                            child: Padding(
                                                              padding: const EdgeInsets.only(top: 4.0, right: 10),
                                                              child:
                                                                  AutoSizeText("$_deadline, "
                                                                      + widget.pojoTask.dueDate.weekdayLocalize(context)
                                                                      + ", "
                                                                      + widget.pojoTask.dueDate.daysDifference(context),
                                                                    maxFontSize: 20,
                                                                    minFontSize: 14,
                                                                    style: TextStyle(
                                                                        fontSize: 19
                                                                    ),
                                                                  ),


                                                              /* FFloat(
                                                                    (_) => Text(widget.pojoTask.dueDate.weekdayLocalize(context)
                                                                              + ", "
                                                                              + widget.pojoTask.dueDate.daysDifference(context),
                                                                              style: TextStyle(fontSize: 18),
                                                                    ),
                                                               // controller: controller2_1,
                                                                color: Theme.of(context).scaffoldBackgroundColor,
                                                                corner: FFloatCorner.all(6),
                                                                margin: EdgeInsets.only(bottom: 10),
                                                                padding: EdgeInsets.only(left: 9, right: 9, top: 3, bottom: 3),
                                                                anchor: Row(
                                                                  children: <Widget>[
                                                                    Text(_deadline,
                                                                      style: TextStyle(
                                                                          fontSize: 20
                                                                      ),
                                                                    ),
                                                                    Text(widget.pojoTask.dueDate.weekdayLocalize(context)
                + ", "
                + widget.pojoTask.dueDate.daysDifference(context),
                                                                      style: TextStyle(
                                                                          fontSize: 20
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                                canTouchOutside: false,
                                                                autoDismissDuration: Duration(milliseconds: 2000),

                                                              ),
                                                             /* Text(_deadline,
                                                                style: TextStyle(
                                                                    fontSize: 20
                                                                ),
                                                              ),*/
                                                              */
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            )
                                        ),
                                        Stack(
                                          children: <Widget>[

                                            Column(
                                              children: <Widget>[
                                                _subject != null ? Container(
                                                    decoration: BoxDecoration(
                                                      borderRadius: BorderRadius.only(bottomRight: Radius.circular(20), bottomLeft: Radius.circular(20)),
                                                      color: mainTag != null ? mainTag.getColor(): Theme.of(context).primaryColor,
                                                    ),
                                                    child: Padding(
                                                      padding: const EdgeInsets.only(left: 12, right: 12),
                                                      child: Text(pojoTask.subject.name.toUpperFirst(),
                                                        style: TextStyle(fontSize: 28),
                                                      ),
                                                    )
                                                ) : Container(),
                                                Builder(
                                                  builder: (context){
                                                    if(_title == null) return Container();
                                                    return Padding(
                                                      padding: const EdgeInsets.only( left: 10,top: 5),
                                                      child: new Row(
                                                        mainAxisAlignment: MainAxisAlignment.start,
                                                        children: [
                                                          new Flexible(
                                                            child: new Text(_title,
                                                              style: TextStyle(fontSize: 26),
                                                            ),
                                                          )
                                                        ],
                                                      ),
                                                    );
                                                  },
                                                ),
                                                Padding(
                                                  padding: const EdgeInsets.only( left: 4, right: 4, top: 4),
                                                  child: new Row(
                                                    mainAxisAlignment: MainAxisAlignment.start,
                                                    children: [
                                                      Flexible(
                                                        child: Builder(
                                                          builder: (context){
                                                            Color textColor = Colors.black;
                                                            if(HazizzTheme.currentThemeIsDark){
                                                              textColor = Colors.white;
                                                            }
                                                            return Markdown(data: _description,
                                                              selectable: false,
                                                              padding:  const EdgeInsets.only(left: 10, top: 10),
                                                              shrinkWrap: true,
                                                              physics: NeverScrollableScrollPhysics(),
                                                              imageBuilder: (uri){
                                                                if(uri.host != "drive.google.com"){
                                                                  return Padding(
                                                                    padding: const EdgeInsets.only(top: 2, bottom: 2),
                                                                    child: ImageViewer.fromNetwork(
                                                                      uri.toString(),key: Key(uri.toString()),
                                                                      heroTag: uri.toString(),
                                                                    )
                                                                  );
                                                                }

                                                                return Padding(
                                                                  padding: const EdgeInsets.only(bottom: 8.0),
                                                                  child: ImageViewer.fromGoogleDrive(
                                                                    uri.toString(),
                                                                    width: MediaQuery.of(context).size.width,
                                                                    heroTag: uri,
                                                                    salt: pojoTask.salt,
                                                                  ),
                                                                );
                                                              },
                                                              styleSheet: MarkdownStyleSheet(
                                                                p:  TextStyle(fontFamily: "Nunito", fontSize: 16, color: textColor),
                                                                h1: TextStyle(fontFamily: "Nunito", fontSize: 28, color: textColor),
                                                                h2: TextStyle(fontFamily: "Nunito", fontSize: 26, color: textColor),
                                                                h3: TextStyle(fontFamily: "Nunito", fontSize: 24, color: textColor),
                                                                h4: TextStyle(fontFamily: "Nunito", fontSize: 22, color: textColor),
                                                                h5: TextStyle(fontFamily: "Nunito", fontSize: 20, color: textColor),
                                                                h6: TextStyle(fontFamily: "Nunito", fontSize: 18, color: textColor),
                                                                a:  TextStyle(fontFamily: "Nunito", color: Colors.blue, decoration: TextDecoration.underline),
                                                              ),
                                                              onTapLink: (String url) async {
                                                                if (await canLaunch(url)) {
                                                                  await launch(url);
                                                                }
                                                              },
                                                            );
                                                          },
                                                        )
                                                      )
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: <Widget>[
                                        BlocBuilder(
                                            bloc: ViewTaskBloc().commentBlocs.commentSectionBloc,
                                            builder: (context, state){

                                              Widget chip = Container();

                                              if(state is CommentSectionLoadedState){
                                                chip = Card(
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(50.0),

                                                  ),
                                                  child: Padding(
                                                    padding: const EdgeInsets.only(left: 5.0, right: 5),
                                                    child: Text(state.items.length.toString()),
                                                  ), color: Colors.red,
                                                );
                                              }

                                              return Stack(
                                                children: <Widget>[
                                                  Padding(
                                                      padding: const EdgeInsets.only(top: 3.0, right: 3),
                                                      child: Builder(
                                                        builder: (context){
                                                          if(originalPojoTask.assignation.name.toLowerCase() == "thera") return Container();
                                                          return FlatButton(
                                                              onPressed: () async {
                                                                setState(() {
                                                                  showComments = true;
                                                                });
                                                                await Future.delayed(50.milliseconds);
                                                                _scrollController.animateTo(_scrollController.position.maxScrollExtent, curve: Curves.ease, duration: 340.milliseconds);
                                                              },

                                                              child: Text(localize(context, key: "comments").toUpperCase(), style: theme(context).textTheme.button)
                                                          );
                                                        },
                                                      )
                                                  ),
                                                  Positioned(top: 0, right: 0,
                                                    child: chip,
                                                  )
                                                ],
                                              );
                                            }
                                        ),
                                        Builder(
                                            builder: (context){
                                              if(canModify){
                                                return Column(
                                                  mainAxisAlignment: MainAxisAlignment.end,
                                                  // crossAxisAlignment: CrossAxisAlignment.end,
                                                  children: <Widget>[
                                                    FlatButton(
                                                      onPressed: () async {
                                                        var editedTask = await Navigator.of(context).pushNamed( "/editTask", arguments: pojoTask);
                                                        if(editedTask != null && editedTask is PojoTask){
                                                          setState(() {
                                                            pojoTask = editedTask;
                                                            _processData(context, pojoTask);
                                                          });
                                                          MainTabBlocs().tasksBloc.add(TasksFetchEvent());
                                                        }
                                                      },
                                                      child: Text(localize(context, key: "edit").toUpperCase(), style: theme(context).textTheme.button,),
                                                    ),
                                                    FlatButton(
                                                      child: Text(localize(context, key: "delete").toUpperCase(), style: TextStyle(color: Colors.red),),
                                                      onPressed: () async {
                                                        if(await showDeleteTaskDialog(context, taskId: widget.taskId)){
                                                          HazizzLogger.printLog("showDeleteTaskDialog : success");

                                                          List<String> splited = pojoTask.description.split("\n![img_");
                                                          if(splited.length > 1){
                                                            await GoogleDriveManager().initialize();
                                                            for(int i = 1; i < splited.length; i++){
                                                              String n = splited[i].split("id=")[1];
                                                              GoogleDriveManager().deleteHazizzImage(n.substring(0, n.length-1));
                                                            }
                                                          }

                                                          Navigator.of(context).pop();
                                                          MainTabBlocs().tasksBloc.add(TasksFetchEvent());
                                                        }else{
                                                          HazizzLogger.printLog("showDeleteTaskDialog: no success");
                                                        }
                                                      },
                                                    ),
                                                  ],
                                                );
                                              }
                                              else return Container();
                                            }
                                        )
                                      ],
                                    ),
                                  ]
                              ),
                            ),
                          ),
                        ),
                        Builder(
                          builder: (BuildContext context){
                            if(showComments) {
                              return Container(
                                width: MediaQuery.of(context).size.width,
                                child: Padding(
                                    padding: EdgeInsets.all(padding),
                                    child:
                                    widget.commentSectionWidget
                                ),
                              );
                            }
                            return Container();
                          },
                        )
                      ],
                    ),
                    ]
                );
              },
            )
          ),
        )
    ),
    );
  }
}
