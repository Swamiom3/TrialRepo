/************************************************************************************************************************************
    Author      :   Oleksandr Liesnik	
    Description :   This class contains test methods for ClusterUpdateInfoOnBuildingTrH
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION     DATE                AUTHOR                  DETAIL
    1           Feb 14, 2022        Oleksandr Liesnik       Initial version
**************************************************************************************************************************************/
@isTest
public with sharing class ClusterUpdateInfoOnBuildingTrHTest {

    @isTest
    static void testClusterTrigger() {
        Cluster__c cluster = new Cluster__c(Name = 'Test CLuster');
        insert cluster;
        System.assert(cluster.Id != null, 'Cluster was not inserted');
    }
    
    @isTest
    static void testGetClusterIds_test_positive() {
        User manager1 = getFakeUser(1);
        User lead1 = getFakeUser(2);
        List<Cluster__c> oldClusters = new List<Cluster__c>{getFakeCluster(1, manager1.Id, lead1.Id), getFakeCluster(2, manager1.Id, lead1.Id)};
        List<Cluster__c> newClusters = oldClusters.deepClone(true);
        newClusters[0].Name = 'New Name';
        newClusters[1].Cluster_Sales_Manager__c = TestUtility.getFakeId(User.SObjectType);
        ClusterUpdateInfoOnBuildingTrH clusterTrH = new ClusterUpdateInfoOnBuildingTrH(newClusters, new Map<Id, Cluster__c>(oldClusters));
        Test.startTest();
        Set<Id> clusterIds = clusterTrH.getClusterIds();
        Test.stopTest();
        System.assertNotEquals(null, clusterIds, 'Result Ids list must not be null');
        System.assertEquals(2, clusterIds.size(), 'The number of Cluster Ids should be 2');
    }

    @isTest
    static void testGetClusterIds_test_negative() {
        User manager1 = getFakeUser(1);
        User lead1 = getFakeUser(2);
        List<Cluster__c> oldClusters = new List<Cluster__c>{getFakeCluster(1, manager1.Id, lead1.Id)};
        List<Cluster__c> newClusters = oldClusters.deepClone(true);
        ClusterUpdateInfoOnBuildingTrH clusterTrH = new ClusterUpdateInfoOnBuildingTrH(newClusters, new Map<Id, Cluster__c>(oldClusters));
        Test.startTest();
        Set<Id> clusterIds = clusterTrH.getClusterIds();
        Test.stopTest();
        System.assert(clusterIds.isEmpty(), 'Result Ids list must be empty');
    }

    @isTest
    static void testGetBuildingsToUpdate_test_positive() {
        User manager1 = getFakeUser(1);
        User lead1 = getFakeUser(2);
        User manager2 = getFakeUser(3);
        User lead2 = getFakeUser(4);
        Cluster__c cluster = getFakeCluster(1, manager1.Id, lead1.Id);
        List<Building__c> buildings = getFakeBuildings(2, cluster);   
        List<Cluster__c> oldClusters = new List<Cluster__c>{cluster};
        List<Cluster__c> newClusters = oldClusters.deepClone(true);
        newClusters[0].Name = 'New CLuster Name';
        newClusters[0].Sales_Lead__c = lead2.Id;
        newClusters[0].Cluster_Sales_Manager__c = manager2.Id;
        List<Building__c> relatedBuildings = getFakeBuildingsFromJson( getJsonStringForBuildingsWithClusters(buildings, newClusters[0], manager2, lead2));
        ClusterUpdateInfoOnBuildingTrH clusterTrH = new ClusterUpdateInfoOnBuildingTrH(newClusters, new Map<Id, Cluster__c>(oldClusters));
        clusterTrH.buildingSelector = (BuildingSelector) MockService.createMock(
                                                         BuildingSelector.class,
                                                         new Map<String, Object>{
                                                         'getBuildingsByCluster' => relatedBuildings});
        Test.startTest();
        List<Building__c> buildingsToUpdate = clusterTrH.getBuildingsToUpdate();
        Test.stopTest();
        System.assertEquals(2, buildingsToUpdate.size(), 'The number of Buildings to Update should be 2');
        System.assertEquals(newClusters[0].Name, buildingsToUpdate[0].Cluster_Name__c, 'Cluster Name was not updated on related Building');
        System.assertEquals(newClusters[0].Name, buildingsToUpdate[1].Cluster_Name__c, 'Cluster Name was not updated on related Building');
        System.assertEquals(lead2.LastName, buildingsToUpdate[0].Cluster_Sales_Lead_Name__c, 'Cluster Sales Lead Name was not updated on related Building');
        System.assertEquals(lead2.LastName, buildingsToUpdate[0].Cluster_Sales_Lead_Name__c, 'Cluster Sales Lead Name was not updated on related Building');
        System.assertEquals(manager2.LastName, buildingsToUpdate[0].Cluster_Sales_Manager_Name__c,  'Cluster Sales Manager Name was not updated on related Building');
        System.assertEquals(manager2.LastName, buildingsToUpdate[0].Cluster_Sales_Manager_Name__c,  'Cluster Sales Manager Name was not updated on related Building');
    }

    @isTest
    static void testGetBuildingsToUpdate_test_negative() {
        User lead = getFakeUser(1);
        User manager = getFakeUser(2);
        Cluster__c cluster = getFakeCluster(1, manager.Id, lead.Id);
        List<Building__c> buildings = getFakeBuildings(2, cluster);   
        List<Cluster__c> oldClusters = new List<Cluster__c>{cluster};
        List<Building__c> relatedBuildings = getFakeBuildingsFromJson(getJsonStringForBuildingsWithClusters(buildings, oldClusters[0], manager, lead));
        ClusterUpdateInfoOnBuildingTrH clusterTrH = new ClusterUpdateInfoOnBuildingTrH(oldClusters, new Map<Id, Cluster__c>(oldClusters));
        clusterTrH.buildingSelector = (BuildingSelector) MockService.createMock(
                                                         BuildingSelector.class,
                                                         new Map<String, Object>{
                                                         'getBuildingsByCluster' => relatedBuildings});
        Test.startTest();
        List<Building__c> buildingsToUpdate = clusterTrH.getBuildingsToUpdate();
        Test.stopTest();
        System.assert(buildingsToUpdate.isEmpty(), 'Result Buildings list must be empty');
    }
 
    static List<Building__c> getFakeBuildingsFromJson(String fakeBuildings) {
        return (List<Building__c>) JSON.deserialize(fakeBuildings, List<Building__c>.class);
    }

    static String getJsonStringForBuildingsWithClusters(List<Building__c> buildings, Cluster__c cluster, User manager, User lead) {
        String toDeserialize = '[';
        for (Building__c build : buildings) {
            toDeserialize += JSON.serialize(build).removeEnd('}') + ',' + '"Cluster__r": ' +
                             JSON.serialize(cluster).removeEnd('}') + ',' + '"Cluster_Sales_Manager__r": ' +
                             JSON.serialize(manager).removeEnd('}') + ',' + '"Name": "' + manager.LastName + '"}' + ',' + '"Sales_Lead__r": ' +
                             JSON.serialize(lead).removeEnd('}') + ',' + '"Name": "' + lead.LastName + '"}}},';
        }
        return toDeserialize.removeEnd(',') + ']';
    }

    static List<Building__c> getFakeBuildings(Integer numOfBuildings, Cluster__c cluster) {
        List<Building__c> buildings = new List<Building__c>();
        for (Integer i = 0; i < numOfBuildings; i++) {
            buildings.add(new Building__c( Id = TestUtility.getFakeId(Building__c.SObjectType),
                                           Name = 'Test Building' + i,
                                           Cluster__c = cluster.Id, 
                                           Cluster_Name__c = cluster.Name));
        }
        return buildings;
    }

    static Cluster__c getFakeCluster(Integer clusterIndex, Id managerId, Id leadId){
        return new Cluster__c(  Id = TestUtility.getFakeId(Cluster__c.SObjectType),
                                Name = 'Test Cluster' + clusterIndex, 
                                Cluster_Sales_Manager__c = managerId, 
                                Sales_Lead__c = leadId);
    }

    static User getFakeUser(Integer userIndex) {
        return new User(Id = TestUtility.getFakeId(User.SObjectType),
                        LastName = 'Test User' + userIndex,
                        Email = 'test.user' + userIndex + '@wework.com');
    }
}