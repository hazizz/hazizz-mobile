import 'package:bloc/bloc.dart';
import 'package:mobile/blocs/request_event.dart';
import 'package:mobile/blocs/response_states.dart';
import 'package:mobile/communication/pojos/PojoError.dart';
import 'package:mobile/communication/pojos/PojoGroup.dart';
import 'package:mobile/communication/pojos/PojoSubject.dart';
import 'package:mobile/communication/pojos/PojoUser.dart';
import 'package:mobile/communication/pojos/task/PojoTask.dart';
import 'package:mobile/communication/requests/request_collection.dart';


import '../RequestSender.dart';


class MyGroupsBloc extends Bloc<HEvent, HState> {
  @override
  HState get initialState => ResponseEmpty();

  @override
  Stream<HState> mapEventToState(HEvent event) async* {
    if (event is FetchData) {
      try {
        yield ResponseWaiting();
        dynamic responseData = await RequestSender().getResponse(new GetMyGroups());

        if(responseData is List<PojoGroup>){
          List<PojoGroup> groups = responseData;
          if(groups.isNotEmpty) {
            yield ResponseDataLoaded(data: responseData);
          }else{
            yield ResponseEmpty();
          }
        }
        if(responseData is PojoError){
          yield ResponseError(error: responseData);
        }
      } on Exception catch(e){
        print("log: Exception: ${e.toString()}");
      }
    }
  }
}