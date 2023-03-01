/************************************************************************************************************************************
    Author      :   Maciej Miłosz
    Description :   Change related journeys for leads.
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION     DATE                AUTHOR                  DETAIL
    1           29 Jan 2021         Maciej Miłosz           Trigger refactoring
**************************************************************************************************************************************/

public with sharing class LeadChangeRelatedJourneyStatusTrH extends SObjectTriggerHandler {
    @TestVisible
    private List<Lead> newLeads;
    @TestVisible
    private Map<Id, Lead> oldLeadsMap;
    @TestVisible
    private static Map<String, String> leadStatusToJourneyStatusMapping;

    public LeadChangeRelatedJourneyStatusTrH(){
        this(
            (List<Lead>) Trigger.new,
            (Map<Id, Lead>) Trigger.oldMap
        );
    }

    @TestVisible
    private LeadChangeRelatedJourneyStatusTrH(List<Lead> newLeads, Map<Id, Lead> oldLeadsMap){
        this.newLeads = newLeads;
        this.oldLeadsMap = oldLeadsMap;
    }

    public override void afterUpdate(){
        //decouple
        if(!JourneyChangeRelatedLeadStatusTrH.isJourneyUpdated){
            changeLeadRelatedJourneyStatus();    
        }
    }
    @TestVisible
    private void changeLeadRelatedJourneyStatus(){
        Map<String, String> statusMapping = getLeadStatusToJourneyStatusMapping();
        Set<Id> validLeadIds = new Set<Id>();       
        for(Lead leadRecord : newLeads){
            Lead oldLead = oldLeadsMap?.get(leadRecord.Id);
            if(TriggerUtility.isFieldValueChanged(leadRecord, oldLead, 'Status') && statusMapping.containsKey(leadRecord.Status)){
                validLeadIds.add(leadRecord.Id);
            }
        }
        if(validLeadIds.isEmpty()){
            return;
        }
        Sales_Console_Setting__mdt journeyCloseStagesSetting = SalesConsoleSettings.get('JourneyCloseStages');
        Set<String> journeyCloseStages = new Set<String>();
        if(journeyCloseStagesSetting != null) {
            journeyCloseStages = (Set<String>)JSON.deserialize(journeyCloseStagesSetting.Data__c, Set<String>.class);
        }
        List<Journey__c> journeysToUpdate = new List<Journey__c>();
        for(Lead leadRecord : [SELECT Id, Status, Unqualified_Reason__c, 
                                    (   SELECT Id, Status__c 
                                        FROM Journeys__r 
                                        WHERE Status__c NOT IN :journeyCloseStages 
                                        ORDER BY LastModifiedDate DESC 
                                        LIMIT 1) 
                               FROM Lead WHERE Id IN : validLeadIds AND IsConverted = FALSE]){
            if(leadRecord.Journeys__r.isEmpty()){
                continue;
            }
            Journey__c  journeyRecord = leadRecord.Journeys__r[0];
            if(journeyRecord.Status__c == statusMapping.get(leadRecord.Status)){
                continue;
            }
            journeyRecord.Status__c = statusMapping.get(leadRecord.Status);
            if(leadRecord.Status == GlobalConstants.DEFERRED){
                journeyRecord.Deferred_Reason__c = leadRecord.Unqualified_Reason__c;
            }
            journeysToUpdate.add(journeyRecord);  
        }
        
        if(!journeysToUpdate.isEmpty()){
            dml.add(journeysToUpdate, DmlConsolidator.Operation.FOR_UPDATE);
        }
    }
    
    @TestVisible
    private static Map<String, String> getLeadStatusToJourneyStatusMapping(){
        if(LeadChangeRelatedJourneyStatusTrH.leadStatusToJourneyStatusMapping != null){
            return LeadChangeRelatedJourneyStatusTrH.leadStatusToJourneyStatusMapping;
        }
        Map<String, String> leadStatusToJourneyStatusMap = new Map<String, String>();
        for(LeadJourneyTrigger__mdt statusMapping : [SELECT Journey_Status__c, Lead_Status__c FROM LeadJourneyTrigger__mdt WHERE Source_Object__c = 'Lead' AND Destination_Object__c = 'Journey__c']){
            leadStatusToJourneyStatusMap.put(statusMapping.Lead_Status__c, statusMapping.Journey_Status__c);
        }
        LeadChangeRelatedJourneyStatusTrH.leadStatusToJourneyStatusMapping = leadStatusToJourneyStatusMap;
        return LeadChangeRelatedJourneyStatusTrH.leadStatusToJourneyStatusMapping;
    }
}