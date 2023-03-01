/************************************************************************************************************************************
    Author       :   Mikolaj Juras    
    @Description :   set Activity Dates on Opportunity
    Issue No     :   ST-8334
    History      :
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION     DATE                AUTHOR              ISSUE NO        DETAIL
    1         7 Jun 2021       Mikolaj Juras           ST-8334         Initial Developement               
**************************************************************************************************************************************/
public with sharing class EventSetRelatedActivityDatesOnOppTrH extends SObjectTriggerHandler {

    @TestVisible
    private List<Event> newEvents;
    @TestVisible
    private Map<Id, Event> oldEventsMap;
    @TestVisible
    private Set<Id> opportunityIds = new Set<Id>();
    @TestVisible
    private OpportunityRelatedActivitiesManager oppRelatedActivitiesManger;

    
    public EventSetRelatedActivityDatesOnOppTrH() {
        this((List<Event>) Trigger.new, (Map<Id, Event>) Trigger.oldMap);
    }
    
    @TestVisible
    private EventSetRelatedActivityDatesOnOppTrH(List<Event> newEvents, Map<Id, Event> oldEventsMap) {
        this.newEvents = newEvents;
        this.oldEventsMap = oldEventsMap;
        this.opportunityIds = getParentOpportunitiesIds();
        this.oppRelatedActivitiesManger = opportunityIds.isEmpty() ? null : new OpportunityRelatedActivitiesManager(opportunityIds);
    }
    
    public override void afterInsert() {
        if (opportunityIds.isEmpty()) {
            return;
        }
        oppRelatedActivitiesManger.checkActivityOnOpportunities();
    }

    public override void afterUpdate() {
        if (opportunityIds.isEmpty()) {
            return;
        }
        oppRelatedActivitiesManger.checkActivityOnOpportunities();
    }

    private Set<Id> getParentOpportunitiesIds() {
        Set<Id> opportunityIds = new Set<Id>();
        if(newEvents == null){
            return opportunityIds;
        }
        for(Event e : newEvents){ 
            if(e.WhatId?.getSObjectType() == Opportunity.sObjectType){
                opportunityIds.add(e.WhatId);
            }
        }
        return opportunityIds;
    }
}