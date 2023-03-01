/*********************************************************************************************************
    Author        :  Ishwar Shinde
    Description   :  If Tour Status updated to Scheduled/Completed then Opportunity Stage updates to 
                     Qualifying/Selling.
    Issue No.     :  TWSPG-9281
    History       :
-----------------------------------------------------------------------------------------------------------
    VERSION        DATE            AUTHOR             DETAIL
    1          11-Apr-2022      Ishwar Shinde     Initial Developement
**********************************************************************************************************/
public with sharing class TourStatusUpdateOpportunityStageTrH extends SObjectTriggerHandler  {
    
    @TestVisible
    private List<ServiceAppointment> newTours;
    @TestVisible
    private Map<Id, ServiceAppointment> oldToursMap;
    @TestVisible
    private static OpportunitySelector oppSelector = new OpportunitySelector();
    private final List<String> statusesToAvoid = new List<String>{'Selling', 'Negotiating', 'Closing'};
  
    public TourStatusUpdateOpportunityStageTrH() {
        this((List<ServiceAppointment>) Trigger.new, (Map<Id, ServiceAppointment>) Trigger.oldMap);
    }
    @TestVisible
    private TourStatusUpdateOpportunityStageTrH(List<ServiceAppointment> newTours, Map<Id, ServiceAppointment> oldToursMap) {
        this.newTours = newTours;
        this.oldToursMap = oldToursMap;
    }
    public override void afterUpdate() {
        updateOpportunityStage();
    }
    private void updateOpportunityStage() {

        Set<Id> opportunityIds = new Set<Id>();
        List<ServiceAppointment> validTours = new List<ServiceAppointment>();
        for (ServiceAppointment tour : newTours) {
            ServiceAppointment oldTour = oldToursMap?.get(tour.Id);
            if (tour.Opportunity_Id__c != null && TriggerUtility.isFieldValueChanged(tour, oldTour, 'Status')) {
                opportunityIds.add(tour.Opportunity_Id__c);
                validTours.add(tour);
            }
        }
        if (opportunityIds.isEmpty()) {
            return;
        }
        Map<Id, Opportunity> opportunities = new Map<Id, Opportunity>(oppSelector.getOpportunitiesByIds(opportunityIds, new List<String>{'Id', 'StageName'}));
        
        Map<Id,Opportunity> opportunitiesToUpdate = new Map<Id,Opportunity>();
        Map<String, Object> statusMappings = Settings.getMetadataSettingByDevNameAsMap('TourOpportunityStatusMappings');
        Map<String, Object> tourOppStatusMappings = (Map<String, Object>) statusMappings.get('touropportunitystatus');
        for (ServiceAppointment tour : validTours) {
            if (tourOppStatusMappings.get(tour.Status.toLowerCase()) != null 
                    && opportunities.containsKey(tour.Opportunity_Id__c) 
                    && !statusesToAvoid.contains(opportunities.get(tour.Opportunity_Id__c).StageName)) {
                opportunitiesToUpdate.put(tour.Opportunity_Id__c, new Opportunity(Id = tour.Opportunity_Id__c, 
                                                                                  StageName = (String)tourOppStatusMappings.get(tour.Status.toLowerCase()), 
                                                                                  Regional_Migration_Exemption__c = true));
            }
        }

        if (!opportunitiesToUpdate.isEmpty()) {
            DmlConsolidatorDefault.getInstance().add(opportunitiesToUpdate.values(), DmlConsolidator.Operation.FOR_UPDATE);
        }
    }
}