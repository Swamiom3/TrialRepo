/*********************************************************************************************************
    Author        :  Shobhit Gahlot 
    Description   :  New Journey inserted or old journey status changes then fields 'Status' 
                     and 'Contact Lead Status' gets updated on Lead and Contact respectively.  
    Issue No.     :  ST-8957 and ST-9446
    History       :
-----------------------------------------------------------------------------------------------------------
    VERSION        DATE            AUTHOR             DETAIL
    1          09-Sept-2021      Shobhit Gahlot     Trigger Refactor
**********************************************************************************************************/
public with sharing class JourneyChangeRelatedLeadStatusTrH extends SObjectTriggerHandler {
    @TestVisible
    private List<Journey__c> newJourneys;
    @TestVisible
    private Map<Id, Journey__c> oldJourneys;
    @TestVisible
    private Map<Id, Lead> leadToUpdate = new Map<Id, Lead>();
    @TestVisible
    private Map<Id, Contact> contactToUpdate = new Map<Id, Contact>();
    @TestVisible
    private List<sObject> sobjectsToUpdate = new List<sObject>();
    public static Boolean isJourneyUpdated = false;
    private static Boolean hasCompletedValidRun = false;
    private static final String CONTACT_STATUS_CONVERTED = 'Converted';

    public JourneyChangeRelatedLeadStatusTrH() {
        this((List<Journey__c>) Trigger.new, (Map<Id, Journey__c>) Trigger.oldMap);
    }

    @TestVisible
    private JourneyChangeRelatedLeadStatusTrH(List<Journey__c> newJourneys, Map<Id, Journey__c> oldJourneys) {
        this.newJourneys = newJourneys;
        this.oldJourneys = oldJourneys;
    }

    public override void afterInsert() {
        changeJourneyRelatedLeadStatus();
    }

    public override void afterUpdate() {
        changeJourneyRelatedLeadStatus();
    }

    @TestVisible
    private void changeJourneyRelatedLeadStatus() {
        Map<Id, Id> journeyIdToLeadIdMap = new Map<Id, Id>();
        Map<Id, Id> journeyIdToContactIdMap = new Map<Id, Id>();
        Set<String> journeyStatusesForContact = new Set<String>{GlobalConstants.JOURNEY_STATUS_KNOWN, GlobalConstants.JOURNEY_STATUS_MQL};
        Set<String> journeyStatusesForLead = new Set<String>{GlobalConstants.JOURNEY_STATUS_KNOWN, GlobalConstants.JOURNEY_STATUS_ACCEPTED};

        for(Journey__c journey : newJourneys) {
            Boolean isLeadToUpdate = false;
            Boolean isContactToUpdate = false;
            Boolean isJourneyHasPrimaryLead = journey.Primary_Lead__c != null;
            if((isJourneyHasPrimaryLead || journey.Primary_Contact__c != null) && String.isNotBlank(journey.Status__c)) {
                if(this.context == TriggerContext.AFTER_INSERT) {
                    if(isJourneyHasPrimaryLead) {
                        isLeadToUpdate = journeyStatusesForLead.contains(journey.Status__c);
                    } else {
                        isContactToUpdate = journeyStatusesForContact.contains(journey.Status__c);
                    }
                } else {
                    Journey__c oldJourney = oldJourneys.get(journey.Id);
                    if (String.isNotBlank(oldJourney.Status__c) && TriggerUtility.isFieldValueChanged(journey, oldJourney, 'Status__c')) {
                        hasCompletedValidRun = true;
                        if (isJourneyHasPrimaryLead) {
                            isLeadToUpdate = true;
                        } else {
                            isContactToUpdate = true;
                        }
                    } else if (!hasCompletedValidRun) {
                        SObjectTriggerHandler.clearLoopCount('JourneyChangeRelatedLeadStatusTrH');
                    }
                }
                if(isLeadToUpdate) {
                    Lead lead = new Lead(
                            Id = journey.Primary_Lead__c,
                            Status = journey.Status__c == GlobalConstants.JOURNEY_STATUS_ACCEPTED ? GlobalConstants.LEAD_STATUS_WORKING : journey.Status__c,
                            Unqualified_Reason__c = journey.Status__c == 'Deferred' ? journey.Deferred_Reason__c : ''
                    );
                    leadToUpdate.put(lead.Id, lead);
                    journeyIdToLeadIdMap.put(journey.Id, lead.Id);
                } else if (isContactToUpdate) {
                    Contact contact = new Contact(Id = journey.Primary_Contact__c,
                                                    Contact_Lead_Status__c = journey.Status__c == GlobalConstants.JOURNEY_STATUS_ACCEPTED ? GlobalConstants.LEAD_STATUS_WORKING : journey.Status__c);
                    contactToUpdate.put(contact.Id, contact);
                    journeyIdToContactIdMap.put(journey.Id, contact.Id);
                }
            }
        }
        if(!contactToUpdate.isEmpty()) {
            setContactToUpdate(journeyIdToContactIdMap);
        }
        if(!leadToUpdate.isEmpty()) {
            setLeadToUpdate(journeyIdToLeadIdMap);
        }
        if(!sobjectsToUpdate.isEmpty()) {
            isJourneyUpdated = true;
            dml.add(sobjectsToUpdate, DmlConsolidator.Operation.FOR_UPDATE);
        }
    }

    private void setContactToUpdate(Map<Id, Id> journeyIdToContactIdMap) {
        Set<String> openOpportunityStages = getStageSetting('OpenOpportunityStages');
        Map<String, Object> mapStatus = getStatusMappings();
        Map<String, String> journeyStatusToContactStatus = getStatusMappingsByObject('Contact');
        for(Contact contact : [ SELECT Id, Contact_Lead_Status__c,
                                       (SELECT Id
                                        FROM Opportunities
                                        WHERE stageName IN :openOpportunityStages
                                        LIMIT 1),
                                       (SELECT Id, Status__c
                                        FROM Journeys__r)
                                FROM Contact
                                WHERE Id IN :journeyIdToContactIdMap.values()]) {
            Contact newContactToUpdate = contactToUpdate.get(contact.Id);
            String contactStatus;
            Integer statusPriority = 0;
            for(Journey__c journey : contact.Journeys__r) {
                if (statusPriority < (Integer) mapStatus.get(journey.Status__c)) {
                    statusPriority = (Integer) mapStatus.get(journey.Status__c);
                    contactStatus = journey.Status__c == GlobalConstants.JOURNEY_STATUS_ACCEPTED ? GlobalConstants.LEAD_STATUS_WORKING : journey.Status__c;
                }
            }

            if(((contact.Contact_Lead_Status__c != CONTACT_STATUS_CONVERTED) || (contact.Contact_Lead_Status__c == CONTACT_STATUS_CONVERTED && contact.Opportunities.isEmpty()))){
                if(journeyStatusToContactStatus.get(newContactToUpdate.Contact_Lead_Status__c) != null){
                    Map<String, Object> statusMap = (Map<String, Object>)JSON.deserializeUntyped(journeyStatusToContactStatus.get(newContactToUpdate.Contact_Lead_Status__c));
                    contactStatus = (String)statusMap.get(String.isBlank(contact.Contact_Lead_Status__c) ? '' : contact.Contact_Lead_Status__c);
                }
            }

            if(String.isNotBlank(contactStatus)) {
                newContactToUpdate.Contact_Lead_Status__c = contactStatus;
                sobjectsToUpdate.add(newContactToUpdate);
            }
        }
    }

    private void setLeadToUpdate(Map<Id, Id> journeyIdToLeadIdMap) {
        Map<String, Object> mapStatus = getStatusMappings();
        Integer statusPriority = 0;
        String leadStatus;
        for(Lead lead : [ SELECT Id, Status, Unqualified_Reason__c,
                                 (SELECT Id, Status__c
                                  FROM Journeys__r)
                          FROM Lead
                          WHERE Id IN :journeyIdToLeadIdMap.values()]) {
            Lead newLeadToUpdate = leadToUpdate.get(lead.Id);
            for (Journey__c journey : lead.Journeys__r) {
                if (statusPriority < (Integer) mapStatus.get(journey.Status__c)) {
                    statusPriority = (Integer) mapStatus.get(journey.Status__c);
                    leadStatus = journey.Status__c == GlobalConstants.JOURNEY_STATUS_ACCEPTED ? GlobalConstants.LEAD_STATUS_WORKING : journey.Status__c;
                }
            }
            if (String.isBlank(leadStatus)) {
                continue;
            }
            newLeadToUpdate.Status = leadStatus;
            if (lead.Status.equalsIgnoreCase('deferred') && !leadStatus.equalsIgnoreCase('deferred')) {
                newLeadToUpdate.Unqualified_Reason__c = '';
            } else if (lead.Status.equalsIgnoreCase('deferred') && leadStatus.equalsIgnoreCase('deferred')) {
                newLeadToUpdate.Unqualified_Reason__c = String.isNotBlank(newLeadToUpdate.Unqualified_Reason__c) ? newLeadToUpdate.Unqualified_Reason__c : lead.Unqualified_Reason__c;
            }
            sobjectsToUpdate.add(newLeadToUpdate);
        }
    }

    private Map<String, Object> getStatusMappings() {
        Map<String, Object> mappStatus = new Map<String, Object>();
        MetadataSetting__mdt statusMapping = MetadataSetting__mdt.getInstance('Journey_Status_Priority');
        mappStatus = (Map<String, Object>) JSON.deserializeUntyped(statusMapping.Data__c);
        return mappStatus;
    }
    
    private Set<String> getStageSetting(String settingName) {
        Sales_Console_Setting__mdt setting = SalesConsoleSettings.get(settingName);
        if(setting != null) {
            return (Set<String>) JSON.deserialize(setting.Data__c, Set<String>.class);
        }
        return null;
    }

    private Map<String, String> getStatusMappingsByObject(String destinationObject){
        Map<String, String> statusMapping = new Map<String, String>();
        for(LeadJourneyTrigger__mdt objStatusMapping : [SELECT Journey_Status__c, Lead_Status_Mapping__c FROM LeadJourneyTrigger__mdt WHERE Source_Object__c = 'Journey__c' AND Destination_Object__c = : destinationObject]){
            statusMapping.put(objStatusMapping.Journey_Status__c, objStatusMapping.Lead_Status_Mapping__c);
        }
        return statusMapping;
    }
}