/**********************************************************************************************************
    Author        :  Rohit Nimase
    Description   :  This is a test class for GeographyUpdateNearestBuildingTrH.
    Issue No.     :  ST-8735
    History       :
-----------------------------------------------------------------------------------------------------------
    VERSION        DATE          AUTHOR           DETAIL
      1            10-Aug-2021   Rohit Nimase     Refactor and move to new framework
**********************************************************************************************************/

@isTest
public class GeographyUpdateNearestBuildingTrHTest { 
    private static final List<String> geoNames = new List<String>{'Baner ,Maharashtra',
                                                                  '1460 Broadway, WeWork',
                                                                  '2 Sheraton St Medius House, WeWork',
                                                                  '33 Rue la Fayette, WeWork',
                                                                  '10F, Mass Mutual Tower, 33 Lockhart Rd, WeWork'};
    @testSetup
    private static void setup() {
        List<Market__c> markets = UtilMarket.createMarkets(4, true);
        List<Geography__c> geographies = new List<Geography__c>();
        List<Building__c> buildings = new List<Building__c>();
        buildings.add(UtilBuilding.createBuilding('BKN-Delhi Heights', 'Delhi', 'India', 'Delhi', null, null, false));
        buildings[0].Market__c = markets[1].Id;
        buildings.add(UtilBuilding.createBuilding('BL-Sony Center', 'New York', 'United States', 'New York', null, null, false));
        buildings[1].Market__c = markets[2].Id;
        buildings.add(UtilBuilding.createBuilding('AMS-UK', 'London', 'United Kingdom', 'London', null, null, false));
        buildings[2].Market__c = markets[3].Id;
        buildings.add(UtilBuilding.createBuilding('AMS-France', 'Paris', 'France', 'Paris', null, null, false));
        buildings.add(UtilBuilding.createBuilding('AMS-China', 'Wan Chai', 'China', 'Hong Kong', null, null, false));
        TestingUtility.insertListWithAssert(buildings);        
        
        geographies.add(UtilGeography.createGeography(geoNames[0], 'Delhi', 'India', 'Delhi', 'Delhi', 'Baner, Delhi, Delhi, India', null, 'ChIJy9Nd8M--wjsRfat_-5cSkaF', null, 18.5596581, 73.7799374, false));
        geographies.add(UtilGeography.createGeography(geoNames[1], 'New York', 'United States', 'New York', 'New York', '1460 Broadway, New York, United States', null, 'ChIJy9Nd8M--wjsRfat_-5cSkaG', null, 45.5771387, 55.2079648, false));
        geographies.add(UtilGeography.createGeography(geoNames[2], 'London', 'United Kingdom', 'London', 'Maharashtra', '2 Sheraton St Medius House, London, United Kingdom', null, 'ChIJy9Nd8M--wjsRfat_-5cSkaH', null, 75.5771387, 85.2079648, false));
        geographies.add(UtilGeography.createGeography(geoNames[3], 'Paris', 'France','Paris', 'Paris', '33 Rue la Fayette, Paris, France', null, 'ChIJy9Nd8M--wjsRfat_-5cSkaM', null, 80.5771387, 85.2079648, false));
        geographies.add(UtilGeography.createGeography(geoNames[4], 'Wan Chai', 'China', 'Wan Chai', 'Hong Kong', '10F, Mass Mutual Tower, 33 Lockhart Rd, Paris, France', null, 'ChIJy9Nd8M--wjsRfat_-5cSkaN', null, 88.5771387, 85.2079648, false));
        TestingUtility.upsertListWithAssert(geographies);
        buildings[4].Geography__c = geographies[4].Id;
        update buildings[4];
    }
    
    @isTest
    public static void updateNearestBuildingTest() {
        List<Geography__c> geographies = [SELECT Id, City__c, Nearest_Building__c, Nearest_Building__r.Name, Building_Portfolio__c 
                                          FROM Geography__c WHERE Name IN :geoNames];
        verifyAsserts();
        for(Geography__c geography:  geographies) {
            geography.Nearest_Building__c = null;
        }
        Test.startTest();
        update geographies;
        Test.stopTest();
        verifyAsserts();
    }
    
    private static void verifyAsserts() {
        List<Geography__c> geographies = [SELECT Id, City__c, Nearest_Building__c, Nearest_Building__r.Name, Building_Portfolio__c 
                                          FROM Geography__c WHERE Name IN :geoNames];
        Map<Id, Building__c> buildings = new Map<Id, Building__c>([SELECT Id, Name, Geography__c, City__c, Geography__r.Name, Market__c FROM Building__c]);
        for(Geography__c geography : geographies) {
            System.assert(buildings.containsKey(geography.Nearest_Building__c), 
                                'Nearest Building on geography should be updated');
            System.assertEquals(buildings.get(geography.Nearest_Building__c).Market__c, geography.Building_Portfolio__c,
                                'Building Portfolio on geography should be updated based on Nearest Building');
        }
    }
}