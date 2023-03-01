/************************************************************************************************************************************
        Author              : Tomasz Sadowski
        Description         : https://jira.weworkers.io/browse/ST-7657
        Last Modified Date  : 10 Feb 2021
        Last Modified By    : Tomasz Sadowski
        Issue No            : ST-7657
    ********************************************************************************************************************************/
public without sharing class TaskJourneyTrH extends SObjectTriggerHandler {
    private List<Task> newRecords;
    @TestVisible
    private JourneySelector journeySelector = new JourneySelector();

    public TaskJourneyTrH() {
        this((List<Task>) Trigger.new); 
    }

    @TestVisible
    private TaskJourneyTrH(List<Task> newRecords) {
        this.newRecords = newRecords; 
    }
    
    public override void afterInsert() {
        this.updateJourneyStatus(); 
    }
    
    private void updateJourneyStatus() {
        Set<Id> combinedIds = new Set<Id>();
        for (Task task : newRecords) {
            combinedIds.add(task.WhatId);
            combinedIds.add(task.WhoId);
        }


        combinedIds.remove(null);
        List<Journey__c> journeysToUpdate = new List<Journey__c>();
        for (Journey__c journey : journeySelector.getAcceptedJourneysMatchingParentIds(GlobalConstants.JOURNEY_STATUS_ACCEPTED, new List<Id>(combinedIds))) {
            journey.Status__c = GlobalConstants.JOURNEY_STATUS_WORKING;

            journeysToUpdate.add(journey);
        }

        if (!journeysToUpdate.isEmpty()) {
            update journeysToUpdate;
        }
    }
}