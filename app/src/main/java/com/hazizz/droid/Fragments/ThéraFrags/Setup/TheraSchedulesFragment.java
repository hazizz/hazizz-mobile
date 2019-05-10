package com.hazizz.droid.fragments.ThéraFrags.Setup;

import android.os.Bundle;
import android.support.annotation.NonNull;
import android.support.annotation.Nullable;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.AdapterView;
import android.widget.ListView;
import android.widget.Spinner;
import android.widget.TextView;

import com.hazizz.droid.cache.HCache;
import com.hazizz.droid.communication.MiddleMan;


import com.hazizz.droid.communication.requests.RequestType.Thera.ThReturnSchedules.PojoClass;
import com.hazizz.droid.communication.requests.RequestType.Thera.ThReturnSchedules.ThReturnSchedules;
import com.hazizz.droid.communication.responsePojos.CustomResponseHandler;
import com.hazizz.droid.communication.responsePojos.PojoError;
import com.hazizz.droid.other.D8;
import com.hazizz.droid.fragments.ParentFragment.ParentFragment;
import com.hazizz.droid.listeners.OnBackPressedListener;
import com.hazizz.droid.listviews.TheraReturnSchedules.ClassItem;
import com.hazizz.droid.listviews.TheraReturnSchedules.CustomAdapter;
import com.hazizz.droid.R;
import com.hazizz.droid.other.SharedPrefs;
import com.hazizz.droid.navigation.Transactor;

import java.util.ArrayList;
import java.util.List;

public class TheraSchedulesFragment extends ParentFragment {

    private CustomAdapter adapter;
    private List<ClassItem> listClassesAll = new ArrayList<>();

    private List<ClassItem> listClassesCurrentDay;

    private Spinner spinner_day_chooser;
    private TextView textView_spinner_display;

    private int currentDay;

    private int weekNumber;
    private int year;

    private static final int weekEndStart = 5;

    @Nullable @Override
    public View onCreateView(@NonNull LayoutInflater inflater, @Nullable ViewGroup container, @Nullable Bundle savedInstanceState) {
        v = inflater.inflate(R.layout.fragment_th_timetable, container, false);
        Log.e("hey", "TheraSchedulesFragment fragment created");

        fragmentSetup(R.string.thera_schedules);
        setOnBackPressedListener(new OnBackPressedListener() {
            @Override
            public void onBackPressed() {
                Transactor.fragmentThMain(getFragmentManager().beginTransaction());
            }
        });

        currentDay = D8.getDayOfWeek(D8.getNow())-1;
        if(currentDay >= weekEndStart){
            currentDay = 0;
            weekNumber++;
        }
        spinner_day_chooser = v.findViewById(R.id.spinner_day_chooser);
        spinner_day_chooser.setSelection(currentDay);
        spinner_day_chooser.setOnItemSelectedListener(new AdapterView.OnItemSelectedListener() {
            @Override
            public void onItemSelected(AdapterView<?> parent, View view, int position, long id) {
                currentDay = position;
                getCurrentDaySchedules(currentDay);
                textView_spinner_display.setText(spinner_day_chooser.getSelectedItem().toString());
            }

            @Override
            public void onNothingSelected(AdapterView<?> parent) {

            }
        });

        textView_spinner_display = v.findViewById(R.id.textView_spinner_display);

        weekNumber = D8.getWeek(D8.getNow());
        year = D8.getYear(D8.getNow());

        createViewList();
        getSchedules();

        proccessData(HCache.getInstance().getThera().getSchedule(getContext()));

        return v;
    }
    void createViewList(){
        listClassesCurrentDay = new ArrayList<>();
        adapter = new CustomAdapter(getActivity(), R.layout.th_class_item, listClassesCurrentDay);
        ListView listView = (ListView)v.findViewById(R.id.listView_classes);
        listView.setAdapter(adapter);

        listView.setOnItemClickListener(new AdapterView.OnItemClickListener() {
            @Override
            public void onItemClick(AdapterView<?> adapterView, View view, int i, long l) {
                  Transactor.fragmentThDialogClass(getFragmentManager().beginTransaction(), adapter.getItem(i));
            }
        });
    }

    private void proccessData(List<PojoClass> classList){
        if(classList != null) {
            if (classList.isEmpty()) {
            } else {
                String currentD = "";
                for (PojoClass t : classList) {
                    if (t.getDate().equals(currentD)) {
                        //Ehhez a naphoz tartozik
                    } else {
                        //Új nap
                    }
                    listClassesAll.add(new ClassItem(t.getDate(), t.getStartOfClass(), t.getEndOfClass(), t.getPeriodNumber(), t.isCancelled(), t.isStandIn(), t.getSubject(), t.getClassName(), t.getTeacher(), t.getRoom(), t.getTopic()));
                }
                getCurrentDaySchedules(currentDay);
            }
        }
    }

    private void getSchedules(){
        long sessionId = SharedPrefs.ThSessionManager.getSessionId(getContext());
        CustomResponseHandler rh = new CustomResponseHandler() {

            @Override
            public void getRawResponseBody(String rawResponseBody) {
                HCache.getInstance().getThera().setSchedule(getContext(), rawResponseBody);
            }

            @Override
            public void onPOJOResponse(Object response) {
                ArrayList<PojoClass> classList = (ArrayList<PojoClass>) response;
                proccessData(classList);

            }
            @Override
            public void onErrorResponse(PojoError error) {
                //                            session not found,                session not active
                if(error.getErrorCode() == 132 || error.getErrorCode() == 136) {
                    Transactor.fragmentThLoginAuthSession(getFragmentManager().beginTransaction(), sessionId,
                            SharedPrefs.ThLoginData.getSchool(getContext(), sessionId),
                            SharedPrefs.ThLoginData.getUsername(getContext(), sessionId));;
                }
            }
        };
        MiddleMan.newRequest(new ThReturnSchedules(getActivity(),rh, sessionId, weekNumber, year));
    }

    private void getCurrentDaySchedules(int dayOfWeek){
        adapter.clear();
        int day = 0;
        String currentDate = "";
        for(ClassItem i : listClassesAll){
            if(!i.getDate().equals(currentDate)){
                day++;
                currentDate = i.getDate();
                if(dayOfWeek < day){
                    break;
                }
            }//else {continue;}
            if(dayOfWeek == day){
                listClassesCurrentDay.add(i);
                adapter.notifyDataSetChanged();
            }
        }
    }

}
