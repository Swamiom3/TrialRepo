/************************************************************************************************************************************
Author      : Milanjeet
Description : This class contains unit tests of PortfolioUpdatePortInfoOnBuildingTrHTest

History :
----------------------------------------------------------------------------------------------------------------------------------
VERSION    DATE           AUTHOR            DETAIL
1          9 Nov 2017     Milanjeet         Initial development
2          16 Aug 2021    Pawel Biszczak    Refactor, adding unit tests
**************************************************************************************************************************************/
@isTest
public with sharing class PortfolioUpdatePortInfoOnBuildingTrHTest {
    @isTest
    static void shouldProceedWithBuildingsToUpdate(){
        List<Building__c> buildingsToUpdate;
        List<Market__c> markets = getFakeMarkets(true);
        markets[0].Portfolio__c = 'P000A1';
        markets[1].Portfolio__c = 'P000A2';
        markets[2].Portfolio__c = 'P000A3';

        List<Market__c> oldMarkets = markets.deepClone(true);
        markets[1].Portfolio__c = 'P000A5';
        markets[2].Portfolio__c = 'P000a3';
        Map<Id, Market__c> oldMarketsByIds = new Map<Id,Market__c>();
        oldMarketsByIds.putAll(new Map<Id, Market__c>(oldMarkets));

        List<Building__c> buildings = getFakeBuildings(true);
        buildings[0].Market__c = markets[1].Id;

        Test.startTest();
        PortfolioUpdatePortInfoOnBuildingTrH handlerInstance = new PortfolioUpdatePortInfoOnBuildingTrH(markets, oldMarketsByIds);
        handlerInstance.buildingSelector = (BuildingSelector) MockService.createMock(
                                                                BuildingSelector.class,
                                                                new Map<String, Object>{
                                                                    'getBuildingsByMarkets' => new List<Building__c>{ buildings[0]}});
        buildingsToUpdate = handlerInstance.prepareBuildingsForPortfolioUpdate();
        Test.stopTest();

        System.assertEquals(1, buildingsToUpdate.size(), 'Should change only one record because of data mocking for query');
        System.assertEquals(buildingsToUpdate[0].Id, buildings[0].Id, 'Should be equal the first building record Id');
    }

    @isTest
    static void shouldNotProceedWithNotChangedPortfolios(){
        List<Building__c> buildingsToUpdate;
        List<Market__c> markets = getFakeMarkets(true);
        markets[0].Portfolio__c = 'P000A1';
        markets[1].Portfolio__c = 'P000A2';
        markets[2].Portfolio__c = 'P000A3';

        List<Market__c> oldMarkets = markets.deepClone(true);
        Map<Id, Market__c> oldMarketsByIds = new Map<Id,Market__c>();
        oldMarketsByIds.putAll(new Map<Id, Market__c>(oldMarkets));

        Test.startTest();
        PortfolioUpdatePortInfoOnBuildingTrH handlerInstance = new PortfolioUpdatePortInfoOnBuildingTrH(markets, oldMarketsByIds);
        buildingsToUpdate = handlerInstance.prepareBuildingsForPortfolioUpdate();
        Test.stopTest();

        System.assert(buildingsToUpdate.isEmpty(), 'Should not proceed with same values on portfolios update');
    }

    @isTest
    static void shouldThrowAnExceptionOnFakeBuildingsToUpdate(){
        List<Market__c> markets = getFakeMarkets(true);
        String exceptionMessage;
        markets[0].Portfolio__c = 'P000A1';
        markets[1].Portfolio__c = 'P000A2';
        markets[2].Portfolio__c = 'P000A3';

        List<Market__c> oldMarkets = markets.deepClone(true);
        markets[1].Portfolio__c = 'P000A5';
        markets[2].Portfolio__c = 'P000a3';
        Map<Id, Market__c> oldMarketsByIds = new Map<Id,Market__c>();
        oldMarketsByIds.putAll(new Map<Id, Market__c>(oldMarkets));

        List<Building__c> buildings = getFakeBuildings(true);
        buildings[0].Market__c = markets[1].Id;

        Test.startTest();
        try {
            PortfolioUpdatePortInfoOnBuildingTrH handlerInstance = new PortfolioUpdatePortInfoOnBuildingTrH(markets, oldMarketsByIds);
            handlerInstance.buildingSelector = (BuildingSelector) MockService.createMock(
                    BuildingSelector.class,
                    new Map<String, Object>{
                            'getBuildingsByMarkets' => new List<Building__c>{
                                    buildings[0]
                            }
                    });
            handlerInstance.updatePortfolioInfoOnBuilding();
        } catch (Exception exp) {
            System.assert(String.isNotBlank(exp.getMessage()), 'Should thrown an exception on fake buildings update');
            exceptionMessage = exp.getMessage();
        }
        Test.stopTest();

        System.assert(String.isNotBlank(exceptionMessage), 'Should catch an exception and assign exception message to variable');
    }

    @isTest
    static void shouldPrepareChangedPortfolios(){
        Set<Id> changedPortfoliosIds;
        List<Market__c> markets = getFakeMarkets(true);
        markets[0].Portfolio__c = 'P000A1';
        markets[1].Portfolio__c = 'P000A2';
        markets[2].Portfolio__c = 'P000A3';

        List<Market__c> oldMarkets = markets.deepClone(true);
        markets[1].Portfolio__c = 'P000A5';
        markets[2].Portfolio__c = 'P000a3';
        Map<Id, Market__c> oldMarketsByIds = new Map<Id,Market__c>();
        oldMarketsByIds.putAll(new Map<Id, Market__c>(oldMarkets));

        Test.startTest();
        PortfolioUpdatePortInfoOnBuildingTrH handlerInstance = new PortfolioUpdatePortInfoOnBuildingTrH(markets, oldMarketsByIds);
        changedPortfoliosIds = handlerInstance.getChangedPortfoliosIds();
        Test.stopTest();

        System.assertEquals(1, changedPortfoliosIds.size(), 'Should change only one record because of case ignore');
        System.assert(changedPortfoliosIds.contains(markets[1].Id), 'Should change only the second record because of case ignore on the last one');
        System.assert(!changedPortfoliosIds.contains(markets[2].Id), 'Should not contain third record because of the case ignore');
    }

    @isTest
    static void shouldGetBuildingRecords(){
        List<Building__c> buildingsForUpdate;
        List<Market__c> markets = getFakeMarkets(true);
        markets[0].Portfolio__c = 'P000A1';
        markets[1].Portfolio__c = 'P000A2';
        markets[2].Portfolio__c = 'P000A3';

        List<Building__c> buildings = getFakeBuildings(true);
        buildings[0].Market__c = markets[0].Id;
        buildings[0].Market__r = markets[0];
        buildings[1].Market__c = markets[1].Id;
        buildings[2].Market__c = markets[2].Id;

        Test.startTest();
        PortfolioUpdatePortInfoOnBuildingTrH handlerInstance = new PortfolioUpdatePortInfoOnBuildingTrH(null, null);
        buildingsForUpdate = handlerInstance.getBuildingsRecords(buildings);
        Test.stopTest();

        System.assert(!buildingsForUpdate.isEmpty(), 'Should prepare new buildings');
        System.assertEquals(3, buildingsForUpdate.size(), 'Should prepare new buildings for all 3 records');
        System.assertEquals(buildingsForUpdate[0].Portfolio_Name__c, buildings[0].Market__r.Portfolio__c, 'Portfolio name should be equal');
    }

    static List<Building__c> getFakeBuildings(Boolean isFakeIds) {
        Map<String, Object> recordsData = new Map<String, Object>();
        recordsData = new Map<String, Object>();
        recordsData.put('objectName', 'Building__c');
        recordsData.put('numberOfRecords', 3);
        return MockTestingUtility.getRecords(recordsData, isFakeIds);
    }

    static List<Market__c> getFakeMarkets(Boolean isFakeIds) {
        Map<String, Object> recordsData = new Map<String, Object>();
        recordsData = new Map<String, Object>();
        recordsData.put('objectName', 'Market__c');
        recordsData.put('numberOfRecords', 3);
        return MockTestingUtility.getRecords(recordsData, isFakeIds);
    }

    @isTest
    public static void shouldUpdatePortfolioInfoOnBuildingWithDMLS(){
        Profile adminProfile = [SELECT Id
                                FROM Profile
                                WHERE Name = 'Wework System Administrator'];

        Map<String, Object> firstPortfolioSalesManagerData = new Map<String, Object>();
        firstPortfolioSalesManagerData.put('LastName', 'FirstPortfolioSalesManager');
        firstPortfolioSalesManagerData.put('Username', 'FirstPortfolioSalesManager@weworkexample.com');
        firstPortfolioSalesManagerData.put('Email', 'FirstPortfolioSalesManager@weworkexample.com');
        User firstPortfolioSalesManager = TestingUtility.insertUserWithAssert(adminProfile.Id, firstPortfolioSalesManagerData, true);

        Map<String,Object> secondPortfolioSalesManagerData = new Map<String,Object>();
        secondPortfolioSalesManagerData.put('LastName', 'SecondPortfolioSalesManager');
        secondPortfolioSalesManagerData.put('Username', 'SecondPortfolioSalesManager@weworkexample.com');
        secondPortfolioSalesManagerData.put('Email', 'SecondPortfolioSalesManager@weworkexample.com');
        User secondPortfolioSalesManager = TestingUtility.insertUserWithAssert(adminProfile.Id, secondPortfolioSalesManagerData, true);

        Map<String,Object> firstTerritorySalesManagerData = new Map<String,Object>();
        firstTerritorySalesManagerData.put('LastName','FirstTerritorySalesManager');
        firstTerritorySalesManagerData.put('Username','FirstTerritorySalesManager@weworkexample.com');
        firstTerritorySalesManagerData.put('Email','FirstTerritorySalesManager@weworkexample.com');
        User firstTerritorySalesManager = TestingUtility.insertUserWithAssert(adminProfile.Id, firstTerritorySalesManagerData, true);

        Map<String,Object> secondTerritorySalesManagerData = new Map<String,Object>();
        secondTerritorySalesManagerData.put('LastName','SecondTerritorySalesManager');
        secondTerritorySalesManagerData.put('Username','SecondTerritorySalesManager@weworkexample.com');
        secondTerritorySalesManagerData.put('Email','SecondTerritorySalesManager@weworkexample.com');
        User secondTerritorySalesManager = TestingUtility.insertUserWithAssert(adminProfile.Id, secondTerritorySalesManagerData, true);

        Territory__c firstTerritory = new Territory__c();
        firstTerritory.Name = 'First Test Territory';
        firstTerritory.Territory__c = 'First Test Territory';
        firstTerritory.Territory_Sales_Manager__c = firstTerritorySalesManager.Id;
        insert firstTerritory;
        System.assert(firstTerritory.Id!=null, 'Territory Not Inserted');

        Territory__c secondTerritory = new Territory__c();
        secondTerritory.Name = 'Second Test Territory';
        secondTerritory.Territory__c = 'Second Test Territory';
        secondTerritory.Territory_Sales_Manager__c = secondTerritorySalesManager.Id;
        insert secondTerritory;
        System.assert(secondTerritory.Id!=null, 'Territory Not Inserted');

        Market__c portfolio = new Market__c();
        portfolio.Name = 'Test Portfolio';
        portfolio.Portfolio__c = 'Test Portfolio';
        portfolio.Portfolio_Sales_Manager__c = firstPortfolioSalesManager.Id;
        portfolio.TerritoryID__c = firstTerritory.Id;
        insert portfolio;
        System.assert(portfolio.Id!=null, 'Portfolio Not Inserted');

        Building__c building = new Building__c(Name='Test Building',Market__c=portfolio.Id);
        insert building;
        System.assert(building.Id!=null, 'Building not inserted');

        building = [SELECT Id, Market__c, Portfolio_Name__c, Portfolio_Sales_Manager_Name__c,
                           Territory_Name__c, Territory_Sales_Manager_Name__c
                    FROM Building__c
                    WHERE Id =: building.Id];
        portfolio = [SELECT Id, Name, Portfolio__c, Portfolio_Sales_Manager__r.Name,
                            Territory__c, TerritoryID__r.Territory__c, TerritoryID__r.Territory_Sales_Manager__r.Name
                     FROM Market__c
                     WHERE Id =: portfolio.Id];

        System.assertEquals(portfolio.Name, building.Portfolio_Name__c,
                            'Portfolio Name Not Updated on Building');
        System.assertEquals(portfolio.Portfolio_Sales_Manager__r.Name, building.Portfolio_Sales_Manager_Name__c,
                            'Portfolio sales Manager Name Not Updated in Building');
        System.assertEquals(portfolio.Territory__c,building.Territory_Name__c ,
                            'Territory Name not Updated on Building');
        System.assertEquals(portfolio.TerritoryID__r.Territory_Sales_Manager__r.Name, building.Territory_Sales_Manager_Name__c,
                            'Territory Sales manager Name Not Updated on Building');

        Test.startTest();
        portfolio.Portfolio__c = 'Test Portfolio Updated';
        portfolio.Portfolio_Sales_Manager__c = secondPortfolioSalesManager.Id;
        portfolio.TerritoryID__c = secondTerritory.Id;
        update portfolio;
        Test.stopTest();

        building = [SELECT Id, Market__c, Portfolio_Name__c, Portfolio_Sales_Manager_Name__c,
                           Territory_Name__c, Territory_Sales_Manager_Name__c
                    FROM Building__c
                    WHERE Id =: building.Id];
        portfolio = [SELECT Id, Name, Portfolio__c, Portfolio_Sales_Manager__r.Name,
                            Territory__c, TerritoryID__r.Territory__c, TerritoryID__r.Territory_Sales_Manager__r.Name
                     FROM Market__c
                     WHERE Id=:portfolio.Id];

        System.assertEquals(portfolio.Portfolio__c, building.Portfolio_Name__c,
                            'Portfolio Name Not Updated on Building');
        System.assertEquals(portfolio.Portfolio_Sales_Manager__r.Name, building.Portfolio_Sales_Manager_Name__c,
                            'Portfolio sales Manager Name Not Updated in Building');
        System.assertEquals(portfolio.Territory__c,building.Territory_Name__c,
                            'Territory Name not Updated on Building');
        System.assertEquals(portfolio.TerritoryID__r.Territory_Sales_Manager__r.Name, building.Territory_Sales_Manager_Name__c,
                            'Territory Sales manager Name Not Updated on Building');
    }
}