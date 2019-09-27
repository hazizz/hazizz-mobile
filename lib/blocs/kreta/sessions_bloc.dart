import 'package:bloc/bloc.dart';
import 'package:mobile/blocs/other/request_event.dart';
import 'package:mobile/blocs/other/response_states.dart';
import 'package:mobile/communication/pojos/PojoGroup.dart';
import 'package:mobile/communication/pojos/PojoSession.dart';
import 'package:mobile/communication/pojos/PojoSubject.dart';
import 'package:mobile/communication/pojos/PojoUser.dart';
import 'package:mobile/communication/pojos/task/PojoTask.dart';
import 'package:mobile/communication/requests/request_collection.dart';
import 'package:mobile/custom/hazizz_logger.dart';


import 'package:mobile/communication/request_sender.dart';
import 'package:mobile/communication/hazizz_response.dart';

class SessionsBloc extends Bloc<HEvent, HState> {

  static final SessionsBloc _singleton = new SessionsBloc._internal();
  factory SessionsBloc() {
    return _singleton;
  }
  SessionsBloc._internal();

  @override
  HState get initialState => ResponseEmpty();

  @override
  Stream<HState> mapEventToState(HEvent event) async* {
    if (event is FetchData) {
      try {
        yield ResponseWaiting();
        HazizzResponse hazizzResponse = await RequestSender().getResponse(new KretaGetSessions());

        if(hazizzResponse.isSuccessful){
          List<PojoSession> sessions = hazizzResponse.convertedData;
          yield ResponseDataLoaded(data: sessions);

        }
        if(hazizzResponse.isError){
          yield ResponseError(errorResponse: hazizzResponse);
        }
      } on Exception catch(e){
        HazizzLogger.printLog("log: Exception: ${e.toString()}");
      }
    }
  }
}

/*
class GroupBlocs{
  // static int groupId = 0;
  PojoGroup group;
  SessionsBloc SessionsBloc = new SessionsBloc();
  GroupSubjectsBloc groupSubjectsBloc = new GroupSubjectsBloc();
  GroupMembersBloc groupMembersBloc = new GroupMembersBloc();

  static final GroupBlocs _singleton = new GroupBlocs._internal();
  factory GroupBlocs() {
    return _singleton;
  }
  GroupBlocs._internal();

  void newGroup(PojoGroup group){
    this.group = group;
    SessionsBloc.dispatch(FetchData());
    groupSubjectsBloc.dispatch(FetchData());
    groupMembersBloc.dispatch(FetchData());
  }

}
*/





