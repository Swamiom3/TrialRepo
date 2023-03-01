/************************************************************************************************************************************
    Author      :   Salesforce 
    Description :   Trigger handler class for updating Order checkbox to true on primary quote under the Opportunity.
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION     DATE                AUTHOR                  DETAIL
    1           Sept 3rd, 2021        Salesforce             Initial version
**************************************************************************************************************************************/
public with sharing class OpportunityCancelationUpdatesTrH extends SObjectTriggerHandler {
    public static final String CLOSED_WON = 'Closed Won';
    @TestVisible
    private List<Opportunity> newOpportunities;
    @TestVisible
    private Map<Id, Opportunity> oldOpportunitiesMap;
    public static OpportunitySelector opportunitySelector = new OpportunitySelector();

    public OpportunityCancelationUpdatesTrH() {
        this((List<Opportunity>) Trigger.new, (Map<Id, Opportunity>) Trigger.oldMap);
    }

    @TestVisible
    private OpportunityCancelationUpdatesTrH(List<Opportunity> newOpportunities, Map<Id, Opportunity> oldOpportunitiesMap) {
        this.newOpportunities = newOpportunities;
        this.oldOpportunitiesMap = oldOpportunitiesMap;
    }

    public override void afterUpdate() {
        updateStageOnCancelationOpportunity();
    }
    
    @TestVisible
    private void updateStageOnCancelationOpportunity() {
        Set<Id> closedReplacementOppIds = getclosedReplacementOppIds();
        List<Opportunity> cancelOpportunities = new List<Opportunity>();
        if(!closedReplacementOppIds.isEmpty()){        
            for(Opportunity opportunity : opportunitySelector.getCancellationOpportunities('Cancellation',closedReplacementOppIds,CLOSED_WON)){
                cancelOpportunities.add(new opportunity(Id = opportunity.Id, StageName = CLOSED_WON));
            }
        }
        if(!cancelOpportunities.isEmpty() && Schema.sObjectType.Opportunity.isUpdateable()){
            update cancelOpportunities;
        }
    }
    
    @TestVisible
    private Set<Id> getclosedReplacementOppIds() {
        Set<Id> closedReplacementOppIds = new Set<Id>();
        for (Opportunity newOpportunity : newOpportunities) {
            Opportunity oldOpportunity = oldOpportunitiesMap.get(newOpportunity.Id);            
            if (newOpportunity.StageName == CLOSED_WON
                    && TriggerUtility.isFieldValueChanged(newOpportunity, oldOpportunity, 'StageName')
                    && newOpportunity.Amendment_Opportunity_Type__c == 'Replacement') {
                closedReplacementOppIds.add(newOpportunity.Id);
            }
        }
        return closedReplacementOppIds;
    }
}