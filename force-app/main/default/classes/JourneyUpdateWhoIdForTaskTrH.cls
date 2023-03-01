/*********************************************************************************************************
    Author        :  Shobhit Gahlot
    Description   :  If journey's primary member gets changed from Lead to Contact, we need to update all 
                     the task's WhoId related to the journey.
    Issue No.     :  ST-8957
    History       :
-----------------------------------------------------------------------------------------------------------
    VERSION        DATE            AUTHOR             DETAIL
    1          09-Sept-2021      Shobhit Gahlot     Trigger Refactor
**********************************************************************************************************/
public class JourneyUpdateWhoIdForTaskTrH extends SObjectTriggerHandler {
    @TestVisible
    private List<Journey__c> newJourneys;
    @TestVisible
    private Map<Id, Journey__c> oldJourneys;
    @TestVisible
    List<Task> tasksToUpdate = new List<Task>();
    @TestVisible
    private TaskSelector taskSelector = new TaskSelector();
    
    public JourneyUpdateWhoIdForTaskTrH() {
        this((List<Journey__c>) Trigger.new, (Map<Id, Journey__c>) Trigger.oldMap);
    }
    
    @TestVisible
    private JourneyUpdateWhoIdForTaskTrH(List<Journey__c> newJourneys, Map<Id, Journey__c> oldJourneys) {
        this.newJourneys = newJourneys;
        this.oldJourneys = oldJourneys;
    }
    
    public override void afterInsert(){
        updateWhoIdForTask();
    }
    
    public override void afterUpdate(){
        updateWhoIdForTask();
    }
    
    @TestVisible
    private void updateWhoIdForTask() {
        Map<Id, Journey__c> journeyWithPrimaryMemberChange = new Map<Id, Journey__c>();
        for(Journey__c journey :  newJourneys){
            if(journey.Primary_Contact__c != null && (this.context == TriggerContext.AFTER_INSERT || (this.context == TriggerContext.AFTER_UPDATE && oldJourneys.get(journey.Id).Primary_Contact__c == null))){
                journeyWithPrimaryMemberChange.put(journey.Id, journey);
            }
        }
        
        if(journeyWithPrimaryMemberChange != null && !journeyWithPrimaryMemberChange.isEmpty()){
            for(Task task: taskSelector.getTasksWithRelatedObjectsFieldsByWhatIds(new List<Id>(journeyWithPrimaryMemberChange.keySet()))){
                task.WhoId = journeyWithPrimaryMemberChange.get(task.WhatId).Primary_Contact__c;
                tasksToUpdate.add(task);
            }
            if(!tasksToUpdate.isEmpty()){
                dml.add(tasksToUpdate, DmlConsolidator.Operation.FOR_UPDATE);
            }
        }
    }
}