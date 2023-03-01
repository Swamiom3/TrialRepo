/*************************************************************************************************************************************
 Author      :   Salesforce
 Description :   This class is selector implementation of particular SObject (Non_Operating_Hours__c)
 --------------------------------------------------------------------------------------------------------------------------------------
 VERSION         DATE            AUTHOR              DETAIL
 1               18 Oct 2021     Salesforce       Initial Deployment
 **************************************************************************************************************************************/
public with sharing class NonOperatingHoursSelector extends SObjectSelector {
    public NonOperatingHoursSelector() {
        super(Non_Operating_Hours__c.getSObjectType());
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
     Description         : This method is used to get Non-Operating Hours based on building ids
     Created Date        : 18 Oct 2021
     *****************************************************************************************************************************/
    public List<Non_Operating_Hours__c> getNonOperatingHoursByBuildingIds(List<Id> buildingIds, String closureType){
        if(buildingIds.isEmpty() || String.isBlank(closureType)) {
            return new List<Non_Operating_Hours__c>();
        }
        List<String> fields = new List<String> { 'Id', 'End_Time__c', 'Start_Time__c', 'Closure_Type__c', 'Building_Id__c' };
        String whereClause = 'Building_Id__c IN :buildingIds AND Closure_Type__c = :closureType';
        List<Object> bindings = new List<Object> { buildingIds, closureType };
        return (List<Non_Operating_Hours__c>) getSObjects(fields, whereClause, bindings);
    }

    /****************************************************************************************************************************
     Author              : Salesforce
     Description         : This method is used to get Non-Operating Hours based on service territory ids
     Created Date        : 18 Oct 2021
     *****************************************************************************************************************************/
    public List<Non_Operating_Hours__c> getNonOperatingHoursByServiceTerritoryIds(List<Id> serviceTerritoryIds){
        if(serviceTerritoryIds.isEmpty()) {
            return new List<Non_Operating_Hours__c>();
        }
        List<String> fields = new List<String> (getDefaultFields());
        String whereClause = 'Building_Id__c IN (SELECT Building_Id__c FROM ServiceTerritory WHERE Id IN :serviceTerritoryIds)';
        List<Object> bindings = new List<Object> { serviceTerritoryIds };
        return (List<Non_Operating_Hours__c>) getSObjects(fields, whereClause, bindings);
    }

    /****************************************************************************************************************************
     Author              : Stepan Vardzal
     Description         : This method is used to get Non-Operating Hours based on Building Id
     Created Date        : 14 Jan 2022
     *****************************************************************************************************************************/
    public List<Non_Operating_Hours__c> getNonOperatingHoursByBuildingIdsAndPeriod(List<Id> buildingIds, String closureType, DateTime startTime, DateTime endTime) {
        if (buildingIds.isEmpty() || String.isBlank(closureType)) {
            return new List<Non_Operating_Hours__c>();
        }
        List<String> fields = new List<String> { 'Start_Time__c', 'End_Time__c' };
        String whereClause = 'Building_Id__c IN :buildingIds AND Closure_Type__c =: closureType AND End_Time__c > :startTime AND  Start_Time__c < :endTime';
        List<Object> bindings = new List<Object> { buildingIds, closureType,  startTime, endTime };
        return (List<Non_Operating_Hours__c>) getSObjects(fields, whereClause, bindings);
    }
}