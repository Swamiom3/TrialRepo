/************************************************************************************************************************************
    Author       :   Mikolaj Juras    
    @Description :   set Activity Dates on Opportunity
    Issue No     :   ST-8334
    History      :
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION     DATE                AUTHOR              ISSUE NO        DETAIL
    1         7 Jun 2021       Mikolaj Juras           ST-8334         Initial Developement               
**************************************************************************************************************************************/
public with sharing class TaskSetRelatedActivityDatesOnOppTrH extends SObjectTriggerHandler {

    @TestVisible
    private List<Task> newTasks;
    @TestVisible
    private Map<Id, Task> oldTasksMap;
    @TestVisible
    private Set<Id> opportunityIds = new Set<Id>();
    @TestVisible
    private OpportunityRelatedActivitiesManager oppRelatedActivitiesManger;
    
    public TaskSetRelatedActivityDatesOnOppTrH() {
        this((List<Task>) Trigger.new, (Map<Id, Task>) Trigger.oldMap);
    }
    
    @TestVisible
    private TaskSetRelatedActivityDatesOnOppTrH(List<Task> newTasks, Map<Id, Task> oldTasksMap) {
        this.newTasks = newTasks;
        this.oldTasksMap = oldTasksMap;
        this.opportunityIds = getParentOpportunitiesIds();
        this.oppRelatedActivitiesManger = new OpportunityRelatedActivitiesManager(opportunityIds);       
    }
    
    public override void afterInsert() {
        if (opportunityIds.isEmpty()) {
            return;
        }
        oppRelatedActivitiesManger.checkActivityOnOpportunities();
    }

    public override void afterUpdate() {
        if (opportunityIds.isEmpty()) {
            return;
        }
        oppRelatedActivitiesManger.checkActivityOnOpportunities();
    }

    private Set<Id> getParentOpportunitiesIds() {
        Set<Id> opportunityIds = new Set<Id>();
        for(Task t : newTasks){ 
            if(t.WhatId?.getSObjectType() == Opportunity.sObjectType){
                opportunityIds.add(t.WhatId);
            }
        }
        return opportunityIds;
    }
}