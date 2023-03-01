/*************************************************************************************************************************************
 Author      :   Salesforce
 Description :   This class is selector implementation of particular SObject (ServiceTerritoryMember)
 --------------------------------------------------------------------------------------------------------------------------------------
 VERSION         DATE            AUTHOR              DETAIL
 1               18 Oct 2021     Salesforce       Initial Deployment
 **************************************************************************************************************************************/
public with sharing class ServiceTerritoryMemberSelector extends SObjectSelector {
    public ServiceTerritoryMemberSelector() {
        super(ServiceTerritoryMember.getSObjectType());
    }

    /****************************************************************************************************************************
     Author              : Salesforce
     Description         : This method is used to get default fields from Object
     Created Date        : 18 Oct 2021
     *****************************************************************************************************************************/
    public override Set<String> getDefaultFields(){
        return new Set<String> { 'Id' };
    }

    /****************************************************************************************************************************
     Author              : Salesforce
     Description         : This method is used to get actove service territory members
     Created Date        : 18 Oct 2021
     *****************************************************************************************************************************/
    public List<ServiceTerritoryMember> getServiceTerritoryMembers(List<Id> buildngIds, List<Id> userIds) {
        if (userIds.isEmpty() || buildngIds.isEmpty()) {
            return new List<ServiceTerritoryMember>();
        }
        List<String> fields = new List<String> { 'Id', 'EffectiveStartDate', 'EffectiveEndDate', 'Has_Timeslots__c', 'ServiceResourceId' };
        String whereClause = 'EffectiveEndDate = null AND ServiceResource.RelatedRecordId IN: userIds AND ServiceTerritoryId IN (SELECT Id FROM ServiceTerritory WHERE Building_Id__c IN :buildngIds)';
        List<Object> bindings = new List<Object> { userIds, buildngIds };
        return (List<ServiceTerritoryMember>) getSObjects(fields, whereClause, bindings);
    }

    /****************************************************************************************************************************
     Author              : Salesforce
     Description         : This method is used to get active service territory members for buildings
     Created Date        : 18 Oct 2021
     *****************************************************************************************************************************/
    public List<ServiceTerritoryMember> getServiceTerritoryMembersWithTimeSlotsByBuilding(List<Id> buildngIds) {
        if (buildngIds.isEmpty()) {
            return new List<ServiceTerritoryMember>();
        }
        List<String> fields = new List<String> { 'Id', 'EffectiveStartDate', 'EffectiveEndDate', 'ServiceTerritory.Building_Id__c', 'ServiceResourceId' };
        String whereClause = 'EffectiveEndDate = null AND Has_Timeslots__c = TRUE AND ServiceTerritoryId IN (SELECT Id FROM ServiceTerritory WHERE Building_Id__c IN :buildngIds)';
        List<Object> bindings = new List<Object> { buildngIds };
        return (List<ServiceTerritoryMember>) getSObjects(fields, whereClause, bindings);
    }

    /****************************************************************************************************************************
     Author              : Salesforce
     Description         : This method is used to get active service territory members by Service Resorce Ids
     Created Date        : 18 Oct 2021
     *****************************************************************************************************************************/
    public List<ServiceTerritoryMember> getActiveBuildingHostsByHostIds(List<Id> serviceResourceIds) {
        if (serviceResourceIds.isEmpty()) {
            return new List<ServiceTerritoryMember>();
        }
        List<String> fields = new List<String> { 'Id', 'EffectiveEndDate' };
        String whereClause = 'EffectiveEndDate = null AND ServiceResourceId IN :serviceResourceIds';
        List<Object> bindings = new List<Object> { serviceResourceIds };
        return (List<ServiceTerritoryMember>) getSObjects(fields, whereClause, bindings);
    }

    /****************************************************************************************************************************
     Author              : Salesforce
     Description         : This method is used to get actove service territory members
     Created Date        : 18 Oct 2021
     *****************************************************************************************************************************/
    public List<ServiceTerritoryMember> getServiceTerritoryMembersForHosts(List<Id> buildngIds, List<Id> hostIds) {
        if (hostIds.isEmpty() || buildngIds.isEmpty()) {
            return new List<ServiceTerritoryMember>();
        }
        List<String> fields = new List<String> { 'Id', 'EffectiveStartDate', 'EffectiveEndDate', 'Has_Timeslots__c', 'ServiceResourceId', 'ServiceTerritoryId' };
        String whereClause = 'EffectiveEndDate = null AND ServiceResourceId IN: hostIds AND ServiceTerritoryId IN (SELECT Id FROM ServiceTerritory WHERE Building_Id__c IN :buildngIds)';
        List<Object> bindings = new List<Object> { hostIds, buildngIds };
        return (List<ServiceTerritoryMember>) getSObjects(fields, whereClause, bindings);
    }
}