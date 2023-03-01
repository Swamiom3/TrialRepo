/**
 * @description unit tests for the trac_Location and trac_LocationHandler classes
 * @name trac_LocationTest
 * @author Daniel Labonte, Traction on Demand
 * @date 2019-07-30
 */

@IsTest
public with sharing class trac_LocationTest {
    static final TLTestFactory factory = new TLTestFactory();
    static final Long NOW = Datetime.now().getTime();

    static final String REGION_NAME = 'Region';
    static final String TERRITORY_NAME= 'Territory';
    static final String BUILDING_1_NAME = 'building1';

    @TestSetup
    static void setup() {
        Location__c region = (Location__c) factory.createSObject(new Location__c(Name = REGION_NAME, RecordTypeId = trac_LocationConstants.RTID_REGION),true);
        Location__c territory = (Location__c) factory.createSObject(new Location__c(Name = TERRITORY_NAME, Region__c = region.Id,RecordTypeId = trac_LocationConstants.RTID_TERRITORY),true);
        factory.createSObject(new Location__c(Name = BUILDING_1_NAME, Territory__c = territory.Id,RecordTypeId = trac_LocationConstants.RTID_BUILDING),true);
    }


    @IsTest
    static void testHierarchyPopulation() {
        final Integer NUM_FLOORS_BUILDING_1 = 3;
        final Integer NUM_FLOORS_BUILDING_2 = 3;

        Location__c region = [SELECT Id FROM Location__c WHERE Name = :REGION_NAME];
        Location__c territory = [SELECT Id FROM Location__c WHERE Name = :TERRITORY_NAME];
        Location__c building1 = (Location__c) factory.createSObject(new Location__c(Name = NOW + 'Building1', Territory__c = territory.Id, RecordTypeId = trac_LocationConstants.RTID_BUILDING), false);
        Location__c building2 = (Location__c) factory.createSObject(new Location__c(Name = NOW + 'Building2', Territory__c = territory.Id, RecordTypeId = trac_LocationConstants.RTID_BUILDING), false);

        Test.startTest();
        insert new List<Location__c>{
                building1, building2
        };
        List<Location__c> floorsBuilding1 = (List<Location__c>) factory.createSObjects(new Location__c(Building__c = building1.Id, RecordTypeId = trac_LocationConstants.RTID_FLOOR), NUM_FLOORS_BUILDING_1, false);
        List<Location__c> floorsBuilding2 = (List<Location__c>) factory.createSObjects(new Location__c(Building__c = building2.Id, RecordTypeId = trac_LocationConstants.RTID_FLOOR), NUM_FLOORS_BUILDING_2, false);
        List<Location__c> allFloors = new List<Location__c>();
        allFloors.addAll(floorsBuilding1);
        allFloors.addAll(floorsBuilding2);
        insert allFloors;
        Test.stopTest();

        List<Location__c> allInsertedFloors = [SELECT Id, Region__c,Territory__c,Building__c FROM Location__c WHERE Region__c = :region.Id AND RecordTypeId = :trac_LocationConstants.RTID_FLOOR];
        System.assertEquals((NUM_FLOORS_BUILDING_1 + NUM_FLOORS_BUILDING_2), allInsertedFloors.size(), 'The floors were not properly inserted');
    }

    @IsTest
    static void testQueueGeneration() {
        Location__c region = (Location__c) factory.createSObject(new Location__c(Name = NOW + 'Eastern Canada', RecordTypeId = trac_LocationConstants.RTID_REGION),false);

        Test.startTest();
        insert region;
        Test.stopTest();

        List<Location_Queue__c> locationQueues = [SELECT Id, Name, Queue_Label__c, Queue_Developer_Name__c FROM Location_Queue__c WHERE Location__c = :region.Id];
        System.assert(locationQueues.size() > 0, 'No location queue records were generated');
    }

    @IsTest
    static void testInsertManyLocations() {
        final Integer NUM_RECORDS = 50;
        List<Location__c> locations = (List<Location__c>) factory.createSObjects(new Location__c(Name = NOW + 'Eastern Canada', RecordTypeId = trac_LocationConstants.RTID_REGION),NUM_RECORDS,false);

        Test.startTest();
        insert locations;
        Test.stopTest();

        List<Location_Queue__c> locationQueues = [SELECT Id, Name, Queue_Label__c, Queue_Developer_Name__c FROM Location_Queue__c WHERE Location__c = :(new Map<Id,Location__c>(locations).keySet())];
        System.assert(locationQueues.size() > NUM_RECORDS, 'No location queue records were generated');
    }

    @IsTest
    static void testQueueGenerationIntegrationUser() {
        User integrationUser = TLTestUtils.createUsers('System API', 1, true)[0];

        Location__c region = (Location__c) factory.createSObject(new Location__c(Name = NOW + 'Eastern Canada', RecordTypeId = trac_LocationConstants.RTID_REGION), false);

        Test.startTest();
        System.runAs(integrationUser) {
            insert region;
        }
        Test.stopTest();

        List<Location_Queue__c> locationQueues = [SELECT Id, Name, Queue_Label__c, Queue_Developer_Name__c FROM Location_Queue__c WHERE Location__c = :region.Id];
        System.assert(locationQueues.size() > 0, 'No location queue records were generated');
    }

    @IsTest
    static void testQueueUpdateIntegrationUser() {
        User integrationUser = TLTestUtils.createUsers('System API', 1, true)[0];

        Location__c region = (Location__c) factory.createSObject(new Location__c(Name = NOW + 'Eastern Canada', RecordTypeId = trac_LocationConstants.RTID_REGION), true);

        Test.startTest();
        System.runAs(integrationUser) {
            update new Location__c(Id = region.Id, Name = 'NEW NAME');
        }
        Test.stopTest();

        List<Location_Queue__c> lqs = [SELECT Id, Name, Queue_Label__c, Queue_Developer_Name__c, Queue_Id__c FROM Location_Queue__c WHERE Location__c = :region.Id];
        Set<String> queueIds = TLList.collectStrings(lqs,Location_Queue__c.Queue_Id__c);

        System.debug(JSON.serializePretty([SELECT Id, Name FROM Location__c WHERE Id = :region.Id]));
        System.debug(JSON.serializePretty(lqs));
        System.debug(JSON.serializePretty([SELECT Id, Name, DeveloperName FROM Group WHERE Id IN :queueIds]));


        List<Location_Queue__c> locationQueues = [SELECT Id, Name, Queue_Label__c, Queue_Developer_Name__c FROM Location_Queue__c WHERE Location__c = :region.Id];
        System.assert(locationQueues.size() > 0, 'No location queue records were generated');
    }

    @IsTest
    static void testNewTerritoryNoParent() {
        Location__c territory = (Location__c) factory.createSObject(new Location__c(Name = NOW + 'Test Territory', RecordTypeId = trac_LocationConstants.RTID_TERRITORY),false);

        Test.startTest();
        insert territory;
        Test.stopTest();

        Location__c insertedTerritory = [SELECT Id, Name, Region__r.Name FROM Location__c WHERE Id = :territory.Id];
        System.assert(insertedTerritory.Region__r.Name != null, 'The region was not set');
    }

    @IsTest
    static void testNewPortfolioNoParent() {
        Location__c portfolio = (Location__c) factory.createSObject(new Location__c(Name = NOW + 'Test Building', RecordTypeId = trac_LocationConstants.RTID_PORTFOLIO),false);

        Test.startTest();
        insert portfolio;
        Test.stopTest();

        Location__c insertedPortfolio = [SELECT Id, Name, Region__r.Name, Territory__r.Name FROM Location__c WHERE Id = :portfolio.Id];
        System.assert(insertedPortfolio.Region__r.Name != null, 'The region was not set');
        System.assert(insertedPortfolio.Territory__r.Name != null, 'The territory was not set');
    }

    @IsTest
    static void testNewBuildingNoParent() {
        Location__c building = (Location__c) factory.createSObject(new Location__c(Name = NOW + 'Test Building', RecordTypeId = trac_LocationConstants.RTID_BUILDING),false);

        Test.startTest();
        insert building;
        Test.stopTest();

        Location__c insertedBuilding = [SELECT Id, Name, Region__r.Name, Territory__r.Name FROM Location__c WHERE Id = :building.Id];
        System.assert(insertedBuilding.Region__r.Name != null, 'The region was not set');
        System.assert(insertedBuilding.Territory__r.Name != null, 'The territory was not set');
    }

    @IsTest
    static void testUpdateLocation() {
        Location__c building = [SELECT Id, Name FROM Location__c WHERE Name = :BUILDING_1_NAME];
        building.Name = 'New Building Name';

        Test.startTest();
        update building;
        Test.stopTest();


        List<Location_Queue__c> locationQueues = [SELECT Id, Name, Queue_Label__c, Queue_Developer_Name__c FROM Location_Queue__c WHERE Location__c = :building.Id];
        System.assert(locationQueues.size() > 0, 'No location queue records were generated');
    }

    @IsTest
    static void testUpdateLocationNameAndRecordType() {
        Location__c building = [SELECT Id, Name FROM Location__c WHERE Name = :BUILDING_1_NAME];
        building.Name = 'New Building Name';

        Test.startTest();
        update building;

        System.debug([SELECT Id, Queue_Prefix__c FROM Location_Queue__c WHERE Location__c = :building.Id]);

        building.Name = 'Psych Im a Territory';
        building.Territory__c = null;
        building.RecordTypeId= trac_LocationConstants.RTID_TERRITORY;

        update building;

        System.debug([SELECT Id, Queue_Prefix__c FROM Location_Queue__c WHERE Location__c = :building.Id]);
        Test.stopTest();


        List<Location_Queue__c> locationQueues = [SELECT Id, Name, Queue_Label__c, Queue_Developer_Name__c FROM Location_Queue__c WHERE Location__c = :building.Id];
        System.assert(locationQueues.size() > 0, 'No location queue records were generated');
    }

}