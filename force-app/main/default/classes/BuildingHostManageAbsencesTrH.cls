/************************************************************************************************************************************
   Author      :   Salesforce
   Description :   This class contain method to create/delete absence records when building host is created/deleted for the building.
   ----------------------------------------------------------------------------------------------------------------------------------
    VERSION    DATE           AUTHOR            DETAIL
    1         27 Oct 2021    Salesforce       TWSPG-5345
 **************************************************************************************************************************************/
public with sharing class BuildingHostManageAbsencesTrH  extends SObjectTriggerHandler {
    @TestVisible
    private final List<ServiceTerritoryMember> newServiceTerritoryMembers;
    @TestVisible
    private final Map<Id, ServiceTerritoryMember> oldServiceTerritoryMembersMap;

    public BuildingHostManageAbsencesTrH() {
        this((List<ServiceTerritoryMember>) Trigger.new,
            (Map<Id, ServiceTerritoryMember>) Trigger.oldMap);
    }

    @TestVisible
    private BuildingHostManageAbsencesTrH(List<ServiceTerritoryMember> newServiceTerritoryMembers, Map<Id, ServiceTerritoryMember> oldServiceTerritoryMembersMap){
        this.newServiceTerritoryMembers = newServiceTerritoryMembers;
        this.oldServiceTerritoryMembersMap = oldServiceTerritoryMembersMap;
    }

    public override void afterInsert() {
        insertResourceAbsenceRecords();
    }

    public override void afterUpdate() {
        deleteResourceAbsenceRecords();
    }

    private void insertResourceAbsenceRecords() {
        Set<Id> fiteredServiceTerritoryIds = new Set<Id>();
        List<ServiceTerritoryMember> fiteredServiceTerritoryMembers = new List<ServiceTerritoryMember>();
        for (ServiceTerritoryMember stm : newServiceTerritoryMembers) {
            if (stm.Has_Timeslots__c) {
                fiteredServiceTerritoryIds.add(stm.ServiceTerritoryId);
                fiteredServiceTerritoryMembers.add(stm);
            }
        }
        if (fiteredServiceTerritoryMembers.isEmpty()) {
            return;
        }
        Map<Id, Id> serviceTerritoryToBuildingMap = new Map<Id, Id>();
        for (ServiceTerritory st : new ServiceTerritorySelector().getServiceTerritoryByIds(new List<Id>(fiteredServiceTerritoryIds))) {
            serviceTerritoryToBuildingMap.put(st.Id, st.Building_Id__c);
        }
        Map<Id, List<Non_Operating_Hours__c>> buildingToNonOperatingHoursMap = new Map<Id, List<Non_Operating_Hours__c>>();
        for (Non_Operating_Hours__c noh : new NonOperatingHoursSelector().getNonOperatingHoursByBuildingIds(new List<Id>(serviceTerritoryToBuildingMap.values()), HolidayTypeConstants.CLOSURE_TYPE_HOLIDAY)) {
            if (!buildingToNonOperatingHoursMap.containsKey(noh.Building_Id__c)) {
                buildingToNonOperatingHoursMap.put(noh.Building_Id__c, new List<Non_Operating_Hours__c>());
            }
            buildingToNonOperatingHoursMap.get(noh.Building_Id__c).add(noh);
        }
        if (buildingToNonOperatingHoursMap.isEmpty()) {
            return;
        }
        List<ResourceAbsence> resourceAbsenceRecordsToInsert = new List<ResourceAbsence>();
        for (ServiceTerritoryMember stm : fiteredServiceTerritoryMembers) {
            for (Non_Operating_Hours__c noh : buildingToNonOperatingHoursMap.get(serviceTerritoryToBuildingMap.get(stm.ServiceTerritoryId))) {
                resourceAbsenceRecordsToInsert.add(new ResourceAbsence(End = noh.End_Time__c, Non_Operating_Hours_Id__c = noh.Id, ResourceId = stm.ServiceResourceId, Start = noh.Start_Time__c, Type = HolidayTypeConstants.RESOURCE_ABSENCE_TYPE_HOLIDAY));
            }
        }
        if (!resourceAbsenceRecordsToInsert.isEmpty()) {
            dml.add(resourceAbsenceRecordsToInsert, DmlConsolidator.Operation.FOR_INSERT);
        }
    }

    private void deleteResourceAbsenceRecords() {
        List<Id> serviceResourceIds = new List<Id>();
        List<Id> serviceTerritoryIds = new List<Id>();
        for (ServiceTerritoryMember stm : newServiceTerritoryMembers) {
            if (stm.Has_Timeslots__c && oldServiceTerritoryMembersMap.get(stm.Id).EffectiveEndDate == null && stm.EffectiveEndDate != null) {
                serviceTerritoryIds.add(stm.ServiceTerritoryId);
                serviceResourceIds.add(stm.ServiceResourceId);
            }
        }
        List<Id> nonOperatingHoursIds = new List<Id>();
        if (serviceTerritoryIds.isEmpty()) {
            return;
        }
        for (Non_Operating_Hours__c noh : new NonOperatingHoursSelector().getNonOperatingHoursByServiceTerritoryIds(serviceTerritoryIds)) {
            nonOperatingHoursIds.add(noh.Id);
        }
        List<ResourceAbsence> resourceAbsencesToDelete = new ResourceAbsenceSelector().getResourceAbsenceByNonOperatingHoursAndServiceResourceIds(nonOperatingHoursIds, serviceResourceIds);
        if (!resourceAbsencesToDelete.isEmpty()) {
            dml.add(resourceAbsencesToDelete, DmlConsolidator.Operation.FOR_DELETE);
        }
    }
}