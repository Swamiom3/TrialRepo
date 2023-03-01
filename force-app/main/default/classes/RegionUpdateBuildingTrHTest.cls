/*************************************************************************************************
    Author        :  Ashish Sharma
    Description   :  Test class for RegionUpdateBuildingTrH
    Issue No.     :  ST-8737
    History       :
--------------------------------------------------------------------------------------------------
    VERSION        DATE            AUTHOR             DETAIL
    1          10-Aug-2021      Ashish Sharma        Refactor
**************************************************************************************************/
@isTest
private class RegionUpdateBuildingTrHTest {
    @isTest
    private static void updateRegionInfoOnBuildingTest() {
        User assignedUser = getUser();
        List<Region__c> testRegions = getInsertedRegions(4);
        List<Region__c> mockedRegions = new List<Region__c>{
            new Region__c(Id = testRegions[0].Id, Region__c = 'Mocked Region 1', 
                          Regional_Sales_Manager__c = assignedUser.Id, 
                          Regional_Sales_Manager__r = assignedUser),
            new Region__c(Id = testRegions[1].Id, Region__c = 'Mocked Region 2', 
                          Regional_Sales_Manager__c = assignedUser.Id, 
                          Regional_Sales_Manager__r = assignedUser),
            new Region__c(Id = testRegions[2].Id, Region__c = 'Mocked Region 3'),
            new Region__c(Id = testRegions[3].Id)
        };
        List<Territory__c> testTerritories = getInsertedTerritories(mockedRegions);        
        List<Market__c> testPortfolios = getInsertedPortfolio(testTerritories);
        List<Building__c> testBuildings = getInsertedBuildings(testPortfolios);
        
        Test.startTest();
        RegionUpdateBuildingTrH regionUpdateBldg = new RegionUpdateBuildingTrH();
        regionUpdateBldg.oldRegionsMap = new Map<Id, Region__c>(testRegions);
        regionUpdateBldg.newRegions = mockedRegions;
        regionUpdateBldg.buildingSelector = (BuildingSelector) 
                                            MockService.createMock(BuildingSelector.class,
                                                                   new Map<String, Object>{
                                                                       'getBuildingsByRegions' => testBuildings
                                                                   });
        regionUpdateBldg.afterUpdate();
        Test.stopTest();
        
        for(Integer i = 0; i < mockedRegions.size(); i++) {
            Region__c region = mockedRegions[i];
            Building__c building = regionUpdateBldg.buildingsToUpdate[i];
            System.assertEquals(region.Regional_Sales_Manager__r.Email,
                                building.Regional_Sales_Manager_Email__c, 
                                'Regional Sales Manager Email on building should be updated with Regional Sales Manager\'s Email from its Region');
            System.assertEquals(region.Regional_Sales_Manager__r.Name,
                                building.Regional_Sales_Manager_Name__c,
                                'Regional Sales Manager Name on building should be updated with Regional Sales Manager\'s Name from its Region');
            System.assertEquals(region.Region__c,
                                building.Region_Name__c,
                                'Region Name on building should be updated with Region__c from its Region');
        } 
    }
    
    private static List<Region__c> getInsertedRegions(Integer size) {
        List<Region__c> testRegions = new List<Region__c>();
        for(Integer i = 0; i < size; i++) {
            testRegions.add(new Region__c(
                Id = TestUtility.getFakeId(Region__c.getSObjectType()), 
                Name = 'Region ' + i,
                Region__c = 'Test Region ' + i
            ));
        }
        return testRegions;
    }
    
    private static List<Building__c> getInsertedBuildings(List<Market__c> portfolio) {
        List<Building__c> testBuildings = new List<Building__c>();
        for(Integer i = 0; i < portfolio.size(); i++) {
            testBuildings.add(new Building__c(
                Id = TestUtility.getFakeId(Building__c.getSObjectType()), 
                Name = 'Test Territory ' + i,
                Market__c = portfolio[i].Id,
                Market__r = portfolio[i]
            ));
        }
        return testBuildings;
    }
    
    private static List<Territory__c> getInsertedTerritories(List<Region__c> regions) {
        List<Territory__c> testTerritories = new List<Territory__c>();
        for(Integer i = 0; i < regions.size(); i++) {
            testTerritories.add(new Territory__c(
                Id = TestUtility.getFakeId(Territory__c.getSObjectType()), 
                Name = 'Test Territory 1',
                RegionID__c = regions[i].Id,
                RegionID__r = regions[i]
            ));
        }
        return testTerritories;
    }
    
    private static List<Market__c> getInsertedPortfolio(List<Territory__c> territories) {
        List<Market__c> testPortfolios = new List<Market__c>();
        for(Integer i = 0; i < territories.size(); i++) {
            testPortfolios.add(new Market__c(
                Id = TestUtility.getFakeId(Market__c.getSObjectType()), 
                Name = 'Test Portfolio '+ i,
                TerritoryID__c = territories[i].Id,
                TerritoryID__r = territories[i]
            ));
        }
        return testPortfolios;
    }
    
    private static User getUser() {
        return new User(
            Id = TestUtility.getFakeId(User.getSObjectType()),
            Email = 'testUser@wework.com'
        );
    }
}