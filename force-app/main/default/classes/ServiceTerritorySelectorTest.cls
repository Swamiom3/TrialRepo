/*************************************************************************************************************************************
Author      :   Salesforce
Description :   This class provides sufficient test coverage for ServiceTerritorySelector class
--------------------------------------------------------------------------------------------------------------------------------------
VERSION         DATE            AUTHOR            DETAIL
1               29 Oct, 2021    Salesforce        Initial Deployment
2               27 Jan, 2022    Pawel Biszczak    Initial Deployment
**************************************************************************************************************************************/
@isTest
public class ServiceTerritorySelectorTest {
    private static ServiceTerritorySelector serviceTerritorySelector = new ServiceTerritorySelector();

    @testSetup
    static void setup() {
        List<Building__c> buildings =
                (List<Building__c>) TestingUtility.getRecords(
                        new Map<String, Object>{
                                'objName' => 'Building__c',
                                'UUID__c'  => 'testUUID',
                                'numberOfRecords' => 1
                        });
        OperatingHours operatingHour = new OperatingHours(Name = 'EDT: Standard 9AM - 5PM Weekday');
        insert operatingHour;
        insert new ServiceTerritory(Building_Id__c = buildings[0].Id,
                                    Name = buildings[0].Name,
                                    OperatingHoursId = operatingHour.Id,
                                    IsActive = true);
    }

    @isTest
    static void shouldGetDefaultFields(){
        Set<String> fields;

        Test.startTest();
        fields = serviceTerritorySelector.getDefaultFields();
        Test.stopTest();

        System.assert(!serviceTerritorySelector.defaultFields.isEmpty(), 'Default fields should be presented');
    }

    @isTest
    static void shouldGetServiceTerritoryByBuildingId() {
        Building__c building = [SELECT Id FROM Building__c LIMIT 1];
        List<ServiceTerritory> serviceTerritories;

        Test.startTest();
        serviceTerritories = serviceTerritorySelector.getServiceTerritoriesByBuilding(building.Id);
        Test.stopTest();

        System.assert(!serviceTerritories.isEmpty(), 'Service Territories should be retrieved successfully');
    }

    @isTest
    static void shouldGetServiceTerritoryByIds() {
        ServiceTerritory territory = [SELECT Id FROM ServiceTerritory LIMIT 1];
        List<ServiceTerritory> serviceTerritories;

        Test.startTest();
        serviceTerritories = serviceTerritorySelector.getServiceTerritoryByIds(new List<Id>{ territory.Id });
        Test.stopTest();

        System.assert(!serviceTerritories.isEmpty(), 'Service Territories should be retrieved successfully');
    }

    @isTest
    static void shouldNotGetServiceTerritoryByIds() {
        Building__c building = [SELECT Id FROM Building__c LIMIT 1];
        List<ServiceTerritory> serviceTerritoriesNegative;
        List<ServiceTerritory> serviceTerritoriesEmpty;

        Test.startTest();
        serviceTerritoriesNegative = serviceTerritorySelector.getServiceTerritoryByIds(new List<Id>{ building.Id });
        serviceTerritoriesEmpty = serviceTerritorySelector.getServiceTerritoryByIds(new List<Id>());
        Test.stopTest();

        System.assert(serviceTerritoriesNegative.isEmpty(), 'Service Territories should be not retrieved');
        System.assert(serviceTerritoriesEmpty.isEmpty(), 'Service Territories should be not retrieved');
    }

    @isTest
    static void getActiveServiceTerritoryByBuildingUUIDTest() {
        Building__c building = [SELECT Id, UUID__c FROM Building__c LIMIT 1];
        ServiceTerritory territory = [SELECT Id FROM ServiceTerritory LIMIT 1];

        Test.startTest();
        List<ServiceTerritory> serviceTerritories = serviceTerritorySelector.getActiveServiceTerritoryByBuildingUUID(new List<String> { building.UUID__c });
        List<ServiceTerritory> serviceTerritoriesNegative = serviceTerritorySelector.getActiveServiceTerritoryByBuildingUUID(new List<String> { territory.Id });
        List<ServiceTerritory> serviceTerritoriesEmpty = serviceTerritorySelector.getActiveServiceTerritoryByBuildingUUID(new List<String> { '' });
        Test.stopTest();

        System.assert(!serviceTerritories.isEmpty(), 'Service Territories should be retrieved successfully');
        System.assert(serviceTerritoriesNegative.isEmpty(), 'Service Territories retrieved');
        System.assert(serviceTerritoriesEmpty.isEmpty(), 'Service Territories retrieved');
    }
}