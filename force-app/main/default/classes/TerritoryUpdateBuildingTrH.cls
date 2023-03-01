/*********************************************************************************************************
	Author        :  Shobhit Gahlot
	Description   :  Updates territory info on buildiing
	Issue No.     :  ST-8870
	History       :
-----------------------------------------------------------------------------------------------------------
	VERSION        DATE            AUTHOR             DETAIL
	1          24-Aug-2021      Shobhit Gahlot        Refactor
**********************************************************************************************************/
public with sharing class TerritoryUpdateBuildingTrH extends SObjectTriggerHandler{
    @TestVisible
    private List<Territory__c> newTerritories;
    @TestVisible
    private Map<Id, Territory__c> oldTerritoriesMap;
    @TestVisible
    private BuildingSelector buildingSelector = new BuildingSelector();
    @TestVisible
    List<Building__c> buildingsToUpdate = new List<Building__c>();
    
    public TerritoryUpdateBuildingTrH() {
        this(
            (List<Territory__c>) Trigger.new,
            (Map<Id, Territory__c>) Trigger.oldMap
        );
    }
    
    @TestVisible
    private TerritoryUpdateBuildingTrH(List<Territory__c> newTerritories, Map<Id, Territory__c> oldTerritoriesMap) {
        this.newTerritories = newTerritories;
        this.oldTerritoriesMap = oldTerritoriesMap;
    }
    
    public override void afterUpdate() {
        updateTerritoryInfoOnBuilding();
    }
    
    private void updateTerritoryInfoOnBuilding(){
        Set<Id> territories = new Set<Id>();
        for(Territory__c territory : newTerritories) {
            Territory__c oldTerritory = oldTerritoriesMap.get(territory.Id);
            if(territory.Territory__c == null
                   || TriggerUtility.isFieldsValueChanged(territory, oldTerritory, new Set<String>{'Territory__c',
                                                                                                   'Territory_Sales_Manager__c', 
                                                                                                   'RegionID__c'})) {
                territories.add(territory.Id);
            }
        }
        if(territories.isEmpty()) {
            return;
        }
        
        for(Building__c building : buildingSelector.getBuildingsByTerritories(new List<Id>(territories))) {
            building.Territory_Name__c = building.Market__r?.TerritoryId__r?.Territory__c;
            building.Territory_Sales_Manager_Name__c = building.Market__r?.TerritoryId__r?.Territory_Sales_Manager__r?.Name;
            building.Region_Name__c = building.Market__r?.TerritoryId__r?.RegionId__r?.Region__c;
            building.Regional_Sales_Manager_Name__c = building.Market__r?.TerritoryId__r?.RegionId__r?.Regional_Sales_Manager__r?.Name;
            building.Territory_Sales_Manager_Email__c = building.Market__r?.TerritoryId__r?.Territory_Sales_Manager__r?.Email;
            building.Regional_Sales_Manager_Email__c = building.Market__r?.TerritoryId__r?.RegionId__r?.Regional_Sales_Manager__r?.Email;
            buildingsToUpdate.add(building);
        }
        try {
            dml.add(buildingsToUpdate, DmlConsolidator.Operation.FOR_UPDATE);
        } catch(DmlException ex) {
            ApexDebugLog.logException(ex, JSON.serialize(buildingsToUpdate), 'TerritoryUpdateBuildingTrH', 'updateTerritoryInfoOnBuilding');
        }
    }
}