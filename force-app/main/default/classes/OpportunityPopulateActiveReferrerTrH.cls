/************************************************************************************************************************************
Author      :   Salesforce
Description :   This class set and populate Opportunity Referrer field value from Referral record
Issue No    :   TWSPG-9682
----------------------------------------------------------------------------------------------------------------------------------
VERSION         DATE             AUTHOR              DETAIL
  1        14 April 2022       Salesforce     Initial Development
**************************************************************************************************************************************/
public with sharing class OpportunityPopulateActiveReferrerTrH extends SObjectTriggerHandler {

    @TestVisible
    private List<Opportunity> newOpportunities;
    
    @TestVisible 
    public OpportunityPopulateActiveReferrerTrH() {
        this((List<Opportunity>) Trigger.new);
    }
    
    @TestVisible
    private OpportunityPopulateActiveReferrerTrH(List<Opportunity> newOpportunities) {
        this.newOpportunities = newOpportunities; 
    }
    
    public override void beforeInsert() {
        populateOpportunityActiveReferrer();
    }
    
    public void populateOpportunityActiveReferrer() {
        Set<String> primaryContactEmails = new Set<String>();
        List<Opportunity> opportunitiesToUpdate = new List<Opportunity>();
        for(Opportunity opp : newOpportunities){
            if(opp.Primary_Member__c != null && opp.Referrer__c == null && String.isNotBlank(opp.Primary_Member_Email_New__c)){
                primaryContactEmails.add(opp.Primary_Member_Email_New__c);
                opportunitiesToUpdate.add(opp);
            }
        }
        if(primaryContactEmails.isEmpty() || opportunitiesToUpdate.isEmpty()){
            return;
        }
        Map<String, Id> mapActiveReferences = ReferenceHandler.getActiveReference(primaryContactEmails);
        if(mapActiveReferences.isEmpty()){
            return;
        }
        for(Opportunity opp : opportunitiesToUpdate){
            if(mapActiveReferences.containsKey(opp.Primary_Member_Email_New__c.toLowerCase())){
                opp.Referrer__c = mapActiveReferences.get(opp.Primary_Member_Email_New__c.toLowerCase());
            }
        }
    }
}