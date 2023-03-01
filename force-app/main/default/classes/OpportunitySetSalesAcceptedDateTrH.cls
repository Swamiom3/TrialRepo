/*********************************************************************************************************
    Author        :  Ashish Sharma
    Description   :  Sets sales accepted date on opportunity when stage changes from Qualifying to selling
    Issue No.     :  TWSPG-14140
    History       :
-----------------------------------------------------------------------------------------------------------
    VERSION        DATE            AUTHOR             DETAIL
    1           08-Sept-2022      Ashish Sharma    Initial development 
**********************************************************************************************************/
public with sharing class OpportunitySetSalesAcceptedDateTrH extends SObjectTriggerHandler{
    private final String QUALIFYING_STAGE_NAME = 'Qualifying';
    private final String CLOSED_LOST_STAGE_NAME = 'Closed Lost';
    @TestVisible
    private List<Opportunity> newOpportunities;
    @TestVisible
    private Map<Id, Opportunity> oldOpportunitiesMap;

    public OpportunitySetSalesAcceptedDateTrH() {
        this((List<Opportunity>) Trigger.new, (Map<Id, Opportunity>) Trigger.oldMap);
    }

    @TestVisible
    private OpportunitySetSalesAcceptedDateTrH(List<Opportunity> newOpportunities, Map<Id,Opportunity> oldOpportunitiesMap) {
        this.newOpportunities = newOpportunities;
        this.oldOpportunitiesMap = oldOpportunitiesMap;
    }

    public override void beforeUpdate() {
        setSalesAcceptedDate();
    }
    
    private void setSalesAcceptedDate() { 
        for(Opportunity newOpportunity : newOpportunities) {
            Opportunity oldOpportunity = oldOpportunitiesMap?.get(newOpportunity.Id);            
            if (newOpportunity.Sales_Accepted_Date_N__c == null && isStageChangedfromQualifying(newOpportunity, oldOpportunity)) {
                newOpportunity.Sales_Accepted_Date_N__c = System.today(); 
            }
        }
    }
    
    private boolean isStageChangedfromQualifying(Opportunity newOpportunity, Opportunity oldOpportunity) {
        return TriggerUtility.isFieldValueChanged(newOpportunity, oldOpportunity, 'StageName') 
            && oldOpportunity.StageName == QUALIFYING_STAGE_NAME && newOpportunity.StageName == 'Selling';
    }
}