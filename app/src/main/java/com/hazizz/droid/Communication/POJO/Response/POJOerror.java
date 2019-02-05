package com.hazizz.droid.Communication.POJO.Response;

import android.util.Log;

import lombok.Data;

public class POJOerror{

    private String time = "null";
    private int errorCode = 0;
    private String title = "null";
    private String message = "null";

    public POJOerror(String time, int errorCode, String title, String message){
        Log.e("hey", "the time: " + time + "|");
        if(time == null || time.length() == 0){this.time = "null";}else{this.time = time;}
        this.errorCode = errorCode;
        if(title == null || title.length() == 0){this.title = "null";}else{this.title = title;}
        if(message == null || message.length() == 0){this.message = "null";}else{this.message = message;}

    }
    public String getTime(){
        if(time != null){
            return time;
        }else{
            return "empty";
        }
    }
    public int getErrorCode(){
        return errorCode;
    }
    public String getTitle(){
        if(title != null){
            return title;
        }else{
            return "empty";
        }
    }
    public String getMessage(){
        if(message != null){
            return message;
        }else{
            return "empty";
        }
    }


}
