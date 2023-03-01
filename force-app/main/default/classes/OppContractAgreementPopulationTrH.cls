/************************************************************************************************************************************
    Author       :  Maciej Miłosz   
    @Description :  Populate contract agreement id and link when opportunity turns to closed won
    Issue No     :  TWSPG-9859
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION     DATE                AUTHOR              ISSUE NO        DETAIL
    1           6 June 2022         Maciej Miłosz       TWSPG-9859      Initial Developement              
**************************************************************************************************************************************/

public with sharing class OppContractAgreementPopulationTrH extends SObjectTriggerHandler{
    private Map<Id, Opportunity> newOpportunitiesMap;
    private Map<Id, Opportunity> oldOpportunitiesMap;
    private List<Opportunity> filteredOpportunities;
    private List<Id> filteredOpportunitieIds;

    public OppContractAgreementPopulationTrH() {
        this((Map<Id, Opportunity>) Trigger.newMap, (Map<Id, Opportunity>) Trigger.oldMap);
    }

    @TestVisible
    private OppContractAgreementPopulationTrH(Map<Id, Opportunity> newOpportunitiesMap, Map<Id, Opportunity> oldOpportunitiesMap) {
        this.newOpportunitiesMap = newOpportunitiesMap;
        this.oldOpportunitiesMap = oldOpportunitiesMap;
        this.filteredOpportunities = new List<Opportunity>();
        this.filteredOpportunitieIds = new List<Id>();
    }

    public override void beforeUpdate() {
        filterOpportunities();
        if(filteredOpportunitieIds.isEmpty()){
            return;
        }
        populateURL();
    }

    private void populateURL(){
        QuoteSelector selector = new QuoteSelector();
        List<SBQQ__Quote__c> quotes = selector.getPrimaryQuotesForOpportunities(filteredOpportunitieIds);
        Map<Id, SBQQ__Quote__c> opportunityToQuote = new Map<Id, SBQQ__Quote__c>();
        for(SBQQ__Quote__c quote : quotes){
            opportunityToQuote.put(quote.SBQQ__Opportunity2__c, quote);
        }
        for (Opportunity filteredOpportunity : filteredOpportunities) {
            if(!opportunityToQuote.containsKey(filteredOpportunity.Id)){
                continue;
            }
            SBQQ__Quote__c primaryQuote = opportunityToQuote.get(filteredOpportunity.Id);
            filteredOpportunity.Signed_Contract_URL__c = primaryQuote.Contract_Public_URL__c;
            List<APXT_Redlining__Contract_Agreement__c> contractAgrerments = primaryQuote.getSObjects('Contract_Agreements__r');
            if(contractAgrerments.isEmpty()){
                continue;
            }
            filteredOpportunity.Contract_UUID__c = contractAgrerments[0].Id;
        }
    }

    private void filterOpportunities(){
        for(Opportunity item : newOpportunitiesMap.values()){
            if(item.isWon 
                && item.StageName == GlobalConstants.OPP_CLOSED_WON_STAGE_NAME
                && TriggerUtility.isFieldsValueChanged(item, oldOpportunitiesMap.get(item.Id), new Set<String>{'isWon', 'StageName'})){
                    filteredOpportunities.add(item);
                    filteredOpportunitieIds.add(item.Id);
            }
        }
    }

}