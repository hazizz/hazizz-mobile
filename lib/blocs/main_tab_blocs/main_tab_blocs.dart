import 'package:bloc/bloc.dart';
import 'package:mobile/communication/pojos/PojoError.dart';
import 'package:mobile/communication/pojos/PojoGrades.dart';
import 'package:mobile/communication/pojos/PojoSchedules.dart';
import 'package:mobile/communication/pojos/task/PojoTask.dart';
import 'package:mobile/communication/requests/request_collection.dart';
import 'package:mobile/managers/preference_services.dart';

import '../../RequestSender.dart';
import '../request_event.dart';
import '../response_states.dart';



class MainTasksBloc extends Bloc<HEvent, HState> {
  List<PojoTask> tasks;

  @override
  HState get initialState => ResponseEmpty();

  @override
  Stream<HState> mapEventToState(HEvent event) async* {
    print("log: Event2: ${event.toString()}");
    if (event is FetchData) {
      try {
        yield ResponseWaiting();
        dynamic responseData = await RequestSender().getResponse(new GetTasksFromMe());
        print("log: responseData: ${responseData}");
        print("log: responseData type:  ${responseData.runtimeType.toString()}");

        if(responseData is List<PojoTask>){
          tasks = responseData;
          if(tasks.isNotEmpty) {
            print("log: response is List");
            yield ResponseDataLoaded(data: responseData);
          }else{
            yield ResponseEmpty();
          }
        }
        if(responseData is PojoError){
          print("log: response is List<PojoTask>");
          yield ResponseError(error: responseData);
        }
      } on Exception catch(e){
        print("log: Exception: ${e.toString()}");
        // yield TasksError();
      }
    }
  }
}

class MainSchedulesBloc extends Bloc<HEvent, HState> {

  PojoSchedules classes;

  @override
  HState get initialState => ResponseEmpty();

  @override
  Stream<HState> mapEventToState(HEvent event) async* {
    if (event is FetchData) {
      try {
        yield ResponseWaiting();
        dynamic responseData = await RequestSender().getResponse(new DummyKretaGetSchedules());

        if(responseData is PojoSchedules){
          classes = responseData;
          if(true) {
            print("log: oy133");
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

class MainGradesBloc extends Bloc<HEvent, HState> {

  PojoGrades grades;

  @override
  HState get initialState => ResponseEmpty();

  @override
  Stream<HState> mapEventToState(HEvent event) async* {
    if (event is FetchData) {
      try {
        yield ResponseWaiting();
            print("log: am0 i here?");

        dynamic responseData = await RequestSender().getResponse(new DummyKretaGetGrades());
        
        
        /*
        PojoGrades responseData = new PojoGrades(
          {"asd1" : [
                PojoGrade(creationDate: DateTime(2010), date: DateTime(2019), grade: "1", gradeType: "mindent eldöntő évvégi jegy", subject: "Nyelvtan", topic: "tz topic", weight: "600%"),
                PojoGrade(creationDate: DateTime(2011), date: DateTime(2019), grade: "1", gradeType: "mindent eldöntő évvégi jegy", subject: "Nyelvtan", topic: "tz topic", weight: "600%"),
                PojoGrade(creationDate: DateTime(2012), date: DateTime(2019), grade: "1", gradeType: "mindent eldöntő évvégi jegy", subject: "Nyelvtan", topic: "tz topic", weight: "600%"),
                PojoGrade(creationDate: DateTime(2013), date: DateTime(2019), grade: "1", gradeType: "mindent eldöntő évvégi jegy", subject: "Nyelvtan", topic: "tz topic", weight: "600%")],

            "asd2" : [
              PojoGrade(creationDate: DateTime(2020), date: DateTime(2019), grade: "1", gradeType: "mindent eldöntő évvégi jegy", subject: "Nyelvtan", topic: "tz topic", weight: "600%"),
              PojoGrade(creationDate: DateTime(2021), date: DateTime(2019), grade: "1", gradeType: "mindent eldöntő évvégi jegy", subject: "Nyelvtan", topic: "tz topic", weight: "600%"),
              PojoGrade(creationDate: DateTime(2022), date: DateTime(2019), grade: "1", gradeType: "mindent eldöntő évvégi jegy", subject: "Nyelvtan", topic: "tz topic", weight: "600%"),
              PojoGrade(creationDate: DateTime(2023), date: DateTime(2019), grade: "1", gradeType: "mindent eldöntő évvégi jegy", subject: "Nyelvtan", topic: "tz topic", weight: "600%")],

          "asd3" : [
            PojoGrade(creationDate: DateTime(2030), date: DateTime(2019), grade: "1", gradeType: "mindent eldöntő évvégi jegy", subject: "Nyelvtan", topic: "tz topic", weight: "600%"),
            PojoGrade(creationDate: DateTime(2031), date: DateTime(2019), grade: "1", gradeType: "mindent eldöntő évvégi jegy", subject: "Nyelvtan", topic: "tz topic", weight: "600%"),
            PojoGrade(creationDate: DateTime(2032), date: DateTime(2019), grade: "1", gradeType: "mindent eldöntő évvégi jegy", subject: "Nyelvtan", topic: "tz topic", weight: "600%"),
            PojoGrade(creationDate: DateTime(2033), date: DateTime(2019), grade: "1", gradeType: "mindent eldöntő évvégi jegy", subject: "Nyelvtan", topic: "tz topic", weight: "600%")]
          }
        );
        */
        if(responseData is PojoGrades){
          grades = responseData;
          if(true) {
            yield ResponseDataLoaded(data: responseData);
          }else{
            yield ResponseEmpty();
          }
        }
        if(responseData is PojoError){
       //   yield ResponseError(error: responseData);
        }
      } on Exception catch(e){
        print("log: Exception: ${e.toString()}");
      }
    }
  }
}

class MainTabBlocs{

  static final MainTabBlocs _singleton = new MainTabBlocs._internal();
  factory MainTabBlocs() {
    return _singleton;
  }
  MainTabBlocs._internal();

  int initialIndex = StartPageService.tasksPage;

  MainTasksBloc tasksBloc = new MainTasksBloc();
  MainSchedulesBloc schedulesBloc = new MainSchedulesBloc();
  MainGradesBloc gradesBloc = new MainGradesBloc();

  void fetchAll(){
    print("log: here455");
    tasksBloc.dispatch(FetchData());
    schedulesBloc.dispatch(FetchData());
    gradesBloc.dispatch(FetchData());
  }

  void initialize()async{
    fetchAll();
    initialIndex = await StartPageService.getStartPageIndex();
  }

}






