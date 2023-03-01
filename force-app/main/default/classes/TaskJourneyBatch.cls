/************************************************************************************************************************************
        Author              : Tomasz Sadowski
        Description         : https://jira.weworkers.io/browse/ST-7657
        Last Modified Date  : 16 Feb 2021
        Last Modified By    : Tomasz Sadowski
        Issue No            : ST-7657
    ********************************************************************************************************************************/
public with sharing class TaskJourneyBatch implements Database.Batchable<sObject> {
    public Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator([SELECT Id, Primary_Contact__c, Primary_Lead__c, Status__c FROM Journey__c WHERE CreatedDate != LAST_N_DAYS:30 AND Status__c NOT IN (:GlobalConstants.JOURNEY_STATUS_CONVERTED, :GlobalConstants.JOURNEY_STATUS_DEFERRED)]);
    }
    
    public void execute(Database.BatchableContext BC, List<Journey__c> scope) {
        Map<Id, Journey__c> recordIdToJourney = new Map<Id, Journey__c>((List<Journey__c>) scope);
        for (Journey__c journey : scope) {
            recordIdToJourney.put(journey.Primary_Contact__c, journey);
            recordIdToJourney.put(journey.Primary_Lead__c, journey);
        }
        recordIdToJourney.remove(null);
        for (Task task : [SELECT Id, WhoId, WhatId FROM Task WHERE CreatedDate = LAST_N_DAYS:30 AND (WhatId IN :recordIdToJourney.keySet() OR WhoId IN :recordIdToJourney.keySet())]) {
            recordIdToJourney.remove(task.WhatId);
            recordIdToJourney.remove(task.WhoId);
        }
        Set<Journey__c> uniqueJourneys = new Set<Journey__c>(recordIdToJourney.values());
        for (Journey__c journey : uniqueJourneys) {
            journey.Status__c = GlobalConstants.JOURNEY_STATUS_DEFERRED;
            journey.Deferred_Reason__c = GlobalConstants.JOURNEY_STATUS_DEFERRED_REASON_AUTO;
        }
        if (!uniqueJourneys.isEmpty()) {
            update new List<Journey__c>(uniqueJourneys);
        }
    }
    
    public void finish(Database.BatchableContext BC) {}
}