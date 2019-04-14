package com.hazizz.droid.Communication.Requests;

import android.app.Activity;
import android.util.Log;

import com.hazizz.droid.Communication.POJO.Response.CustomResponseHandler;
import com.hazizz.droid.Communication.Requests.Parent.Request;

import okhttp3.ResponseBody;
import retrofit2.Response;

public class DeleteAnnouncement extends Request {
    public DeleteAnnouncement(Activity act, CustomResponseHandler rh) {
        super(act, rh);
        Log.e("hey", "created UpdateTask object");
    }


    public void setupCall() {

        headerMap.put(HEADER_AUTH, getHeaderAuthToken());
     //   call = aRequest.deleteAnnouncement(vars.get(Strings.Path.GROUPID).toString(), vars.get(Strings.Path.ANNOUNCEMENTID).toString(), headerMap); //Integer.toString(groupID)
    }
    @Override
    public void callIsSuccessful(Response<ResponseBody> response) {
        cOnResponse.onSuccessfulResponse();
    }
}