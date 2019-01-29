package com.hazizz.droid.Communication;

import android.app.Activity;
import android.content.Context;

import com.hazizz.droid.Network;
import android.util.Log;

import com.hazizz.droid.Communication.POJO.Response.CustomResponseHandler;
import com.hazizz.droid.Communication.Requests.Request;

import java.util.EnumMap;
import java.util.HashMap;
import java.util.concurrent.BlockingQueue;
import java.util.concurrent.LinkedBlockingDeque;

public abstract class MiddleMan{

    public static BlockingQueue<Request> requestQueue = new LinkedBlockingDeque<>(10);
    public static BlockingQueue<Request> waitingForResponseQueue = new LinkedBlockingDeque<>(10);

    public static void cancelAllRequest(){
        for (Request r : requestQueue) {
            r.cancelRequest();
        }
        for (Request r : waitingForResponseQueue) {
            r.cancelRequest();
        }
    }

    public static void cancelAndSaveAllRequests() {
        for (Request r : requestQueue) {
            r.cancelRequest();
            try {
                requestQueue.put(r);
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
        }
    }

    public static void addToCallAgain(Request r) {
        try {
            requestQueue.put(r);
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
    }


    public static void newRequest(Request newRequest) {
        for (Request r : requestQueue)
            if (r.requestType.getClass() == newRequest.requestType.getClass()) {
                requestQueue.remove(r);
            }
        if(Network.getActiveNetwork(newRequest.getActivity()) == null || !Network.isConnectedOrConnecting(newRequest.getActivity())) {
            newRequest.getResponseHandler().onNoConnection();
        }
        try {
            requestQueue.put(newRequest);
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
    }

    public static void gotRequestResponse(Request r){
        waitingForResponseQueue.remove(r);
    }

    public static void callAgain(){
        for(Request r : requestQueue) {
            Log.e("hey", "call again: " + r.requestType);
            r.requestType.setupCall();
            r.requestType.makeCallAgain();
        }



    }

    public static void sendRequestsFromQ() {
        for (Request request : requestQueue) {
            request.requestType.setupCall();
            request.requestType.makeCall();
            try {
                waitingForResponseQueue.put(request);
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
        }
        for(Request r : waitingForResponseQueue){
            requestQueue.remove(r);
        }
    }
}