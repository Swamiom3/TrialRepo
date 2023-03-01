/*********************************************************************************************************
    Author        :  Ashish Sharma
    Description   :  Updates region info on buildiing
    Issue No.     :  ST-8737
    History       :
-----------------------------------------------------------------------------------------------------------
    VERSION        DATE            AUTHOR             DETAIL
    1          10-Aug-2021      Ashish Sharma        Refactor
**********************************************************************************************************/
public with sharing class RegionUpdateBuildingTrH extends SObjectTriggerHandler {
    @TestVisible
    private List<Region__c> newRegions;
    @TestVisible
    private Map<Id, Region__c> oldRegionsMap;
    @TestVisible
    private BuildingSelector buildingSelector = new BuildingSelector();
    @TestVisible
    List<Building__c> buildingsToUpdate = new List<Building__c>();
    
    public RegionUpdateBuildingTrH() {
        this(
            (List<Region__c>) Trigger.new,
            (Map<Id, Region__c>) Trigger.oldMap
        );
    }
    
    @TestVisible
    private RegionUpdateBuildingTrH(List<Region__c> newRegions, Map<Id, Region__c> oldRegionsMap) {
        this.newRegions = newRegions;
        this.oldRegionsMap = oldRegionsMap;
    }
    
    public override void afterUpdate() {
        updateRegionInfoOnBuilding();
    }
    
    private void updateRegionInfoOnBuilding() {
        Set<Id> regions = new Set<Id>();
        for(Region__c region : newRegions) {
            Region__c oldRegion = oldRegionsMap?.get(region.Id);
            if(region.Region__c == null 
                   || TriggerUtility.isFieldsValueChanged(region, oldRegion, new Set<String>{'Region__c', 'Regional_Sales_Manager__c'})) {
                regions.add(region.Id);
            }
        }
        if(regions.isEmpty()) {
            return;
        }

        for(Building__c building : buildingSelector.getBuildingsByRegions(new List<Id>(regions))) {
            Building__c buildingToUpdate = new Building__c(
                Id = building.Id,
                Region_Name__c = building.Market__r?.TerritoryId__r?.RegionId__r?.Region__c,
                Regional_Sales_Manager_Name__c = building.Market__r?.TerritoryId__r?.RegionId__r?.Regional_Sales_Manager__r?.Name,
                Regional_Sales_Manager_Email__c = building.Market__r?.TerritoryId__r?.RegionId__r?.Regional_Sales_Manager__r?.Email
            );
            buildingsToUpdate.add(buildingToUpdate);
        }
        try {
            update buildingsToUpdate;
        } catch(DmlException ex) {
            ApexDebugLog.logException(ex, JSON.serialize(buildingsToUpdate), 'RegionUpdateBuildingInfoTrH', 'updateRegionInfoOnBuilding');
        }
    }
}