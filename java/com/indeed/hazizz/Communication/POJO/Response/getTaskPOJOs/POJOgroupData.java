package com.indeed.hazizz.Communication.POJO.Response.getTaskPOJOs;

import lombok.Data;

@Data
public class POJOgroupData {

    private long id;
    private String name;
    private String groupType;
    private int userCount;

    public POJOgroupData(long id, String name, String groupType, int userCount) {
        this.id = id;
        this.name = name;
        this.groupType = groupType;
        this.userCount = userCount;
    }

}