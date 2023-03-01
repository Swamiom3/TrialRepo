/*************************************************************************************************************************************
    Author      :   Pawel Biszczak
    Description :   This class provides sufficient test coverage for OperatingHoursSelector class
    --------------------------------------------------------------------------------------------------------------------------------------
    VERSION     DATE            AUTHOR            DETAIL
    1           28 Jan, 2022    Pawel Biszczak    Initial Deployment
**************************************************************************************************************************************/
@isTest
public without sharing class OperatingHoursSelectorTest {
    private static OperatingHoursSelector operatingHoursSelector = new OperatingHoursSelector();

    @testSetup
    static void makeData(){
        Map<String, Object> recordsData = new Map<String, Object>();
        recordsData.put('objName', 'User');
        recordsData.put('numberOfRecords', 1);
        List<User> users = TestingUtility.getRecords(recordsData);
        recordsData = new Map<String, Object>();
        recordsData.put('objName', 'Building__c');
        recordsData.put('numberOfRecords', 1);
        List<Building__c> buildings =  TestingUtility.getRecords(recordsData);

        ServiceResource resource = new ServiceResource(Name = 'Resource', RelatedRecordId = users[0].Id);
        TestingUtility.insertWithAssert(resource);

        OperatingHours hoursWithHost = new OperatingHours(Name = 'EDT: Standard 9AM - 5PM Weekday');
        hoursWithHost.Building_Id__c = buildings[0].Id;
        hoursWithHost.Host_Id__c = resource.Id;
        OperatingHours hoursWithoutHost = new OperatingHours(Name = 'EDT: Standard 9AM - 5PM Weekday');
        hoursWithoutHost.Building_Id__c = buildings[0].Id;
        TestingUtility.insertListWithAssert(new List<OperatingHours>{ hoursWithHost, hoursWithoutHost });
    }

    @isTest
    static void shouldGetDefaultFields(){
        Set<String> fields;

        Test.startTest();
        fields = operatingHoursSelector.getDefaultFields();
        Test.stopTest();

        System.assert(!operatingHoursSelector.defaultFields.isEmpty(), 'Default fields should be presented');
    }

    @isTest
    static void shouldOperatingHoursByBuildingId(){
        List<OperatingHours> hours;
        Building__c buildingForSelector;

        Test.startTest();
        buildingForSelector = [ SELECT Id
                                FROM Building__c
                                LIMIT 1 ];
        hours = operatingHoursSelector.getBuildingOperatingHours(buildingForSelector.Id);
        Test.stopTest();

        System.assert(!hours.isEmpty(), 'Should get OperatingHours for provided Id');
    }

    @isTest
    static void shouldNotGetRecordsForFakeId(){
        List<OperatingHours> hours;
        Building__c buildingForSelector = getFakeBuildings()[0];

        Test.startTest();
        hours = operatingHoursSelector.getBuildingOperatingHours(buildingForSelector.Id);
        Test.stopTest();

        System.assert(hours.isEmpty(), 'Should not get any OperatingHours for fake Building Id');
    }

    @isTest
    static void shouldNotGetRecordsForBlankId(){
        List<OperatingHours> hours;
        Building__c buildingForSelector = new Building__c();

        Test.startTest();
        hours = operatingHoursSelector.getBuildingOperatingHours(buildingForSelector.Id);
        Test.stopTest();

        System.assert(hours.isEmpty(), 'Should not get any OperatingHours for blank Building Id');
    }

    private static List<Building__c> getFakeBuildings() {
        Map<String, Object> recordsData = new Map<String, Object>();
        recordsData = new Map<String, Object>();
        recordsData.put('objectName', 'Building__c');
        recordsData.put('numberOfRecords', 1);
        return MockTestingUtility.getRecords(recordsData, true);
    }
}