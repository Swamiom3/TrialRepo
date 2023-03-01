/*********************************************************************************************************
    Author        :  Krishna Somwanshi
    Description   :  This class makes Dev Batch Update Field to true based on Building field values.
    Issue No.     :  ST-8736
    History       :
-----------------------------------------------------------------------------------------------------------
    VERSION        DATE            AUTHOR             DETAIL
    1          24-Aug-2021      Krishna Somwanshi     Refactor
**********************************************************************************************************/
public with sharing class BuildingSetDevBatchUpdateTrH extends SObjectTriggerHandler {
    @TestVisible
    private List<Building__c> newBuildings;
    @TestVisible
    private Map<Id, Building__c> oldBuildingsMap;
    
    public BuildingSetDevBatchUpdateTrH() {
        this(
            (List<Building__c>) Trigger.new,
            (Map<Id, Building__c>) Trigger.oldMap
        );
    }
    
    @TestVisible
    private BuildingSetDevBatchUpdateTrH(List<Building__c> newBuildings, Map<Id, Building__c> oldBuildingsMap) {
        this.newBuildings = newBuildings;
        this.oldBuildingsMap = oldBuildingsMap;
    }
    
    public override void beforeInsert() {
        insertSetDevBatchUpdateOnBuilding();
    }

    public override void beforeUpdate() {
        updateSetDevBatchUpdateOnBuilding();
    }

    private void insertSetDevBatchUpdateOnBuilding() {
        for(Building__c building : newBuildings) {
            if(building.Sub_Territory__c != null
               || building.Market__c != null
               || building.Associate_Director_Market_Sales__c != null
               || building.Associate_Director_Portfolio_Sales__c != null
               || building.Senior_Associate_Market_Sales__c != null
               || building.Senior_Director_Territory_Sales__c != null
               || building.Director_Portfolio_Sales__c != null
               || building.Inside_Sales_Rep__c != null
               || building.Inside_Sales_Renewals_Rep__c != null ) {
                   building.Dev_Batch_Update__c = true;
            }
        }
    }
    
    private void updateSetDevBatchUpdateOnBuilding() {
        for(Building__c building : newBuildings) {
            Building__c oldBuilding = oldBuildingsMap?.get(building.Id);
            if(TriggerUtility.isFieldsValueChanged(building, oldBuilding, new Set<String>{'Sub_Territory__c',
                                                                                          'Market__c',
                                                                                          'Associate_Director_Market_Sales__c',
                                                                                          'Associate_Director_Portfolio_Sales__c',
                                                                                          'Senior_Associate_Market_Sales__c',
                                                                                          'Senior_Director_Territory_Sales__c',
                                                                                          'Director_Portfolio_Sales__c',
                                                                                          'Inside_Sales_Rep__c',
                                                                                          'Inside_Sales_Renewals_Rep__c'})) {
                building.Dev_Batch_Update__c = true;
            }
        }
    }
}