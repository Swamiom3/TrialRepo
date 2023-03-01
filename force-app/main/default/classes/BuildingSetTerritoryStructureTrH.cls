/*********************************************************************************************************
    Author        :  Krishna Somwanshi
    Description   :  This class has business logic to Set Territory Structure.
    Issue No.     :  ST-8736
    History       :
-----------------------------------------------------------------------------------------------------------
    VERSION        DATE            AUTHOR             DETAIL
    1          24-Aug-2021      Krishna Somwanshi     Refactor
**********************************************************************************************************/
public with sharing class BuildingSetTerritoryStructureTrH extends SObjectTriggerHandler {
    @TestVisible
    private List<Building__c> newBuildings;
    @TestVisible
    private Map<Id, Building__c> oldBuildingsMap;
    @TestVisible
    private PortfolioSelector portfolioSelector = new PortfolioSelector();
    @TestVisible
    private ClusterSelector clusterSelector = new ClusterSelector();
    
    public BuildingSetTerritoryStructureTrH() {
        this(
            (List<Building__c>) Trigger.new,
            (Map<Id, Building__c>) Trigger.oldMap
        );
    }
    
    @TestVisible
    private BuildingSetTerritoryStructureTrH(List<Building__c> newBuildings, Map<Id, Building__c> oldBuildingsMap) {
        this.newBuildings = newBuildings;
        this.oldBuildingsMap = oldBuildingsMap;
    }
    
    public override void beforeInsert() {
        setTerritoryStructure();
    }
    
    public override void beforeUpdate() {
        setTerritoryStructure();
    }
    
    @TestVisible
    private void setTerritoryStructure(){
        assignTerritoriesStructure();
        setSubTerritory();
        setCommunityLeadManagerName();
    }
    
    @TestVisible
    private void assignTerritoriesStructure() {
        List<Building__c> buildingsToSetStructure = new List<Building__c>();
        Set<Id> clusterIds = new Set<Id>();
        Set<Id> portfolioIds = new Set<Id>();
        Boolean isBuildingToUpdate = false;
        for(Building__c building : newBuildings) {
            isBuildingToUpdate = false;
            Building__c oldBuilding = oldBuildingsMap?.get(building.Id);
            if((oldBuilding == null && building.Cluster__c != null) || (oldBuilding != null && TriggerUtility.isFieldValueChanged(building, oldBuilding, 'Cluster__c'))) {
                clusterIds.add(building.Cluster__c);
                isBuildingToUpdate = true;
            }
            if((oldBuilding == null && building.Market__c != null) || (oldBuilding != null && TriggerUtility.isFieldValueChanged(building, oldBuilding, 'Market__c'))) {
                portfolioIds.add(building.Market__c);
                isBuildingToUpdate = true;
            }
            if(isBuildingToUpdate == true) {
                buildingsToSetStructure.add(building);
            }
        }
        setClusterStructure(buildingsToSetStructure, clusterIds);
        setPortfolioStructure(buildingsToSetStructure, portfolioIds);
    }
    
    @TestVisible
    private void setClusterStructure(List<Building__c> buildingsToSetStructure, Set<Id> clusterIds) {
        if(clusterIds.isEmpty()) {
            return;
        }
        Map<Id, Cluster__c> clusterData = new Map<Id, Cluster__c>();
        clusterData.putAll(clusterSelector.getClustersById(new List<Id>(clusterIds)));
        for(Building__c building : buildingsToSetStructure) {
            building.Cluster_Name__c = clusterData?.get(building.Cluster__c)?.Name;
            building.Cluster_Sales_Manager_Name__c = clusterData?.get(building.Cluster__c)?.Cluster_Sales_Manager__r?.Full_Name__c;
            building.Cluster_Sales_Lead_Name__c = clusterData?.get(building.Cluster__c)?.Sales_Lead__r?.Full_Name__c;
            building.Cluster_Sales_Manager_Email__c = clusterData?.get(building.Cluster__c)?.Cluster_Sales_Manager__r?.Email;
            building.Cluster_Sales_Lead_Email__c = clusterData?.get(building.Cluster__c)?.Sales_Lead__r?.Email;
        }
    }
    
    @TestVisible
    private void setPortfolioStructure(List<Building__c> buildingsToSetStructure, Set<Id> portfolioIds) {
        if(portfolioIds.isEmpty()) {
            return;
        }
        Map<Id, Market__c> portfolioData = new Map<Id, Market__c>();
        portfolioData.putAll(portfolioSelector.getPortfoliosById(new List<Id>(portfolioIds)));
        for(Building__c building : buildingsToSetStructure) {
            building.Portfolio_Name__c = portfolioData?.get(building.Market__c)?.Name;
            building.Territory_Name__c = portfolioData?.get(building.Market__c)?.TerritoryID__r?.Territory__c;
            building.Region_Name__c = portfolioData?.get(building.Market__c)?.TerritoryID__r?.RegionID__r?.Region__c;
            building.Portfolio_Sales_Manager_Name__c = portfolioData?.get(building.Market__c)?.Portfolio_Sales_Manager__r?.Full_Name__c;
            building.Territory_Sales_Manager_Name__c = portfolioData?.get(building.Market__c)?.TerritoryID__r?.Territory_Sales_Manager__r?.Full_Name__c;
            building.Regional_Sales_Manager_Name__c = portfolioData?.get(building.Market__c)?.TerritoryID__r?.RegionID__r?.Regional_Sales_Manager__r?.Full_Name__c;
            building.Portfolio_Sales_Manager_Email__c = portfolioData?.get(building.Market__c)?.Portfolio_Sales_Manager__r?.Email;
            building.Territory_Sales_Manager_Email__c = portfolioData?.get(building.Market__c)?.TerritoryID__r?.Territory_Sales_Manager__r?.Email;
            building.Regional_Sales_Manager_Email__c = portfolioData?.get(building.Market__c)?.TerritoryID__r?.RegionID__r?.Regional_Sales_Manager__r?.Email;
        }
    }
    
    @TestVisible
    private void setCommunityLeadManagerName() {
        for(Building__c building : newBuildings) {
            Building__c oldBuilding = oldBuildingsMap?.get(building.Id);
            if((building?.Community_Lead__c != null && oldBuilding == null)
              ||(oldBuilding != null && TriggerUtility.isFieldValueChanged(building, oldBuilding, 'Community_Lead__c'))) {
                User user = UserUtility.getUserById(building.Community_Lead__c);
                building.Community_Lead_Name__c = user?.Name;
            }
            if((building?.Responsible_CM__c != null && oldBuilding == null)
              ||(oldBuilding != null && TriggerUtility.isFieldValueChanged(building, oldBuilding, 'Responsible_CM__c'))) {
                User user = UserUtility.getUserById(building.Responsible_CM__c);
                building.Community_Manager_Name__c = user?.Name;
            }
        }
    }
    
    @TestVisible
    private void setSubTerritory() {
        Set<Id> portfolioIds = new Set<Id>();
        for(Building__c building : newBuildings) {
            Building__c oldBuilding = oldBuildingsMap?.get(building.Id);
            if(building.Market__c != null && (oldBuilding == null || TriggerUtility.isFieldValueChanged(building, oldBuilding, 'Market__c'))) {
                portfolioIds.add(building.Market__c);
            }
        }
        if(portfolioIds.isEmpty()) {
            return;
        }
        Map<Id, Market__c> portfolios = new Map<Id, Market__c>(portfolioSelector.getPortfoliosById(new List<Id>(portfolioIds)));
        for(Building__c building : newBuildings) {
            building.Sub_Territory__c = portfolios?.get(building.Market__c)?.Sub_Territory__c;
        }
    }
}