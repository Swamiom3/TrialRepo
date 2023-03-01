/************************************************************************************************************************************
    Author      :   Shubham Nandwana
    Description :   This class contains the business logic to populate contact related field on opportunity upon insertion/updation.
    History	    :
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION     DATE                AUTHOR                  DETAIL					ISSUE
    1           20 July 2021        Shubham Nandwana        Initial Development		TWSPG-2285
**************************************************************************************************************************************/
public with sharing class OpportunityUpdateReferralFieldsTrH extends SObjectTriggerHandler {

    @TestVisible
    private Map<Id,Opportunity> oldOpportunitiesMap;
    @TestVisible
    private List<Opportunity> newOpportunities;

    public OpportunityUpdateReferralFieldsTrH() {
        this((Map<Id,Opportunity>) Trigger.OldMap, (List<Opportunity>) Trigger.new);
    }

    @TestVisible
    private OpportunityUpdateReferralFieldsTrH(Map<Id,Opportunity> oldOpportunitiesMap, List<Opportunity> newOpportunities) {
        this.oldOpportunitiesMap = oldOpportunitiesMap;
        this.newOpportunities = newOpportunities;
    }

    public override void beforeInsert() {
        updateContactFieldsOnOpportunities(true);
    }
    
    public override void beforeUpdate() {
        updateContactFieldsOnOpportunities(false);
    }

    @TestVisible
    private void updateContactFieldsOnOpportunities(boolean isInsert) {
        Map<Opportunity, Id> filteredOppWithConIdMap = new Map<Opportunity, Id>();
        filteredOppWithConIdMap = filterOpportunities(isInsert);
        if (!filteredOppWithConIdMap.isEmpty()) {
            updateOpportunitiesContactField(filteredOppWithConIdMap);
        }
    }

    @TestVisible
    private Map<Opportunity, Id> filterOpportunities(boolean isInsert) {
        Map<Opportunity, Id> filteredOpportunitiesToContactIds = new Map<Opportunity, Id>();
        for (Opportunity objOpportunity : newOpportunities) {
            if(String.isBlank(objOpportunity.Referrer__c))
                continue;
            if(isInsert){
                filteredOpportunitiesToContactIds.put(objOpportunity, objOpportunity.Referrer__c);
            }else{
                if (objOpportunity.referrer__c != oldOpportunitiesMap.get(objOpportunity.Id).Referrer__c) {
                    filteredOpportunitiesToContactIds.put(objOpportunity, objOpportunity.Referrer__c);
                }
            }
        }
        return filteredOpportunitiesToContactIds;
    }


    /************************************************************************************************************************************
        Author          : Shubham Nandwana
        Description     : This method is used to update Referrer fields on opportunity
        Created Date    : 20 July 2021 
        Issue No        : TWSPG-2285
    **************************************************************************************************************************************/
    private void updateOpportunitiesContactField(Map<Opportunity, Id> filteredOppWithConMap) {
        Map<Id, Contact> contactsMap = new Map<Id, Contact>([SELECT Id, AccountId, Type__c 
                                                             FROM Contact
                                                             WHERE Id IN :filteredOppWithConMap.values()]);
        for (Opportunity objOpportunity : filteredOppWithConMap.keySet()) {
            if (contactsMap.containsKey(objOpportunity.Referrer__c)) {
                objOpportunity.Referrer_Account__c = contactsMap.get(objOpportunity.Referrer__c).AccountId;
                objOpportunity.Referrer_Contact_Type__c = contactsMap.get(objOpportunity.Referrer__c).type__c;
            }
        }
    }
}