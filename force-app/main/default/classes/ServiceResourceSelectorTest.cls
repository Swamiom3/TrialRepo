/*************************************************************************************************************************************
    Author      :   Pawel Biszczak
    Description :   This class provides sufficient test coverage for ServiceResourceSelector class
    --------------------------------------------------------------------------------------------------------------------------------------
    VERSION     DATE            AUTHOR            DETAIL
    1           27 Jan, 2022    Pawel Biszczak    Initial Deployment
**************************************************************************************************************************************/
@isTest
public with sharing class ServiceResourceSelectorTest {
    private static ServiceResourceSelector serviceResourceSelector = new ServiceResourceSelector();

    @testSetup
    static void makeData(){
        Map<String, Object> recordsData = new Map<String, Object>();
        recordsData.put('objName', 'User');
        recordsData.put('numberOfRecords', 1);
        List<User> users = TestingUtility.getRecords(recordsData);

        ServiceResource resource = new ServiceResource(Name = 'Resource', RelatedRecordId = users[0].Id);
        TestingUtility.insertWithAssert(resource);
    }

    @isTest
    static void shouldGetDefaultFields(){
        Set<String> fields;

        Test.startTest();
        fields = serviceResourceSelector.getDefaultFields();
        Test.stopTest();

        System.assert(!serviceResourceSelector.defaultFields.isEmpty(), 'Default fields should be presented');
    }

    @isTest
    static void shouldServiceResourceByUserId(){
        List<ServiceResource> serviceResources;
        User userForSelector;

        Test.startTest();
        userForSelector = [ SELECT Id
                            FROM User
                            WHERE LastName LIKE '%testUser 1%'
                            LIMIT 1 ];
        serviceResources = serviceResourceSelector.getServiceResourcesByUserIds(new List<Id>{ userForSelector.Id });
        Test.stopTest();

        System.assertEquals(1, serviceResources.size(), 'Should get Service Resource for provided Id');
    }

    @isTest
    static void shouldNotGetRecordsForFakeId(){
        List<ServiceResource> serviceResources;
        User userForSelector = getFakeUsers()[0];

        Test.startTest();
        serviceResources = serviceResourceSelector.getServiceResourcesByUserIds(new List<Id>{ userForSelector.Id });
        Test.stopTest();

        System.assert(serviceResources.isEmpty(), 'Should not get any ServiceResource for fake User Id');
    }

    @isTest
    static void shouldNotGetRecordsForEmptyList(){
        List<ServiceResource> serviceResources;

        Test.startTest();
        serviceResources = serviceResourceSelector.getServiceResourcesByUserIds(new List<Id>());
        Test.stopTest();

        System.assert(serviceResources.isEmpty(), 'Should not get any ServiceResource for empty list');
    }

    @isTest
    static void testGetServiceResourceWithUserById() {
        Id serviceResourceId = [SELECT Id FROM ServiceResource LIMIT 1].Id;
        ServiceResource serviceResource;

        Test.startTest();
        serviceResource = serviceResourceSelector.getServiceResourceWithUserById(serviceResourceId);
        Test.stopTest();

        System.assert(String.isNotBlank(serviceResource.RelatedRecordId), 'Should get ServiceResource related User Id');
    }

    private static List<User> getFakeUsers() {
        Map<String, Object> recordsData = new Map<String, Object>();
        recordsData = new Map<String, Object>();
        recordsData.put('objectName', 'User');
        recordsData.put('numberOfRecords', 1);
        return MockTestingUtility.getRecords(recordsData, true);
    }
}