/************************************************************************************************************************************
    Author      :   Oleksandr Liesnik	
    Description :   Trigger handler class for updating cluster information on building after cluster update.
                    Created during trigger redesign (ST-10541)
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION     DATE                AUTHOR                  DETAIL
    1           Feb 14, 2022        Oleksandr Liesnik       Initial version
**************************************************************************************************************************************/
public with sharing class ClusterUpdateInfoOnBuildingTrH extends SObjectTriggerHandler{

    @TestVisible
    private List<Cluster__c> newClusters;
    @TestVisible
    private Map<Id, Cluster__c> oldClustersMap;
    @TestVisible
    private BuildingSelector buildingSelector = new BuildingSelector();

    public ClusterUpdateInfoOnBuildingTrH() {
        this((List<Cluster__c>) Trigger.new, (Map<Id, Cluster__c>) Trigger.oldMap);
    }

    @TestVisible
    private ClusterUpdateInfoOnBuildingTrH(List<Cluster__c> newClusters,  Map<Id, Cluster__c> oldClustersMap) {
        this.newClusters = newClusters;
        this.oldClustersMap = oldClustersMap;
    }

    public override void afterUpdate() {
        updateClusterInfoOnBuilding();
    }

    private void updateClusterInfoOnBuilding() {
        List<Building__c> buildingsToUpdate = getBuildingsToUpdate();
        if (buildingsToUpdate != null && !buildingsToUpdate.isEmpty()) {
            dml.add(buildingsToUpdate, DmlConsolidator.Operation.FOR_UPDATE);
        }
    }

    @TestVisible
    private List<Building__c> getBuildingsToUpdate() {
        Set<Id> clusterIds = getClusterIds();
        List<Building__c> relatedBuildings = getRelatedBuildings(clusterIds);
        List<Building__c> buildingsToUpdate = new List<Building__c>();
        for (Building__c building : relatedBuildings) {
            Building__c buildToUpdate = new Building__c(Id = building.Id);
            if (building.Cluster__c != null && clusterIds.contains(building.Cluster__c)) {
                buildToUpdate.Cluster_Name__c = building.Cluster__r.Name;
                buildToUpdate.Cluster_Sales_Lead_Name__c = building.Cluster__r.Sales_Lead__r?.Name;
                buildToUpdate.Cluster_Sales_Lead_Email__c = building.Cluster__r.Sales_Lead__r?.Email;
                buildToUpdate.Cluster_Sales_Manager_Name__c = building.Cluster__r.Cluster_Sales_Manager__r?.Name;
                buildToUpdate.Cluster_Sales_Manager_Email__c = building.Cluster__r.Cluster_Sales_Manager__r?.Email;
                buildingsToUpdate.add(buildToUpdate);
            }
        }
        return buildingsToUpdate;
    }

    private List<Building__c> getRelatedBuildings(Set<Id> clusterIds) {
        return buildingSelector.getBuildingsByCluster(new List<Id>(clusterIds));
    }

    @TestVisible
    private Set<Id> getClusterIds() {
        Set<Id> clusterIds = new Set<Id>();
        Set<String> fieldAPINames = new Set<String>{'Name','Cluster_Sales_Manager__c', 'Sales_Lead__c'};
        for (Cluster__c newCluster : newClusters) {
            Cluster__c oldCluster = oldClustersMap.get(newCluster.Id);
            if (TriggerUtility.isFieldsValueChanged(newCluster, oldCluster, fieldAPINames)) {
                clusterIds.add(newCluster.Id);
            }
        }
        return clusterIds;
    }
}