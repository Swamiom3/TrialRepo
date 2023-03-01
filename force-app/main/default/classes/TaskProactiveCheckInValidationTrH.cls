/************************************************************************************************************************************
    Author      :   Mikołaj Juras
    Description :   Create Validation to block any update except WhoId for Proactive Check In Task Type
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION     DATE                AUTHOR                  DETAIL
    1           23 Feb 2021         Mikołaj Juras           ST-7722 security validation for Practive CheckIn Task
**************************************************************************************************************************************/
public with sharing class TaskProactiveCheckInValidationTrH extends SObjectTriggerHandler {
    
    @TestVisible
    private List<Task> newTasks;
    @TestVisible
    private Map<Id, Task> oldTasksMap;
    
    @TestVisible
    private List<Profile> adminProfiles;

    @TestVisible
    private final static Map<String, Schema.SObjectField> TASK_FIELDS_MAP = getTaskFieldsMap();
    private final static Set<String> EDITABLE_FIELDS_PROCTIVE_CHECKIN_TYPE = new Set<String> {
        'WhoId', 'WhatId', 'Data_Quality_Description__c', 'Data_Quality_Score__c'
    };
   
    public TaskProactiveCheckInValidationTrH() {
        this(
            (List<Task>) Trigger.new,
            (Map<Id, Task>) Trigger.oldMap
        );
    }

    // TODO: change to private after refactor
    @TestVisible
    public TaskProactiveCheckInValidationTrH(List<Task> newTasks, Map<Id, Task> oldTasksMap){
        this.newTasks = newTasks;
        this.oldTasksMap = oldTasksMap;
    }

    // TODO: remove flag after refactor
    public override void beforeUpdate() {
        for(Task currentTask : newTasks) {
            if(canUserEditTask()
                || !isProactiveCheckIn(currentTask, oldTasksMap.get(currentTask.Id)) 
                || (isProactiveCheckIn(currentTask, oldTasksMap.get(currentTask.Id)) 
                    && !isMoreFieldsEdited(currentTask, oldTasksMap.get(currentTask.Id)))) {
                continue;
            }
            currentTask.addError(System.Label.ProactiveCheckInValidationMessege);
        }
    }

    @TestVisible
    private static Map<String, Schema.SObjectField> getTaskFieldsMap() {
        Schema.DescribeSObjectResult d = Task.sObjectType.getDescribe();
        return d.fields.getMap();
    }

    @TestVisible
    private Boolean isProactiveCheckIn (Task newTask, Task oldTask) {
        return newTask.Type == GlobalConstants.TASK_TYPE_PROACTIVE_CHECKIN || oldTask.Type == GlobalConstants.TASK_TYPE_PROACTIVE_CHECKIN;

    }

    @TestVisible
    private Boolean isMoreFieldsEdited(Task newTask, Task oldTask) {       
        Set<String> taskFieldAPINames = new Set<String>();
        for (Schema.SObjectField taskField : TASK_FIELDS_MAP.values()) {
            taskFieldAPINames.add(taskField.getDescribe().getName());
        }
        taskFieldAPINames.removeAll(EDITABLE_FIELDS_PROCTIVE_CHECKIN_TYPE);

        return TriggerUtility.isFieldsValueChanged(newTask, oldTask, taskFieldAPINames);
    }

    @TestVisible
    private static Boolean canUserEditTask() {
        return UserUtility.isMuleSoftUser || UserUtility.isSystemAdministrator;
    }
}