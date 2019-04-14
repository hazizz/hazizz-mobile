package com.hazizz.droid.Fragments.Dialog;

import android.os.Bundle;
import android.support.v4.app.DialogFragment;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Button;
import android.widget.TextView;

import com.hazizz.droid.D8;
import com.hazizz.droid.R;
import com.hazizz.droid.Transactor;

public class DateViewerDialogFragment extends DialogFragment {

    TextView textView_mainFormat;
    TextView textView_daysLeft;
    TextView textView_dayOfTheWeek;

    Button button_close;


    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
    }

    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container, Bundle savedInstanceState) {
        View v = inflater.inflate(R.layout.dialog_fragment_date_viewer, container, false);

        D8.Date dateText = D8.textToDate(getArguments().getString(Transactor.KEY_DATE));

        // Do all the stuff to initialize your custom view
        textView_mainFormat = v.findViewById(R.id.textView_link);
        textView_daysLeft = v.findViewById(R.id.textView_daysLeft);
        textView_dayOfTheWeek = v.findViewById(R.id.textView_dayOfTheWeek);

        textView_mainFormat.setText(dateText.getMainFormat());
        textView_daysLeft.setText(dateText.daysLeft() + " " + getResources().getString(R.string.daysLeft));
        textView_dayOfTheWeek.setText(dateText.dayOfWeek(getContext()));

        button_close = v.findViewById(R.id.button_close);
        button_close.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                dismiss();
            }
        });


        return v;
    }
}