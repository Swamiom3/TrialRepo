/************************************************************************************************************************************
    Author 	    :   Salesforce
    Description :   This class updates the Pricebook and Currency on Opportunity when Building is updated on Opportunity
    Issue No    :   TWSPG-5031
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION	    DATE			    AUTHOR				    DETAIL
    1		    1 November 2020	    Salesforce     Initial Development
    **************************************************************************************************************************************/
public class OpportunityPricebookUpdateTrH extends SObjectTriggerHandler {
    @TestVisible
    private final List<Opportunity> newOpportunities;
    @TestVisible
    private final Map<Id, Opportunity> newOpportunitiesMap;
    @TestVisible
    private final Map<Id, Opportunity> oldOpportunitiesMap;
    private BuildingSelector buildSelector = new BuildingSelector();

    public OpportunityPricebookUpdateTrH() {
        this((List<Opportunity>) Trigger.new,
             (Map<Id, Opportunity>) Trigger.newMap,
             (Map<Id, Opportunity>) Trigger.oldMap);
    }

    @TestVisible
    private OpportunityPricebookUpdateTrH(List<Opportunity> newOpportunities,
                                 Map<Id, Opportunity> newOpportunitiesMap,
                                 Map<Id, Opportunity> oldOpportunitiesMap){
        this.newOpportunities = newOpportunities;
        this.newOpportunitiesMap = newOpportunitiesMap;
        this.oldOpportunitiesMap = oldOpportunitiesMap;
    }

    public override void beforeInsert() {
        updateOpportunityPricebook();
    }

    public override void beforeUpdate() {
        updateOpportunityPricebook();
    }

    private void updateOpportunityPricebook() {
        Set<Id> buildingIds = getOpportunityBuidlingIds();
        Map<Id, Building__c> buildings = new Map<Id, Building__c>(buildSelector.getBuildingsWithPriceBookAndCurrencyByIds(buildingIds));

        for(Opportunity opp : newOpportunities){
            if(String.isNotBlank(opp.Building__c) && String.isBlank(opp.SBQQ__PrimaryQuote__c) && isBuildingChangedOnOpportunity(opp)){
                Id buildingPricebookId = buildings.get(opp.Building__c)?.Building_Price_Book_Id__c;
                opp.Pricebook2Id = buildingPricebookId;
                opp.SBQQ__QuotePricebookId__c = buildingPricebookId;
               
            }
        }
    }

    private Boolean isBuildingChangedOnOpportunity(Opportunity opportunity) {
        Boolean isInsert = (oldOpportunitiesMap == null || oldOpportunitiesMap.isEmpty());
        return (isInsert || TriggerUtility.isFieldValueChanged(opportunity, oldOpportunitiesMap.get(opportunity.Id), 'Building__c'));
    }

    private Set<Id> getOpportunityBuidlingIds() {
        Set<Id> buildingsToQuery = new Set<Id>();
        for(Opportunity opp : newOpportunities){
            buildingsToQuery.add(opp.Building__c);
        }
        buildingsToQuery.remove(null);
        return buildingsToQuery;
    }
}