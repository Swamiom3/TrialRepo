/************************************************************************************************************************************
   Author      :   Salesforce
   Description :   This class contain method to create/delete absence records when non operating hours is created/deleted for the building.
   ----------------------------------------------------------------------------------------------------------------------------------
    VERSION    DATE           AUTHOR            DETAIL
    1         27 Oct 2021    Salesforce       TWSPG-5345
 **************************************************************************************************************************************/
public with sharing class NonOperatingHoursManageAbsencesTrH  extends SObjectTriggerHandler {
    @TestVisible
    private final List<Non_Operating_Hours__c> newNonOperatingHours;
    @TestVisible
    private final List<Non_Operating_Hours__c> oldNonOperatingHours;

    public NonOperatingHoursManageAbsencesTrH() {
        this((List<Non_Operating_Hours__c>) Trigger.new,
            (List<Non_Operating_Hours__c>) Trigger.old);
    }

    @TestVisible
    private NonOperatingHoursManageAbsencesTrH(List<Non_Operating_Hours__c> newNonOperatingHours,
                                 List<Non_Operating_Hours__c> oldNonOperatingHours){
        this.newNonOperatingHours = newNonOperatingHours;
        this.oldNonOperatingHours = oldNonOperatingHours;
    }

    public override void afterInsert() {
        insertAbsenceRecods();
    }

    public override void beforeDelete() {
        deleteAbsenceRecords();
    }

    private void insertAbsenceRecods() {
        Map<Id, Non_Operating_Hours__c> buildingtoNonOperatingHoursMap = new Map<Id, Non_Operating_Hours__c>();
        for (Non_Operating_Hours__c noh : newNonOperatingHours) {
            if (noh.Closure_Type__c == HolidayTypeConstants.CLOSURE_TYPE_HOLIDAY) {
                buildingtoNonOperatingHoursMap.put(noh.Building_Id__c, noh);
            }
        }
        if (buildingtoNonOperatingHoursMap.isEmpty()) {
            return;
        }
        List<ResourceAbsence> absenceRecordsToInsert = new List<ResourceAbsence>();
        ServiceTerritoryMemberSelector serviceTerritoryMemberSelector = new ServiceTerritoryMemberSelector();
        for (ServiceTerritoryMember stm : serviceTerritoryMemberSelector.getServiceTerritoryMembersWithTimeSlotsByBuilding(new List<Id>(buildingtoNonOperatingHoursMap.keySet()))) {
            Non_Operating_Hours__c noh = buildingtoNonOperatingHoursMap.get(stm.ServiceTerritory.Building_Id__c);
            absenceRecordsToInsert.add(new ResourceAbsence(End = noh.End_Time__c, Non_Operating_Hours_Id__c = noh.Id, ResourceId = stm.ServiceResourceId, Start = noh.Start_Time__c, Type = HolidayTypeConstants.RESOURCE_ABSENCE_TYPE_HOLIDAY));
        }
        if (!absenceRecordsToInsert.isEmpty()) {
            dml.add(absenceRecordsToInsert, DmlConsolidator.Operation.FOR_INSERT);
        }
    }

    private void deleteAbsenceRecords() {
        List<Id> nohIds = new List<Id>();
        for (Non_Operating_Hours__c noh : oldNonOperatingHours) {
            if (noh.Closure_Type__c == HolidayTypeConstants.CLOSURE_TYPE_HOLIDAY) {
                nohIds.add(noh.Id);
            }
        }
        ResourceAbsenceSelector resourceAbsenceSelector = new ResourceAbsenceSelector();
        List<ResourceAbsence> resourceAbsencesToDelete = resourceAbsenceSelector.getResourceAbsenceByNonOperatingHoursIds(nohIds);
        if (!resourceAbsencesToDelete.isEmpty()) {
            dml.add(resourceAbsencesToDelete, DmlConsolidator.Operation.FOR_DELETE);
        }
    }
}