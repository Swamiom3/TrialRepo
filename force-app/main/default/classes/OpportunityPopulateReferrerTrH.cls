public with sharing class OpportunityPopulateReferrerTrH extends SObjectTriggerHandler {
    
    @TestVisible
    private List<Opportunity> newOpportunities;
    @TestVisible
    private Map<Id, Opportunity> oldOpportunitiesMap;
    @TestVisible
    private JourneySelector journeySelector = new JourneySelector();
    @TestVisible
    Map<Id,Id> JourneyToReferrerMapping = new Map<Id,Id>();
    @TestVisible
    private String JOURNEY_CREATION_SOURCE = 'Inbound Lead';
    @TestVisible
    private String ADD_OPPORTUNITY= 'From Add Opportunity';
    @TestVisible
    private String BOOK_TOUR = 'From Manage/Book Tour';
    
    public OpportunityPopulateReferrerTrH() {
        this((List<Opportunity>) Trigger.new, (Map<Id, Opportunity>) Trigger.oldMap);
    }
    
    @TestVisible
    private OpportunityPopulateReferrerTrH(List<Opportunity> newOpps, Map<Id,Opportunity> oldOppsMap){
        newOpportunities = newOpps;
        oldOpportunitiesMap = oldOppsMap;
    }
    
    public override void beforeInsert() {
        insertOpportunityReferrer();
    }
    
    private void insertOpportunityReferrer(){
        Set<Id> journeyIds = new Set<Id>();
        for(Opportunity oppo : newOpportunities){
            journeyIds.add(oppo.Journey__c);
        }
        List<Journey__c> journeys = journeySelector.getJourneysWithReferrer(journeyIds, JOURNEY_CREATION_SOURCE);
        for(Journey__c journey : journeys){
            JourneyToReferrerMapping.put(journey.Id,journey.Referrer__c);
        }
        for(Opportunity opp: newOpportunities){
            if(opp.Opportunity_Creation_Source__c == ADD_OPPORTUNITY ||
               opp.Opportunity_Creation_Source__c == BOOK_TOUR ){
                   opp.Referrer__c = JourneyToReferrerMapping.get(opp.Journey__c);
               }
        }
    }
}