/************************************************************************************************************************************
   Author      :   Salesforce
   Description :   This class contain method to deactivate building Hosts when service resource is deactivated.
   ----------------------------------------------------------------------------------------------------------------------------------
    VERSION    DATE           AUTHOR            DETAIL
    1         09 Nov 2021    Salesforce       Initial Development
 **************************************************************************************************************************************/
public with sharing class ServiceResourceDeactivateBuildingHostTrH  extends SObjectTriggerHandler {
    @TestVisible
    private final List<ServiceResource> newServiceResourceRecords;
    @TestVisible
    private final Map<Id, ServiceResource> oldServiceResourceRecordsMap;
    private final String IS_ACTIVE_FIELD_API_NAME = 'IsActive';

    public ServiceResourceDeactivateBuildingHostTrH() {
        this((List<ServiceResource>) Trigger.new,
            (Map<Id, ServiceResource>) Trigger.oldMap);
    }

    @TestVisible
    private ServiceResourceDeactivateBuildingHostTrH(List<ServiceResource> newServiceResourceRecords, Map<Id, ServiceResource> oldServiceResourceRecordsMap){
        this.newServiceResourceRecords = newServiceResourceRecords;
        this.oldServiceResourceRecordsMap = oldServiceResourceRecordsMap;
    }

    public override void afterUpdate() {
        deactiveBuildingHosts();
    }

    private void deactiveBuildingHosts() {
        List<Id> deactivatedServiceResourceIds = new List<Id>();
        for (ServiceResource sr : newServiceResourceRecords) {
            if (TriggerUtility.isFieldValueChanged(sr, oldServiceResourceRecordsMap.get(sr.Id), IS_ACTIVE_FIELD_API_NAME) && !sr.IsActive) {
                deactivatedServiceResourceIds.add(sr.Id);
            }
        }
        if (deactivatedServiceResourceIds.isEmpty()) {
            return;
        }
        ServiceTerritoryMemberSelector serviceTerritoryMemberSelector = new ServiceTerritoryMemberSelector();
        List<ServiceTerritoryMember> buildingHostsToRemove = new List<ServiceTerritoryMember>();
        for(ServiceTerritoryMember stm : serviceTerritoryMemberSelector.getActiveBuildingHostsByHostIds(deactivatedServiceResourceIds)) {
            stm.EffectiveEndDate = System.now();
            buildingHostsToRemove.add(stm);
        }
        if (!buildingHostsToRemove.isEmpty()) {
            dml.add(buildingHostsToRemove, DmlConsolidator.Operation.FOR_UPDATE);
        }
    }
}