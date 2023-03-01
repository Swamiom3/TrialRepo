/************************************************************************************************************************************
        Author              : Tomasz Sadowski
        Description         : https://jira.weworkers.io/browse/ST-7657
        Last Modified Date  : 28 Feb 2021
        Last Modified By    : Tomasz Sadowski
        Issue No            : ST-7657
    ********************************************************************************************************************************/
public with sharing class EventJourneyTrH extends SObjectTriggerHandler {
    private List<Event> newRecords;
    @TestVisible
    private JourneySelector journeySelector = new JourneySelector();

    public EventJourneyTrH() {
        this((List<Event>) Trigger.new); 
    }

    @TestVisible
    private EventJourneyTrH(List<Event> newRecords) {
        this.newRecords = newRecords; 
    }
    
    public override void afterInsert() {
        this.updateJourneyStatus(); 
    }
    
    private void updateJourneyStatus() {
        Set<Id> combinedIds = new Set<Id>();
        for (Event event : newRecords) {
            combinedIds.add(event.WhatId);
            combinedIds.add(event.WhoId);
        }
        combinedIds.remove(null);
        List<Journey__c> journeysToUpdate = new List<Journey__c>();
        for (Journey__c journey : journeySelector.getAcceptedJourneysMatchingParentIds(GlobalConstants.JOURNEY_STATUS_ACCEPTED, new List<Id>(combinedIds))){
            journey.Status__c = GlobalConstants.JOURNEY_STATUS_WORKING;
            journeysToUpdate.add(journey);
        }
        if (!journeysToUpdate.isEmpty()) {
            update journeysToUpdate;
        }
    }
}