/*************************************************************************************************************************************
 Author      :   Salesforce
 Description :   This class is selector implementation of particular SObject (ServiceTerritory)
 --------------------------------------------------------------------------------------------------------------------------------------
 VERSION         DATE            AUTHOR              DETAIL
 1               18 Oct 2021     Salesforce       Initial Deployment
 **************************************************************************************************************************************/
public with sharing class ServiceTerritorySelector extends SObjectSelector {
    public ServiceTerritorySelector() {
        super(ServiceTerritory.getSObjectType());
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
     Description         : This method is used to get service territory based on Id
     Created Date        : 18 Oct 2021
     *****************************************************************************************************************************/
    public List<ServiceTerritory> getServiceTerritoryByIds(List<Id> serviceTerritoryIds){
        if(serviceTerritoryIds.isEmpty()) {
            return new List<ServiceTerritory>();
        }
        List<String> fields = new List<String> { 'Id', 'Building_Id__c' };
        String whereClause = 'Id IN :serviceTerritoryIds';
        List<Object> bindings = new List<Object> { serviceTerritoryIds };
        return (List<ServiceTerritory>) getSObjects(fields, whereClause, bindings);
    }

    public List<ServiceTerritory> getServiceTerritoriesByBuilding(Id buildingId) {
        if (String.isBlank(buildingId)) {
            return new List<ServiceTerritory>();
        }
        String whereClause = 'Building_Id__c = :buildingId AND IsActive = true';
        List<Object> bindings = new List<Object> { buildingId };
        return (List<ServiceTerritory>) getSObjects(new List<String>(getDefaultFields()), whereClause, bindings);
    }
    /****************************************************************************************************************************
     Author              : Stepan Vardzal
     Description         : This method is used to get only active service territory based on Building UUID
     Created Date        : 13 Jan 2022
     *****************************************************************************************************************************/
    public List<ServiceTerritory> getActiveServiceTerritoryByBuildingUUID(List<String> buildingUUIDs){
        if(buildingUUIDs.isEmpty()) {
            return new List<ServiceTerritory>();
        }
        List<String> fields = new List<String> { 'Id' };
        String whereClause = 'Building_Id__r.UUID__c IN :buildingUUIDs AND IsActive = TRUE';
        List<Object> bindings = new List<Object> { buildingUUIDs };
        return (List<ServiceTerritory>) getSObjects(fields, whereClause, bindings);
    }
}