/*************************************************************************************************
    Author        :  Shobhit Gahlot
    Description   :  Test class for TerritoryUpdateBuildingTrH
    Issue No.     :  ST-8870
    History       :
--------------------------------------------------------------------------------------------------
    VERSION        DATE            AUTHOR             DETAIL
    1          24-Aug-2021      Shobhit Gahlot        Refactor
**************************************************************************************************/
@isTest
private class TerritoryUpdateBuildingTrHTest {
    @isTest
    private static void updateTerritoryInfoOnBuildingTest() {
        User assignedUser = [SELECT Id, Name, Email FROM User LIMIT 1];
        List<Region__c> testRegions = getTestRegions(4, assignedUser);
        List<Territory__c> oldTerritories = getTestTerritories(testRegions, assignedUser);
        List<Territory__c> newTerritories = oldTerritories.deepClone(true);
        newTerritories[0].Territory__c = 'Territory 1';
        newTerritories[1].Territory__c = 'Territory 2';
        newTerritories[2].Territory__c = 'Territory 0';
        newTerritories[3].Name = 'Negative Territory';
        
        List<Market__c> testPortfolios = getTestPortfolio(newTerritories);
        List<Building__c> testBuildings = getTestBuildings(testPortfolios);
        
        Test.startTest();
        TerritoryUpdateBuildingTrH territoryUpdateBldg = new TerritoryUpdateBuildingTrH();
        territoryUpdateBldg.registerDmlConsolidator(DmlConsolidatorDefault.getInstance());
        territoryUpdateBldg.oldTerritoriesMap = new Map<Id, Territory__c>(oldTerritories);
        territoryUpdateBldg.newTerritories = newTerritories;
        territoryUpdateBldg.buildingSelector = (BuildingSelector) 
                                               MockService.createMock(BuildingSelector.class,
                                                                      new Map<String, Object>{
                                                                          'getBuildingsByTerritories' => new List<Building__c> {
                                                                              testBuildings[0], testBuildings[1], testBuildings[2]
                                                                      }});
        territoryUpdateBldg.afterUpdate();
        Test.stopTest();
        
        for(Integer i = 0; i < 3; i++) {
            checkPositiveAsserts(newTerritories[i], territoryUpdateBldg.buildingsToUpdate[i]);
        }
        
        checkNegativeAsserts(newTerritories[3], testBuildings[3]);
    }
    
    private static void checkPositiveAsserts(Territory__c territory, Building__c building) {
        System.assertEquals(territory.Territory__c,
                            building.Territory_Name__c, 
                            'Territory name on building should be updated with Territory name from its Territory');
        System.assertEquals(territory.Territory_Sales_Manager__r.Name,
                            building.Territory_Sales_Manager_Name__c,
                            'Territory Sales Manager Name on building should be updated with Territory Sales Manager\'s Name from its Territory');
        System.assertEquals(territory.RegionID__r.Region__c,
                            building.Region_Name__c,
                            'Region Name on building should be updated with Region__c from its Territory');
        System.assertEquals(territory.RegionID__r.Regional_Sales_Manager__r.Email,
                            building.Regional_Sales_Manager_Email__c,
                            'Region Sales Manager Email on building should be updated with Region Sales Manager\'s Email from its Territory');
        System.assertEquals(territory.Territory_Sales_Manager__r.Email,
                            building.Territory_Sales_Manager_Email__c,
                            'Territory Sales Manager Email on building should be updated with Territory Sales Manager\'s Email from its Territory');
        System.assertEquals(territory.RegionID__r.Regional_Sales_Manager__r.Name,
                            building.Regional_Sales_Manager_Name__c,
                            'Region Sales Manager Name on building should be updated with Region Sales Manager\'s Name from its Territory');
    }
    
    private static void checkNegativeAsserts(Territory__c territory, Building__c building) {
        System.assertNotEquals(territory.Territory__c,
                               building.Territory_Name__c, 
                               'Territory name on building should not be updated with Territory name from its Territory');
        System.assertNotEquals(territory.RegionID__r.Region__c,
                               building.Region_Name__c,
                               'Region Name on building should not be updated with Region__c from its Territory');
        System.assertNotEquals(territory.RegionID__r.Regional_Sales_Manager__r.Email,
                               building.Regional_Sales_Manager_Email__c,
                               'Region Sales Manager Email on building should not be updated with Region Sales Manager\'s Email from its Territory');
        System.assertNotEquals(territory.Territory_Sales_Manager__r.Email,
                               building.Territory_Sales_Manager_Email__c,
                               'Territory Sales Manager Email on building should not be updated with Territory Sales Manager\'s Email from its Territory');
    }
    
    private static List<Region__c> getTestRegions(Integer size, User assignedUser) {
        List<Region__c> testRegions = new List<Region__c>();
        for(Integer i = 0; i < size; i++) {
            testRegions.add(new Region__c(
                Id = TestUtility.getFakeId(Region__c.getSObjectType()), 
                Name = 'Region ' + i,
                Region__c = 'Test Region ' + i,
                Regional_Sales_Manager__c = assignedUser.Id, 
                Regional_Sales_Manager__r = assignedUser
            ));
        }
        return testRegions;
    }
    
    private static List<Building__c> getTestBuildings(List<Market__c> portfolios) {
        List<Building__c> testBuildings = new List<Building__c>();
        for(Integer i = 0; i < portfolios.size(); i++) {
            testBuildings.add(new Building__c(
                Id = TestUtility.getFakeId(Building__c.getSObjectType()), 
                Name = 'Test Building ' + i,
                Market__c = portfolios[i].Id,
                Market__r = portfolios[i]
            ));
        }
        return testBuildings;
    }
    
    private static List<Territory__c> getTestTerritories(List<Region__c> regions, User assignedUser) {
        List<Territory__c> testTerritories = new List<Territory__c>();
        for(Integer i = 0; i < regions.size(); i++) {
            testTerritories.add(new Territory__c(
                Id = TestUtility.getFakeId(Territory__c.getSObjectType()), 
                Name = 'Territory ' + i,
                Territory__c = 'Territory ' + i,
                RegionID__c = regions[i].Id,
                RegionID__r = regions[i],
                Territory_Sales_Manager__c = assignedUser.Id,
                Territory_Sales_Manager__r = assignedUser
            ));
        }
        return testTerritories;
    }
    
    private static List<Market__c> getTestPortfolio(List<Territory__c> territories) {
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
}