/*********************************************************************************************************
    Author        :  Ishwar Shinde
    Description   :  once tour inserted/updated related to journey then journey stage gets converted
    Issue No.     :  TWSPG-10524
    History       :
-----------------------------------------------------------------------------------------------------------
    VERSION        DATE            AUTHOR             DETAIL
    1          02-May-2022      Ishwar Shinde     Initial Developement 
**********************************************************************************************************/
public with sharing class TourUpdateJourneyStatusTrH extends SObjectTriggerHandler {
    @TestVisible
    private List<ServiceAppointment> newTours;
    private static final JourneySelector journeySelector = new JourneySelector();
    public TourUpdateJourneyStatusTrH() {
        this((List<ServiceAppointment>) Trigger.new);
    }

    @TestVisible
    private TourUpdateJourneyStatusTrH(List<ServiceAppointment> newTours) {
        this.newTours = newTours;
    }
    
    public override void afterInsert() {
        updateJourneyStage();
    }
    
    public override void afterUpdate() {
        updateJourneyStage();
    }
    
    public void updateJourneyStage() {
        Set<Id> journeyIds = new Set<Id>();
        for (ServiceAppointment tour : newTours) {
            if (tour.Journey_Id__c != null) {
                journeyIds.add(tour.Journey_Id__c);
            }
        }
        if (journeyIds.isEmpty()) {
            return;
        }
        
        Set<String> closeStage = (Set<String>) JSON.deserialize(MetadataSetting__mdt.getInstance('ClosedJourneyStages').Data__c, Set<String>.class);
        List<String> fields = new List<String>{ 'Id', 'Name', 'Status__c'};
        
        List<Journey__c> journeysToUpdate = new List<Journey__c>();
        for (Journey__c journey : journeySelector.getJourneyWithTours(journeyIds, closeStage)) {
            if (journey.Service_Appointments__r.isEmpty()) {	
                continue;
            }
            for (ServiceAppointment tour : journey.Service_Appointments__r) {
                if (tour.Status != GlobalConstants.TOUR_COMPLETED) {
                    journey.Status__c = GlobalConstants.TOUR_CONVERTED;
                    journeysToUpdate.add(journey);
                    break;
                }
            }
        }
        if (!journeysToUpdate.isEmpty()) {
            update journeysToUpdate;
        }
    }
}