public with sharing class BuildingHostManageTimeSlotsTrH extends SObjectTriggerHandler {
    @TestVisible
    private final List<ServiceTerritoryMember> newServiceTerritoryMembers;
    @TestVisible
    private final Map<Id, ServiceTerritoryMember> oldServiceTerritoryMembersMap;
    private final String END_DATE_FIELD_API_NAME = 'EffectiveEndDate';

    public BuildingHostManageTimeSlotsTrH() {
        this((List<ServiceTerritoryMember>) Trigger.new,
            (Map<Id, ServiceTerritoryMember>) Trigger.oldMap);
    }

    @TestVisible
    private BuildingHostManageTimeSlotsTrH(List<ServiceTerritoryMember> newServiceTerritoryMembers, Map<Id, ServiceTerritoryMember> oldServiceTerritoryMembersMap){
        this.newServiceTerritoryMembers = newServiceTerritoryMembers;
        this.oldServiceTerritoryMembersMap = oldServiceTerritoryMembersMap;
    }

    public override void afterUpdate() {
        deleteTimeSlotRecords();
    }

    private void deleteTimeSlotRecords() {
        List<Id> operatingHoursIds = new List<Id>();
        for (ServiceTerritoryMember stm : newServiceTerritoryMembers) {
            if (stm.Has_Timeslots__c && TriggerUtility.isFieldValueChanged(stm, oldServiceTerritoryMembersMap.get(stm.Id), END_DATE_FIELD_API_NAME) && stm.EffectiveEndDate != null) {
                operatingHoursIds.add(stm.OperatingHoursId);
            }
        }
        if (operatingHoursIds.isEmpty()) {
            return;
        }
        List<TimeSlot> timeSlotsToDelete = new TimeSlotsSelector().getTimeSlotsByOPeratingHoursIds(operatingHoursIds);
        if (!timeSlotsToDelete.isEmpty()) {
            dml.add(timeSlotsToDelete, DmlConsolidator.Operation.FOR_DELETE);
        }
    }
}