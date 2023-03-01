/************************************************************************************************************************************
    Author      :   Salesforce 
    Description :   Trigger handler class for updating Order checkbox to true on primary quote under the Opportunity.
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION     DATE                AUTHOR                  DETAIL
    1           Jul 23, 2021        Salesforce             Initial version
**************************************************************************************************************************************/
public with sharing class OpportunityPrimaryQuoteUpdatesTrH extends SObjectTriggerHandler {
    public static final String CLOSED_WON = 'Closed Won';
    @TestVisible
    private List<Opportunity> newOpportunities;
    @TestVisible
    private Map<Id, Opportunity> oldOpportunitiesMap;

    public OpportunityPrimaryQuoteUpdatesTrH() {
        this((List<Opportunity>) Trigger.new, (Map<Id, Opportunity>) Trigger.oldMap);
    }

    @TestVisible
    private OpportunityPrimaryQuoteUpdatesTrH(List<Opportunity> newOpportunities, Map<Id, Opportunity> oldOpportunitiesMap) {
        this.newOpportunities = newOpportunities;
        this.oldOpportunitiesMap = oldOpportunitiesMap;
    }

    public override void afterUpdate() {
        updateOrderOnOpportunityPrimaryQuote();
    }
    
    @TestVisible
    private void updateOrderOnOpportunityPrimaryQuote() {
        Set<Id> quoteIds = getClosedWonOppPrimaryQuotes();
        List<SBQQ__Quote__c> quotes = new List<SBQQ__Quote__c>();
        for(Id quoteId : quoteIds){
            quotes.add(new SBQQ__Quote__c(Id = quoteId, SBQQ__Ordered__c = true));
        }
        if(!quotes.isEmpty() && Schema.sObjectType.SBQQ__Quote__c.isUpdateable()){
            update quotes;
        }
    }
    
    @TestVisible
    private Set<Id> getClosedWonOppPrimaryQuotes() {
        Set<Id> quoteIds = new Set<Id>();
        for (Opportunity newOpportunity : newOpportunities) {
            Opportunity oldOpportunity = oldOpportunitiesMap.get(newOpportunity.Id);            
            if (newOpportunity.StageName == CLOSED_WON  
                    && newOpportunity.StageName != oldOpportunity.StageName
                    && newOpportunity.SBQQ__PrimaryQuote__c != null
                    && !newOpportunity.In_Policy_Move_Out__c) {
                quoteIds.add(newOpportunity.SBQQ__PrimaryQuote__c);
            }
        }
        return quoteIds;
    }
}