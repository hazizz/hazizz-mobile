package com.hazizz.droid.Fragments.GroupTabs;

import android.os.Bundle;
import android.support.annotation.NonNull;
import android.support.annotation.Nullable;
import android.support.v4.app.Fragment;
import android.support.v4.app.FragmentManager;
import android.support.v4.widget.SwipeRefreshLayout;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.AdapterView;
import android.widget.ListView;
import android.widget.TextView;

import com.hazizz.droid.Activities.MainActivity;
import com.hazizz.droid.Communication.POJO.Response.CustomResponseHandler;
import com.hazizz.droid.Communication.POJO.Response.POJOerror;
import com.hazizz.droid.Communication.POJO.Response.getTaskPOJOs.POJOgetTask;
import com.hazizz.droid.Communication.Requests.GetTasksFromGroup;
import com.hazizz.droid.Communication.Requests.LeaveGroup;
import com.hazizz.droid.Communication.Strings;
import com.hazizz.droid.D8;
import com.hazizz.droid.Listviews.TaskList.Group.CustomAdapter;
import com.hazizz.droid.Listviews.TaskList.TaskItem;
import com.hazizz.droid.Manager;
import com.hazizz.droid.Transactor;
import com.hazizz.droid.Communication.MiddleMan;
import com.hazizz.droid.R;

import java.util.ArrayList;
import java.util.EnumMap;
import java.util.HashMap;
import java.util.List;

import okhttp3.Headers;
import okhttp3.ResponseBody;
import retrofit2.Call;

public class GroupMainFragment extends Fragment {

    private View v;
    private CustomAdapter adapter;
    private List<TaskItem> listTask;

    private TextView textView_noContent;
    private SwipeRefreshLayout sRefreshLayout;


    private int groupId;
    private String groupName;

    FragmentManager fg;


    @Nullable
    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, @Nullable ViewGroup container, @Nullable Bundle savedInstanceState) {
        v = inflater.inflate(R.layout.fragment_maingroup, container, false);
        Log.e("hey", "mainGroup fragment created");
        ((MainActivity)getActivity()).onFragmentCreated();
        groupId = Manager.GroupManager.getGroupId();
        groupName = Manager.GroupManager.getGroupName();

        textView_noContent = v.findViewById(R.id.textView_noContent);
        sRefreshLayout = v.findViewById(R.id.swipe_refresh_layout); sRefreshLayout.bringToFront();
        sRefreshLayout.setOnRefreshListener(new SwipeRefreshLayout.OnRefreshListener() {
            @Override
            public void onRefresh() {
                getTask();
            }});

       // ((MainActivity)getActivity()).setGroupName(groupName);

        fg = getFragmentManager();

        createViewList();
        getTask();

        return v;
    }

    void createViewList(){
        listTask = new ArrayList<>();

        ListView listView = (ListView)v.findViewById(R.id.listView_mainGroupFrag);

        adapter = new CustomAdapter(getActivity(), R.layout.task_item, listTask);
        listView.setAdapter(adapter);

        listView.setOnItemClickListener(new AdapterView.OnItemClickListener() {
            @Override
            public void onItemClick(AdapterView<?> adapterView, View view, int i, long l) {
/*
                EnumMap<Strings.Path, Object> vars = new EnumMap<>(Strings.Path.class);
                vars.put(Strings.Path.TASKID, ((TaskItem)listView.getItemAtPosition(i)).getTaskId());
                vars.put(Strings.Path.GROUPID,((TaskItem)listView.getItemAtPosition(i)).getGroup().getId()); */
                groupName = ((TaskItem)listView.getItemAtPosition(i)).getGroup().getName();


                int byId;
                String byName;

                /*
                if(((TaskItem)listView.getItemAtPosition(i)).getSubject() != null){
                    byId = ((TaskItem)listView.getItemAtPosition(i)).getSubject().getId();
                    byName = Strings.Path.SUBJECTS.toString();
                }else{ */
                    byId = ((TaskItem)listView.getItemAtPosition(i)).getGroup().getId();
                    byName = Strings.Path.GROUPS.toString();
               // }
                Transactor.fragmentViewTask(getFragmentManager().beginTransaction(),
                         ((TaskItem)listView.getItemAtPosition(i)).getTaskId(),
                        false, Manager.DestManager.TOGROUP);
            }
        });
    }

    private void getTask(){
        adapter.clear();
        Log.e("hey", "atleast here 2");
        CustomResponseHandler responseHandler = new CustomResponseHandler() {
            @Override
            public void onPOJOResponse(Object response) {
                ArrayList<POJOgetTask> sorted = D8.sortTasksByDate((ArrayList<POJOgetTask>) response);
                if(sorted.size() == 0){
                    textView_noContent.setVisibility(v.VISIBLE);
                }else {

                    for (POJOgetTask t : sorted) {
                        listTask.add(new TaskItem(R.drawable.ic_launcher_background, t.getTitle(),
                                t.getDescription(), t.getDueDate(), t.getGroup(), t.getCreator(), t.getSubject(), t.getId()));
                        adapter.notifyDataSetChanged();
                        Log.e("hey", t.getId() + " " + t.getGroup().getId());
                    }
                    Log.e("hey", "got response");
                }
                sRefreshLayout.setRefreshing(false);
            }
            @Override
            public void onFailure(Call<ResponseBody> call, Throwable t) {
                Log.e("hey", "4");
                Log.e("hey", "got here onFailure");
                textView_noContent.setVisibility(v.VISIBLE);
                sRefreshLayout.setRefreshing(false);
            }
            @Override
            public void onErrorResponse(POJOerror error) {
                Log.e("hey", "onErrorResponse");
                sRefreshLayout.setRefreshing(false);
            }
            @Override
            public void onEmptyResponse() { }
            @Override
            public void onSuccessfulResponse() { }
            @Override
            public void onNoConnection() {
                textView_noContent.setText(R.string.info_noInternetAccess);
                textView_noContent.setVisibility(View.VISIBLE);
                sRefreshLayout.setRefreshing(false);
            }
        };
      //  MiddleMan.request.getTasksFromGroup(this.getActivity(), null, responseHandler, vars);
        MiddleMan.newRequest(new GetTasksFromGroup(getActivity(), responseHandler, groupId));

    }

    public void toTaskEditor(FragmentManager fm){
        Log.e("hey", "GROUPID: " + groupId);
        Transactor.fragmentCreateTask(fm.beginTransaction(), groupId, groupName, Manager.DestManager.TOGROUP);

    }

    public void leaveGroup(){
        EnumMap<Strings.Path, Object> vars = new EnumMap<>(Strings.Path.class);
        vars.put(Strings.Path.GROUPID, Integer.toString(groupId));
        MiddleMan.newRequest(new LeaveGroup( getActivity(), new CustomResponseHandler() {
            @Override
            public void onSuccessfulResponse() {
                Transactor.fragmentGroups(getFragmentManager().beginTransaction());
            }
        }, groupId));
    }
}


