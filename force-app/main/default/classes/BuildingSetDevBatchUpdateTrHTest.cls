/*********************************************************************************************************
    Author        :  Krishna Somwanshi
    Description   :  Test class for BuildingOpportunityUserMapTrh
    Issue No.     :  ST-8736
    History       :
-----------------------------------------------------------------------------------------------------------
    VERSION        DATE            AUTHOR             DETAIL
    1          24-Aug-2021      Krishna Somwanshi     Refactor
**********************************************************************************************************/
@isTest
public class BuildingSetDevBatchUpdateTrHTest {

    @isTest
    private static void insertOpportunityUserMap() {
        User assignedUser = [SELECT Id, Name, Full_Name__c, Email FROM User LIMIT 1];
        List<Cluster__c> testClusters = getInsertedClusters();
        List<Market__c> testPortfolios = getInsertedPortfolios();
        List<Building__c> testBuildings = getInsertedBuildings();
        List<Building__c> mockedBuildings = new List<Building__c>{
            new Building__c(Id = testBuildings[0].Id, Name = 'Mocked Building 1', Sub_Territory__c = testClusters[0].Id),
            new Building__c(Id = testBuildings[1].Id, Name = 'Mocked Building 2', Sub_Territory__c = testClusters[0].Id, Market__c = testPortfolios[0].Id),
            new Building__c(Id = testBuildings[2].Id),
            new Building__c(Id = testBuildings[3].Id)
        };
       
        Test.startTest();
        BuildingSetDevBatchUpdateTrH setDevBatchUpdate = new BuildingSetDevBatchUpdateTrH();
        setDevBatchUpdate.newBuildings = mockedBuildings;
        setDevBatchUpdate.beforeInsert();
        Test.stopTest();
        System.assertEquals(mockedBuildings[0].Dev_Batch_Update__c, true, 'Dev Batch Update field should be true');//Positive case
        System.assertEquals(mockedBuildings[1].Dev_Batch_Update__c, true, 'Dev Batch Update field should be true');//Positive case
        System.assertEquals(mockedBuildings[2].Dev_Batch_Update__c, false, 'Dev Batch Update field should be false');//Negative case
        System.assertEquals(mockedBuildings[3].Dev_Batch_Update__c, false, 'Dev Batch Update field should be false');//Negative case
    }
    
    @isTest
    private static void updateOpportunityUserMap() {
        User assignedUser = [SELECT Id, Name, Full_Name__c, Email FROM User LIMIT 1];
        List<Cluster__c> testClusters = getInsertedClusters();
        List<Market__c> testPortfolios = getInsertedPortfolios();
        List<Building__c> testBuildings = getInsertedBuildings();
       
        List<Building__c> mockedBuildings = new List<Building__c>{
            new Building__c(Id = testBuildings[0].Id, Name = 'Mocked Building 1', Sub_Territory__c = testClusters[1].Id, Market__c = testPortfolios[1].Id),
            new Building__c(Id = testBuildings[1].Id, Name = 'Mocked Building 2', Sub_Territory__c = testClusters[1].Id, Market__c = testPortfolios[1].Id, Associate_Director_Market_Sales__c = assignedUser.Id,
                            Associate_Director_Portfolio_Sales__c = assignedUser.Id, Senior_Associate_Market_Sales__c = assignedUser.Id, Senior_Director_Territory_Sales__c = assignedUser.Id,
                            Director_Portfolio_Sales__c = assignedUser.Id, Inside_Sales_Rep__c = assignedUser.Id, Inside_Sales_Renewals_Rep__c = assignedUser.Id),
            new Building__c(Id = testBuildings[2].Id),
            new Building__c(Id = testBuildings[3].Id)
        };
       
        Test.startTest();
        BuildingSetDevBatchUpdateTrH setDevBatchUpdate = new BuildingSetDevBatchUpdateTrH();
        setDevBatchUpdate.oldBuildingsMap = new Map<Id, Building__c>(testBuildings);
        setDevBatchUpdate.newBuildings = mockedBuildings;
        setDevBatchUpdate.beforeUpdate();
        Test.stopTest();
        System.assertEquals(mockedBuildings[0].Dev_Batch_Update__c, true, 'Dev Batch Update field should be true');//Positive case
        System.assertEquals(mockedBuildings[1].Dev_Batch_Update__c, true, 'Dev Batch Update field should be true');//Positive case
        System.assertEquals(mockedBuildings[2].Dev_Batch_Update__c, false, 'Dev Batch Update field should be false');//Negative case
        System.assertEquals(mockedBuildings[3].Dev_Batch_Update__c, false, 'Dev Batch Update field should be false');//Negative case
    }
    
    private static List<Cluster__c> getInsertedClusters() {
        List<Cluster__c> testClusters = new List<Cluster__c>();
        for(Integer i = 0; i < 4; i++) {
            testClusters.add(new Cluster__c(
                Id = TestUtility.getFakeId(Cluster__c.getSObjectType()), 
                Name = 'Test Cluster '+ i
            ));
        }
        return testClusters;
    }
    
    private static List<Market__c> getInsertedPortfolios() {
        List<Market__c> testPortfolios = new List<Market__c>();
        for(Integer i = 0; i < 4; i++) {
            testPortfolios.add(new Market__c(
                Id = TestUtility.getFakeId(Market__c.getSObjectType()), 
                Name = 'Test Portfolio '+ i
            ));
        }
        return testPortfolios;
    }
    
    private static List<Building__c> getInsertedBuildings() {
        List<Building__c> testBuildings = new List<Building__c>();
        for(Integer i = 0; i < 4; i++) {
            testBuildings.add(new Building__c(
                Id = TestUtility.getFakeId(Building__c.getSObjectType()),
                Name = 'Test Building ' + i
            ));
        }
        return testBuildings;
    }
}