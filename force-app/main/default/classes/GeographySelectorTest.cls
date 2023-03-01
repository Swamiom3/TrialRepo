/*************************************************************************************************************************************
    Author      :    Ishwar Shinde
    Description :    This is test class for GeographySelector class
    --------------------------------------------------------------------------------------------------------------------------------------
    VERSION    DATE              AUTHOR             DETAIL
    1          10 March, 2022    Ishwar Shinde      Initial Deployment
**************************************************************************************************************************************/
@isTest
public with sharing class GeographySelectorTest {
    private static GeographySelector geographySelector = new GeographySelector();

    @testSetup
    static void makeData(){
        Region__c region = UtilBuilding.createRegion('Test Region Name', true);
        Territory__c territory = UtilBuilding.createTerritory('Test Territory Name', region.Id, true);
        Market__c market = UtilMarket.createMarkets(1, true)[0];
        market.Name = 'Test_market';
        market.TerritoryID__c = territory.id;
        update market;
        Building__c testBuilding = new Building__c(City__c = 'Test_Pune', Country__c = 'Test_India',Name = 'PMS-Metrocity', CurrencyIsoCode = 'USD', UUID__c = '123456789', Market__c = market.id);
        TestingUtility.insertWithAssert(testBuilding);

        Geography__c testGeography = new Geography__c(
            Name = 'Aurangabad123, Maharashtra',
            City__c = 'Test_Aurangabad',
            Country__c = 'Test_India',
            Country_Code__c = '+91',
            District__c = 'Test_Aurangabad',
            Formatted_Address__c = 'Badnapur2456, Maharashtra 412605, India', 
            Geocode__Latitude__s = 75.4771383 ,
            Geocode__Longitude__s = 88.3079647,
            Place_ID__c = 'ChIJy2456M--wjs2456_-5cSkaE', 
            Nearest_Building__c = testBuilding.Id
        );
        insert testGeography;
    }
    
    @isTest
    static void shouldGetGeographiesByIdAndNotNullNearestBuilding(){
        List<Geography__c> geographys;
        List<Geography__c> getEmptyGeographys;
        Id getGeographyId = [SELECT Id FROM Geography__c][0].Id;
        Id getGeographyNearBuilding = [SELECT Nearest_Building__c FROM Geography__c][0].Nearest_Building__c;
        Test.startTest();
        geographys = geographySelector.getGeographiesByIdAndNotNullNearestBuilding(new List<Id>{getGeographyId});
        getEmptyGeographys = geographySelector.getGeographiesByIdAndNotNullNearestBuilding(new List<Id>{});
        Test.stopTest();

        System.assertEquals(getGeographyNearBuilding, geographys[0].Nearest_Building__c, 'Should get Geography Nearest Building');
        System.assertNotEquals(null, geographys[0].Id, 'Should not get null Id');
        System.assertEquals(true, getEmptyGeographys.isEmpty(), 'Should get Empty Geography');
    }
    
    @isTest
    static void shouldGetGeographiesByIDs(){
        List<Geography__c> geographys;
        List<Geography__c> getEmptyGeographys;
        Id getGeographyId = [SELECT Id FROM Geography__c][0].Id;
        Test.startTest();
        geographys = geographySelector.getGeographiesByIDs(new List<String>{getGeographyId});
        getEmptyGeographys = geographySelector.getGeographiesByIDs(new List<String>{});
        Test.stopTest();

        System.assertEquals('Test_Aurangabad', geographys[0].City__c, 'Should get City');
        System.assertNotEquals(null, geographys[0].Name, 'Should not get null Name');        
        System.assertEquals(true, getEmptyGeographys.isEmpty(), 'Should get Empty Geography');
    }
    
    @isTest
    static void shouldGetGeographiesByID(){
        List<Geography__c> geographys;
        List<Geography__c> getEmptyGeographys;
        Id getGeographyId = [SELECT Id FROM Geography__c][0].Id;
        Test.startTest();
        geographys = geographySelector.getGeographiesById(getGeographyId);
        getGeographyId = null;
        getEmptyGeographys = geographySelector.getGeographiesById(getGeographyId);
        Test.stopTest();

        System.assertEquals('PMS-Metrocity', geographys[0].Nearest_Building__r.Name, 'Should get Nearest Building Name');
        System.assertEquals(88.3079647, geographys[0].Geocode__Longitude__s, 'Should get Geocode (Longitude)');
        System.assertNotEquals(null, geographys[0].Name, 'Should not get null Name');
        System.assertEquals(true, getEmptyGeographys.isEmpty(), 'Should get Empty Geography');
    }

    @isTest
    static void shouldGetGeographiesByNearestBuilding(){
        List<Geography__c> geographys;
        List<Geography__c> getEmptyGeographys;
        Id getBuildingId = [SELECT Id FROM Building__c][0].Id;
        Test.startTest();
        geographys = geographySelector.getGeographiesByNearestBuilding(getBuildingId);
        getBuildingId = null;
        getEmptyGeographys = geographySelector.getGeographiesByNearestBuilding(getBuildingId);
        Test.stopTest();

        System.assertNotEquals(null, geographys[0].Id, 'Geography Id Field should be retrieved');
        System.assertEquals('Aurangabad123, Maharashtra', geographys[0].Name, 'should get Geography Name Field');
    	System.assertEquals(true, getEmptyGeographys.isEmpty(), 'Should get Empty Geography');
    }
    
    @isTest
    static void shouldGetGeographiesByIdAndNotNullUUIDs(){
        List<Geography__c> geographys;
        List<Geography__c> getEmptyGeographys;
        Id getGeographyId = [SELECT Id FROM Geography__c][0].Id;
        Id getBuildingId = [SELECT Id FROM Building__c][0].Id;
        Test.startTest();
        geographys = geographySelector.getGeographiesByIdAndNotNullUUIDs(getGeographyId);
        getGeographyId = null;
        getEmptyGeographys = geographySelector.getGeographiesByIdAndNotNullUUIDs(getGeographyId);
        Test.stopTest();        
        System.assertEquals(getBuildingId, geographys[0].Nearest_Building__c, 'Geography Nearest Building Field should be retrieved');
        System.assertEquals('123456789', geographys[0].Nearest_Building__r.UUID__c, 'should get Geography Nearest Building UUID Field');
    	System.assertEquals(true, getEmptyGeographys.isEmpty(), 'Should get Empty Geography');
    }
    
    @isTest
    static void shouldGetGeographiesByCountryCode(){
        List<Geography__c> geographys;
        List<Geography__c> getEmptyGeographys;
		String getGeographyCountryCode = [SELECT Country_Code__c FROM Geography__c][0].Country_Code__c;
        Test.startTest();
        geographys = geographySelector.getGeographiesByCountryCode(getGeographyCountryCode);
        getGeographyCountryCode = '';
        getEmptyGeographys = geographySelector.getGeographiesByCountryCode(getGeographyCountryCode);
        Test.stopTest();        
        System.assertEquals('Test_market', geographys[0].Nearest_Building__r.Market__r.Name, 'Geography Nearest Building Market Name should be retrieved');
        System.assertEquals('Test Territory Name', geographys[0].Nearest_Building__r.Market__r.TerritoryID__r.Name, 'should get Geography Nearest Building Market Territory Name Field');
        System.assertNotEquals(null, geographys[0].id, 'Geography should not be null');
        System.assertEquals(true, getEmptyGeographys.isEmpty(), 'Should get Empty Geography');
    }
    
    @isTest
    static void shouldGetGeographiesByPlaceId(){
        List<Geography__c> geographys;
        List<Geography__c> getEmptyGeographys;
        String getGeographyPlaceId = [SELECT Place_ID__c FROM Geography__c][0].Place_ID__c;
        Test.startTest();
        geographys = geographySelector.getGeographiesByPlaceId(getGeographyPlaceId);
        getGeographyPlaceId = null;
        getEmptyGeographys = geographySelector.getGeographiesByPlaceId(getGeographyPlaceId);
        Test.stopTest();

        System.assertEquals('ChIJy2456M--wjs2456_-5cSkaE', geographys[0].Place_ID__c, 'Should get Place ID');
        System.assertNotEquals('Test_Pune', geographys[0].City__c, 'Should get proper city Name');
        System.assertEquals(true, getEmptyGeographys.isEmpty(), 'Should get Empty Geography');
    }
}