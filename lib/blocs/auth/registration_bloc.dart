import 'dart:async';


import 'package:flutter/material.dart';
import 'package:mobile/blocs/other/request_event.dart';
import 'package:mobile/blocs/other/response_states.dart';
import 'package:mobile/blocs/other/text_form_bloc.dart';
import 'package:mobile/communication/errorcode_collection.dart';
import 'package:mobile/communication/requests/request_collection.dart';
import 'package:meta/meta.dart';
import 'package:bloc/bloc.dart';
import 'package:mobile/custom/hazizz_logger.dart';
import 'package:mobile/communication/request_sender.dart';
import 'package:mobile/communication/hazizz_response.dart';
import 'package:mobile/exceptions/exceptions.dart';


//region Registration events
abstract class RegistrationEvent extends HEvent {
  RegistrationEvent([List props = const []]) : super(props);
}

class RegisterButtonPressed extends RegistrationEvent {
  final String username;
  final String email;
  final String password;

  RegisterButtonPressed({
    @required this.username,
    @required this.email,
    @required this.password,
  });

  @override
  String toString() =>
      'RegisterButtonPressed { username: $username, password: $password }';
  @override
  List<Object> get props => ([username, email, password]);
}
//endregion

//region Registration states
abstract class RegistrationState extends HState {
  RegistrationState([List props = const []]) : super(props);
}

class RegisterInitial extends RegistrationState {
  @override
  String toString() => 'RegisterInitial';
  @override
  List<Object> get props => null;
}

class RegisterLoading extends RegistrationState {
  @override
  String toString() => 'RegisterLoading';
  @override
  List<Object> get props => null;
}

class RegisterSuccessState extends RegistrationState {

  @override
  String toString() => 'RegisterSuccessState';
  @override
  List<Object> get props => null;
}


//endregion

class RegistrationBloc extends Bloc<RegistrationEvent, RegistrationState> {
  final TextFormBloc usernameBloc;
  final TextFormBloc passwordBloc;

  RegistrationBloc(this.usernameBloc, this.passwordBloc);

  RegistrationState get initialState => RegisterInitial();


  @override
  Stream<RegistrationState> mapEventToState(RegistrationEvent event) async* {
    if (event is RegisterButtonPressed) {
      HazizzLogger.printLog("sentaa1");

      usernameBloc.dispatch(TextFormValidate(text: event.username));
      passwordBloc.dispatch(TextFormValidate(text: event.password));

      HFormState usernameState = usernameBloc.currentState;
      HFormState passwordState = passwordBloc.currentState;
      HazizzLogger.printLog("log: usernameState: ${usernameState.toString()}");
      HazizzLogger.printLog("log: usernameState: ${usernameState.toString()}");

      if(usernameState is TextFormFine) {
        if(passwordState is TextFormFine) { //usernameState is TextFormFine && passwordState is TextFormFine) {
          try {
            HazizzLogger.printLog("sentaa22");
            HazizzResponse hazizzResponse = await RequestSender().getResponse(
                new RegisterUser(
                    b_username: event.username,
                    b_emailAddress: event.email,
                    b_password: event.password
            ));
            if(hazizzResponse.isSuccessful){
              yield RegisterSuccessState();
            }else{
              HazizzLogger.printLog("log: not successful registration!");
            }
          }on HResponseError catch(e) {
            HazizzLogger.printLog("piritos111");
            int errorCode = e.error.errorCode;
            if(ErrorCodes.USERNAME_CONFLICT.equals(errorCode)) {
              HazizzLogger.printLog("piritos222");
              usernameBloc.dispatch(TextFormUsernameTakenEvent());
            }
          }
        }
      }
    }
  }
}

//region TextForm events
class TextFormUsernameTakenEvent extends HFormEvent {
  @override
  String toString() => 'TextFormUsernameTakenEvent';
  @override
  List<Object> get props => null;
}
//endregion

//region TextForm states
class TextFormUsernameTakenState extends HFormState {
  @override
  String toString() => 'TextFormUsernameTakenState';
  @override
  List<Object> get props => null;
}
class TextFormEmailInvalidState extends HFormState {
  @override
  String toString() => 'TextFormEmailInvalid';
  @override
  List<Object> get props => null;
}
//endregion

class RegistrationPageBlocs{
  TextFormBloc usernameBloc = new TextFormBloc(
      validate: (String text){
        if(text.length < 4){
          HazizzLogger.printLog("TextFormErrorTooShort");
          return TextFormErrorTooShort();
        }if(text.length >= 20){
          return TextFormErrorTooLong();
        }
        return TextFormFine();

      },
      handleErrorEvents: (HFormEvent event){
        if(event is TextFormUsernameTakenEvent){
          return TextFormUsernameTakenState();
        }
      }
  );
  TextFormBloc emailBloc = new TextFormBloc(
      validate: (String text){
        final String emailRegex = r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$';
        RegExp regExp = new RegExp(emailRegex);
        if(!regExp.hasMatch(text)) {
          return TextFormEmailInvalidState();
        }
        return TextFormFine();
      }
  );
  TextFormBloc passwordBloc = new TextFormBloc(
      validate: (String text){
        if(text.length < 8) {
          return TextFormErrorTooShort();
        }
        return TextFormFine();
      },
      handleErrorEvents: (HFormEvent event){
        /*if(event is PasswordIncorrectEvent){
          return PasswordIncorrectState();
        }
        */
      }
  );

  RegistrationBloc registrationBloc;

  RegistrationPageBlocs(){
    registrationBloc = new RegistrationBloc(usernameBloc, passwordBloc);
  }
}