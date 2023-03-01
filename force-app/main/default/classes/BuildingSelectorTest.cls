/*************************************************************************************************************************************
Author      :   Oleg Krasko
Description :   This class provides sufficient test coverage for BuildingSelector class
--------------------------------------------------------------------------------------------------------------------------------------
VERSION         DATE            AUTHOR              DETAIL
1               7/15/2020       Oleg Krasko         Initial Deployment
2               12/21/2021      Neelima             Increased the code coverage
**************************************************************************************************************************************/
@isTest
private class BuildingSelectorTest {
    private static BuildingSelector buildSelector = new BuildingSelector();
    private final static String TEST_NAME0 = 'TEST_NAME0';
    private final static String TEST_NAME1 = 'TEST_NAME1';
    private final static String UUID0 = 'testUUID0';
    private final static String UUID1 = 'testUUID1';
    private final static String TEST_CITY = 'TEST_CITY';
    private final static String TEST_STATE = 'TEST_STATE';
    private final static String TEST_COUNTRY = 'testCountry';
    private final static String TEST_EMAIL = 'test@test.com';
    private final static String TEST_REGION_NAME = 'testRegionName';
    static Integer s_num = 1;

    @testSetup
    static void makeData(){
        List<Building__c> buildingsToInsert = new List<Building__c>();
        Test.startTest();
        OperatingHours objOpHour = new OperatingHours(Name = 'EDT: Standard 9AM - 5PM Weekday');
        insert objOpHour;
        String clusterSalesRT = Schema.SObjectType.Cluster__c.getRecordTypeInfosByName().get('Sales Cluster').getRecordTypeId();
        Cluster__c cluster = new Cluster__c(Name = 'Test Cluster', RecordTypeId = clusterSalesRT);
        insert cluster;
        buildingsToInsert.add(TestingUtility.createBuilding(new Map<String, Object>{'UUID__c' => UUID0, 'Name' => 'Test Name 000', 'Email__c' => TEST_EMAIL, 'Region_Name__c' => TEST_REGION_NAME}, false));
        buildingsToInsert.add(TestingUtility.createBuilding(new Map<String, Object>{'Name' => 'Test Name 001', 'Cluster__c' => cluster.Id}, false));
        buildingsToInsert.add(TestingUtility.createBuilding(new Map<String, Object>{'Name' => 'Test Name 002', 'City__c' => TEST_CITY}, false));
        buildingsToInsert.add(TestingUtility.createBuilding(new Map<String, Object>{'UUID__c' => UUID1, 'Name' => 'Test Name 003', 'Country__c' => TEST_COUNTRY}, false));
        buildingsToInsert.add(TestingUtility.createBuilding(new Map<String, Object>{'Name' => 'Test Name 004', 'State__c' => TEST_STATE}, false));
        insert buildingsToInsert;
        Test.stopTest();
    }

    @isTest
    static void getDefaultFieldsTest(){
        buildSelector.setBuildingFieldsMetadata('fakeMetadata');
        buildSelector.getDefaultFields();
        System.assert(!buildSelector.defaultFields.isEmpty(),'Buildselector with defaultfield should be selected');
    }

    @isTest
    static void getBuildingsByUuidTest(){
        Building__c building = buildSelector.getBuildingsByUuid(UUID0)[0];
        List<Building__c> buildings = buildSelector.getBuildingsByUuid(new List<String>{UUID0, UUID1});
        List<Building__c> fakeBuildings0 = buildSelector.getBuildingsByUuid('');
        List<Building__c> fakeBuildings1 = buildSelector.getBuildingsByUuid(new List<String>());
        System.assert(building != null,'Building should not equal to null');
        System.assertEquals(UUID0, building.UUID__c,'UUID0 should equals to building uuid');
        System.assert(fakeBuildings0.isEmpty(),'fakebuilding should equal to empty list');
        System.assert(fakeBuildings1.isEmpty(),'fakebuilding should equal to empty list');
        System.assertEquals(UUID0, buildings[0].UUID__c,'UUID0 should equals to building uuid');
        System.assertEquals(UUID1, buildings[1].UUID__c,'UUID1 should equals to building uuid');
    }

    @isTest
    static void getBuildingsByUuidWithTourSchedulesTest(){
        Building__c building = buildSelector.getBuildingsByUuid(UUID0)[0];
        List<Building__c> buildings = buildSelector.getBuildingsByUuidWithTourSchedules(UUID0);
        List<Building__c> fakeBuildings0 = buildSelector.getBuildingsByUuidWithTourSchedules('');
        System.assert(fakeBuildings0.isEmpty(),'fakebuildings should equal to empty list');
        System.assertEquals(UUID0, buildings[0].UUID__c,'UUID0 should equals to building uuid');
    }

    @isTest
    static void getAllBuildingsWithTourSchedulesTest(){
        Building__c building = buildSelector.getBuildingsByUuid(UUID0)[0];
        List<Building__c> buildings = buildSelector.getAllBuildingsWithTourSchedules();
        System.assertEquals(UUID0, buildings[0].UUID__c,'UUID0 should equals to building uuid');
    }

    @isTest
    static void getBuildingsByIdWithTourSchedulesTest(){
        Building__c building = buildSelector.getBuildingsByUuid(UUID0)[0];
        List<Building__c> buildings = buildSelector.getBuildingsByIdWithTourSchedules(building.Id);
        List<Building__c> fakeBuildings0 = buildSelector.getBuildingsByIdWithTourSchedules(null);
        System.assert(fakeBuildings0.isEmpty(),'fakebuildings should equal to empty list');
        System.assertEquals(UUID0, buildings[0].UUID__c,'UUID0 should equals to building uuid');
    }

    @isTest
    static void getBuildingsByUuidPopulatedTest(){
        List<Building__c> buildingsWithUuidPopulated = buildSelector.getBuildingsByUuidPopulated();
        List<Building__c> allBuildings = buildSelector.getSObjectsWithoutFilters(new List<String>{'Id'});
        System.assertEquals(2, buildingsWithUuidPopulated.size(),'Number of buildings with UUID populated should be bigger than 2');
        //there are records with empty Uuid field
        System.assert(allBuildings.size() > 2,'Building size should be greater than 2');
    }

    @isTest
    static void getBuildingsByAddressesTest(){
        List<Building__c> buildings = buildSelector.getBuildingsByAddresses(new List<String>{TEST_CITY}, new List<String>{TEST_STATE}, new List<String>{TEST_COUNTRY});
        List<Building__c> fakeBuildings = buildSelector.getBuildingsByAddresses(new List<String>{'fakeCity'}, new List<String>{'fakeState'}, new List<String>{'fakeCountry'});
        buildSelector.getBuildingsByAddresses(new List<String>(), null, null);
        Id clusterId = [SELECT Id FROM Cluster__c LIMIT 1].Id;
        BuildingSelector building= new  BuildingSelector();
        building.getAllBuildingsWithTourSchedules();
        building.getBuildingsByCluster(new List<Id>{clusterId});
        String uuid='';
        building.getBuildingsByBuildingUUId(uuid);
        List<String> names = new List<String>();
        building.getBuildingsByName(names);
        building.getBuildingsByUuidWithTourSchedules(uuid);
        id ids=buildings[0].id;
        building.getBuildingsByIdWithTourSchedules(ids);
        building.getBuildingByCommunityManagerWithTourSchedules(ids);
        System.assertEquals(3, buildings.size(),' Number of buildings should be bigger than 3');
        System.assert(fakeBuildings.isEmpty(),'fakebuildings should not be selected');
    }

    @isTest
    static void getBuildingsByMarketsTest(){
        Market__c market = UtilMarket.createMarkets(1, true)[0];
        UtilBuilding.createBuildingWithMarket(market.Id, true);
        List<Building__c> buildings = buildSelector.getBuildingsByMarkets(new List<Id>{market.Id});
        List<Building__c> fakeBuildings = buildSelector.getBuildingsByMarkets(new List<Id>{getFakeId(Market__c.getSObjectType())});
        buildSelector.getBuildingsByMarkets(null);
        System.assertEquals(market.Id, buildings[0].Market__c,'market id should equal to building market id');
        System.assert(fakeBuildings.isEmpty(),'fakebuildings should not be selected');
    }

    @isTest
    static void getBuildingsByRegionsTest(){
        Region__c region = UtilBuilding.createRegion('Test Region Name', true);
        Territory__c territory = UtilBuilding.createTerritory('Test Territory Name', region.Id, true);
        Market__c market = UtilMarket.createMarketWithTerritory(territory.Id, true);
        UtilBuilding.createBuildingWithClusterAndTerritoryAndMarket(null, null, market.Id, true);
        List<Building__c> buildings = buildSelector.getBuildingsByRegions(new List<Id>{region.Id});
        List<Building__c> fakeBuildings = buildSelector.getBuildingsByRegions(new List<Id>{getFakeId(Region__c.getSObjectType())});
        buildSelector.getBuildingsByRegions(null);
        System.assertEquals(territory.Id, buildings[0].Market__r.TerritoryID__c,'Territory should equals to building market territory');
        System.assertEquals(region.Id, buildings[0].Market__r.TerritoryID__r.RegionID__c,'Region should equals to building market region');
        System.assert(fakeBuildings.isEmpty(),'fakebuildings should not be selected');
    }

    @isTest
    static void getBuildingsByEmailTest(){
        List<Building__c> buildings = buildSelector.getBuildingsByEmails(new List<String>{TEST_EMAIL});
        List<Building__c> fakeBuildings = buildSelector.getBuildingsByEmails(new List<String>{'fakeEmail'});
        buildSelector.getBuildingsByEmails(new Set<String>{''});
        System.assertEquals(TEST_EMAIL, buildings[0].Email__c,'Test email should equals to building email');
        System.assert(fakeBuildings.isEmpty(),'fakebuildings should not be selected');
    }

    @isTest
    static void getBuildingsByRegionNameTest(){
        List<Building__c> buildings = buildSelector.getBuildingsByRegionName(TEST_REGION_NAME);
        List<Building__c> fakeBuildings = buildSelector.getBuildingsByRegionName('fakeRegionName');
        buildSelector.getBuildingsByRegionName(null);
        System.assertEquals(TEST_REGION_NAME, buildings[0].Region_Name__c,'Test region name should equals to building region name');
        System.assert(fakeBuildings.isEmpty(),'fakebuildings should not be selected');
    }

    @isTest
    static void getBuildingsByTerritoriesTest(){
        Territory__c territory = UtilBuilding.createTerritory('Test Territory Name', null, true);
        Market__c market = UtilMarket.createMarketWithTerritory(territory.Id, true);
        UtilBuilding.createBuildingWithClusterAndTerritoryAndMarket(null, null, market.Id, true);
        List<Building__c> buildings = buildSelector.getBuildingsByTerritories(new List<Id>{territory.Id});
        List<Building__c> fakeBuildings = buildSelector.getBuildingsByTerritories(new List<Id>{getFakeId(Region__c.getSObjectType())});
        buildSelector.getBuildingsByTerritories(null);
        System.assertEquals(territory.Id, buildings[0].Market__r.TerritoryID__c,'Territory id should equals to building territory id');
        System.assert(fakeBuildings.isEmpty(),'fakebuildings should not be selected');
    }

    @isTest
    static void getBuildingsByIdTest(){
        Building__c building0 = UtilBuilding.createBuilding(null, TEST_EMAIL, null, true);
        Building__c building1 = UtilBuilding.createBuilding(null, TEST_EMAIL, null, true);
        List<Building__c> buildings0 = buildSelector.getBuildingsById(building0.Id);
        List<Building__c> buildings1 = buildSelector.getBuildingsById(new List<Id>{building0.Id, building1.Id});
        List<Building__c> fakeBuildings0 = buildSelector.getBuildingsById(getFakeId(Building__c.getSObjectType()));
        List<Building__c> fakeBuildings1 = buildSelector.getBuildingsById(new List<Id>{getFakeId(Building__c.getSObjectType()),
                                                                                                 getFakeId(Building__c.getSObjectType())});
        Id id = null;
        buildSelector.getSObjectByIds(new List<String>{'Id'}, id);
        buildSelector.getSObjectByIds(new List<String>{'Id'}, new List<Id>());
        System.assertEquals(building0.Id, buildings0[0].Id,'Building id should be retrieved');
        System.assertEquals(building0.Id, buildings1[0].Id,'Building id should be retrieved');
        System.assertEquals(building1.Id, buildings1[1].Id,'Building id should be retrieved');
        System.assert(fakeBuildings0.isEmpty(),'fakebuildings should not be selected');
        System.assert(fakeBuildings1.isEmpty(),'fakebuildings should not be selected');
    }

    @isTest
    static void getBuildingsByNameTest(){
        Building__c building0 = UtilBuilding.createBuilding(TEST_NAME0, true);
        Building__c building1 = UtilBuilding.createBuilding(TEST_NAME1, true);
        List<Building__c> buildings0 = buildSelector.getBuildingsByName(TEST_NAME0, false);
        List<Building__c> buildings1 = buildSelector.getBuildingsByName('test%', true);
        List<Building__c> buildings2 = buildSelector.getBuildingsByName(new Set<String>{TEST_NAME0, TEST_NAME1}, false);
        List<Building__c> buildings3 = buildSelector.getBuildingsByName(new List<String>{'%test%', '%name%'}, true);
        List<Building__c> fakeBuildings0 = buildSelector.getBuildingsByName('fake', false);
        List<Building__c> fakeBuildings1 = buildSelector.getBuildingsByName(new List<String>{'fake0', 'fake1'}, false);
        List<Building__c> fakeBuildings2 = buildSelector.getBuildingsByName('%fake%', true);
        List<Building__c> fakeBuildings3 = buildSelector.getBuildingsByName(new List<String>{'%fake0%', '%fake1%'}, true);
        String str = null;
        buildSelector.getBuildingsByName(str, false);
        buildSelector.getBuildingsByName(new Set<String>(), false);
        System.assertEquals(building0.Id, buildings0[0].Id,'Building id should be retrieved');
        System.assert(!buildings1.isEmpty(),'Buildings should be selected');
        System.assertEquals(building0.Id, buildings2[0].Id,'Building id should be retrieved');
        System.assertEquals(building1.Id, buildings2[1].Id,'Building id should be retrieved');
        System.assert(!buildings3.isEmpty(),'Buildings should be selected');
        System.assert(fakeBuildings0.isEmpty(),'fakebuildings should not be selected');
        System.assert(fakeBuildings1.isEmpty(),'fakebuildings should not be selected');
        System.assert(fakeBuildings2.isEmpty(),'fakebuildings should not be selected');
        System.assert(fakeBuildings3.isEmpty(),'fakebuildings should not be selected');
    }

    @isTest
    static void getBuildingsWithoutFiltersTest(){
        List<Building__c> buildings = buildSelector.getBuildingsWithoutFilters();
        System.assert(!buildings.isEmpty(),'Buildings should be selected');
    }

    private static String getFakeId(Schema.SObjectType sot){
        String result = String.valueOf(s_num++);
        return sot.getDescribe().getKeyPrefix() +
            '0'.repeat(12-result.length()) + result;
    }

    @isTest
    static void getBuildingsByKeywordWithLimitTest(){
        List<Building__c> buildings = buildSelector.getBuildingsByKeywordWithLimit('Test', 10);
        System.assert(!buildings.isEmpty(),'Buildings should be selected');
        System.assert(buildings.size() < 10,'Building size should be less than 10');
    }

    @isTest
    static void getQueryLocatorForGMTOffsetTest(){
        Set<String> dSTTimezones = new Set<String>();
        Set<String> noDSTTimezones = new Set<String>();
        dSTTimezones.add('PST');
        noDSTTimezones.add('IST');
        String query = buildSelector.getQueryLocatorForGMTOffset(dSTTimezones, noDSTTimezones);
    }

    @isTest
    static void getBuildingById(){
        OperatingHours operatingHour = new OperatingHours(Name = 'EDT: Standard 9AM - 5PM Weekday');
        insert operatingHour;
        Building__c building =New Building__c();
        building.Name ='testbuild-001';
        building.Building_ID__c ='test';
        building.UUID__c ='test';
        building.Time_Zone__c ='America/Denver';
        insert building;
        List<Building__c> buidlingById =buildSelector.getBuildingById(building.Id);
        System.assert(buidlingById !=null,'Building not retrieved');
        List<Building__c> otherBuilding =buildSelector.getBuildingById('test123');
        System.assert(otherBuilding.isEmpty(),'Building record retrieved');
    }

    @isTest
    static void getBuildingsWithoutFiltersHugeSetOfFieldsTest(){
        List<Building__c> buidlings = buildSelector.getBuildingsWithoutFiltersHugeSetOfFields();
        System.assert(!buidlings.isEmpty(),'Buildings should be selected');
    }

    @isTest
    static void getBuildingsWithLocationNoCityAndNotNullUuidTest() {
        List<Building__c> buildings = buildSelector.getBuildingsWithLocationNoCityAndNotNullUuid();
        System.assert(!buildings.isEmpty(),'Buildings should be selected');
    }

    @isTest
    static void getBuildingsByIdsFewMethodsTest() {
        Map<Id, Building__c> buildings = new Map<Id, Building__c>([SELECT Id FROM Building__c]);
        List<Building__c> buildsWithTZ = buildSelector.getBuildingsWithTimeZoneByIds(buildings.keySet());
        List<Building__c> buildsWithPB = buildSelector.getBuildingsWithPriceBookAndCurrencyByIds(buildings.keySet());
        List<Building__c> buildsWithHoursId = buildSelector.getBuildingHoursId(String.valueOf(new List<Id>(buildings.keySet())[0]));
        List<Building__c> buildsWithHoursIdList = buildSelector.getBuildingHoursIdList(new List<Id>(buildings.keySet()));
        List<Building__c> buildsWithRegAndTerr = buildSelector.getBuildingRegionAndTerritory(buildings.keySet());
        Building__c buildTourability = buildSelector.getBuildingTourabilityById(buildings.values()[0].Id);
        System.assert(!buildsWithTZ.isEmpty(),'Buildings should be selected');
        System.assert(!buildsWithPB.isEmpty(),'Buildings should be selected');
        System.assert(!buildsWithHoursId.isEmpty(),'Buildings should be selected');
        System.assert(!buildsWithHoursIdList.isEmpty(),'Buildings should be selected');
        System.assert(!buildsWithRegAndTerr.isEmpty(),'Buildings should be selected');
        System.assertNotEquals(null, buildTourability.Id, 'Building should be selected');
    }

}