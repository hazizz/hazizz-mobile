package com.indeed.hazizz.Listviews.TaskList.Group;

import android.app.Activity;
import android.content.Context;
import android.support.annotation.NonNull;
import android.support.annotation.Nullable;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ArrayAdapter;
import android.widget.TextView;

import com.indeed.hazizz.Listviews.TaskList.TaskItem;
import com.indeed.hazizz.R;

import java.util.List;

public class CustomAdapter extends ArrayAdapter<TaskItem> {

    Context context;
    int picID;
    List<TaskItem> data = null;


    public CustomAdapter(@NonNull Context context, int resource, @NonNull List<TaskItem> objects) {
        super(context, resource, objects);

        this.picID = resource;
        this.context = context;
        this.data = objects;
    }

    static class DataHolder{
       // ImageView taskPic;
        TextView taskTitle;
        TextView taskDescription;
        TextView taskDueDate;
        TextView taskCreator;
        TextView taskSubject;
    }
    @NonNull
    @Override
    public View getView(int position, @Nullable View convertView, @NonNull ViewGroup parent) {
        DataHolder holder = null;

        if(convertView == null) {
            LayoutInflater inflater = ((Activity) context).getLayoutInflater();

            convertView = inflater.inflate(picID, parent, false);

            holder = new DataHolder();
           // holder.taskPic = (ImageView) convertView.findViewById(R.id.task_pic);
            holder.taskTitle = (TextView) convertView.findViewById(R.id.task_title);
            holder.taskDescription = (TextView) convertView.findViewById(R.id.task_description);
            holder.taskDueDate = (TextView) convertView.findViewById(R.id.textView_dueDate);
            holder.taskCreator = (TextView) convertView.findViewById(R.id.textView_creator);
            holder.taskSubject = (TextView) convertView.findViewById(R.id.textView_title);

            convertView.setTag(holder);
        }else{
            holder = (DataHolder)convertView.getTag();
        }

        TaskItem taskItem = data.get(position);
        holder.taskTitle.setText(taskItem.getTaskTitle());
        holder.taskDescription.setText(taskItem.getTaskDescription());
        holder.taskDueDate.setText(taskItem.getTaskDueDate());
     //   holder.taskCreator.setText(taskItem.getCreator().getUsername());
        holder.taskCreator.setText(taskItem.getCreator().getUsername());
        holder.taskSubject.setText(taskItem.getSubject().getName());
      //  holder.taskPic.setImageResource(taskItem.taskPic);

        return convertView;
        // return super.getView(position, convertView, parent);
    }
}