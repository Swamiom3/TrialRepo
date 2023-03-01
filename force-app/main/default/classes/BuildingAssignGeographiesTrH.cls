/*********************************************************************************************************
    Author        :  Krishna Somwanshi
    Description   :  This class has business logic to manage Building Related Geographies.
    Issue No.     :  ST-8736
    History       :
-----------------------------------------------------------------------------------------------------------
    VERSION        DATE            AUTHOR             DETAIL
    1          24-Aug-2021      Krishna Somwanshi     Refactor
    2          20-jan-2022      Krishna Somwanshi     Added Update context
**********************************************************************************************************/
public with sharing class BuildingAssignGeographiesTrH extends SObjectTriggerHandler {
    @TestVisible
    private List<Building__c> newBuildings;
    @TestVisible
    private Map<Id, Building__c> oldBuildingsMap;
    @TestVisible
    private List<Building__c> newBuildingsToUpdate = new List<Building__c>();
    
    public BuildingAssignGeographiesTrH() {
        this(
            (List<Building__c>) Trigger.new,
            (Map<Id, Building__c>) Trigger.oldMap
        );
    }
    
    @TestVisible
    private BuildingAssignGeographiesTrH(List<Building__c> newBuildings, Map<Id, Building__c> oldBuildingsMap) {
        this.newBuildings = newBuildings;
        this.oldBuildingsMap = oldBuildingsMap;
    }
    
    @TestVisible
    public override void afterInsert() {
        insertGeographiesOnBuilding();
    }
    
    @TestVisible
    public override void afterUpdate() {
        updateGeographiesOnBuilding();
    }

    @TestVisible
    private void insertGeographiesOnBuilding() {
        new AsyncsExecutor(QueueInsertGeographyForBuilding.class, new Map<String, Object>{'buildings' => newBuildings}).execute();
    }
    
    private void updateGeographiesOnBuilding(){
        for(Building__c building : newBuildings) {
            Building__c oldBuilding = oldBuildingsMap?.get(building.Id);
            if(oldBuilding.Id != null && TriggerUtility.isFieldsValueChanged(building, oldBuilding, new Set<String>{'Address__c',
                                                                                                                    'City__c',
                                                                                                                    'State__c',
                                                                                                                    'Country__c',
                                                                                                                    'Postal_Code__c'})) {
                newBuildingsToUpdate.add(building);
            }
        }
        if(newBuildingsToUpdate.isEmpty()){
            return;
        }
        new AsyncsExecutor(QueueInsertGeographyForBuilding.class, new Map<String, Object>{'buildings' => newBuildingsToUpdate}).execute();
    }
}