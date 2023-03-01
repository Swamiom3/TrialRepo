/************************************************************************************************************************************
    Author       :   Mikolaj Juras    
    Description  :   Class to sumarize activities and populate fields on Opportunity
    Issue No     :   ST-8334
    History      :
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION     DATE                AUTHOR              ISSUE NO        DETAIL
    1           24 May 2021     Mikolaj Juras       ST-8334         Initial Developement 
**************************************************************************************************************************************/
public without sharing class OpportunityRelatedActivitiesManager {

    @TestVisible
    private static OpportunitySelector opportunitySelector = new OpportunitySelector();
    @TestVisible
    private List<Opportunity> opportunitiesToUpdate;
    @TestVisible
    private Set<Id> oppsIdToUpdate; 

    public OpportunityRelatedActivitiesManager(Set<Id> oppsIdToUpdate) {
        this.oppsIdToUpdate = oppsIdToUpdate;
        opportunitiesToUpdate = opportunitySelector.getOpportunitiesWithRelatedActivities(oppsIdToUpdate);
    }

    public void checkActivityOnOpportunities() {
        
        for (Opportunity opp : opportunitiesToUpdate) {
            if (opp.Tasks.isEmpty() && opp.Events.isEmpty()) {
                continue;
            }
            setFirstActivityCreatedDate(opp);
            setTotalNumberOfActiviteis(opp);
            setRelatedActivityLastModifiedDate(opp);
        }
        updateOpportunities(opportunitiesToUpdate);
    }

    private void setFirstActivityCreatedDate(Opportunity opp) {
        Datetime activityCreatedDate = opp.First_Activity_Date__c;
        for (Task t : opp.Tasks) {
            if (activityCreatedDate == null || t.CreatedDate < activityCreatedDate) {
                activityCreatedDate = t.CreatedDate;
            }
        }
        for (Event e : opp.Events) {
            if (activityCreatedDate == null || e.CreatedDate < activityCreatedDate) {
                activityCreatedDate = e.CreatedDate;
            }
        }
        opp.First_Activity_Date__c = activityCreatedDate;
    }

    private void setTotalNumberOfActiviteis(Opportunity opp){
        opp.Total_Number_of_Activities__c = opp.Tasks.size() + opp.Events.size();
    }

    private void updateOpportunities(List<Opportunity> oppToUpdate){
        MetadataDrivenTriggerHandler.disableExecution();
        try {
            update oppToUpdate;
        } catch(Exception e){
            ApexDebugLog.logException(e, JSON.serialize(oppToUpdate), 'OpportunityRelatedActivitiesManager', 'save');                      
        } 
        MetadataDrivenTriggerHandler.enableExecution();
    }

    private void setRelatedActivityLastModifiedDate(Opportunity opp) {
        Datetime activityLastModifiedDate = opp.Last_Related_Activity_Modified_Date__c;
        if (activityLastModifiedDate == null && opp.Events.isEmpty() && opp.Tasks.isEmpty()) {
            return;
        }
        if (!opp.Events.isEmpty() && (activityLastModifiedDate == null || opp.Events[0].LastModifiedDate > activityLastModifiedDate)) {
            activityLastModifiedDate = opp.Events[0].LastModifiedDate;
        }
        if (!opp.Tasks.isEmpty() && (activityLastModifiedDate == null || opp.Tasks[0].LastModifiedDate > activityLastModifiedDate)) {
            activityLastModifiedDate = opp.Tasks[0].LastModifiedDate;
        }
        opp.Last_Related_Activity_Modified_Date__c = Date.valueOf(activityLastModifiedDate);
    }
}