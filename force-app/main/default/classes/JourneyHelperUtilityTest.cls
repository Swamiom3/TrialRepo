/*************************************************************************************************************************************
    Author      :   Pawel Biszczak
    Description :   This class provides sufficient test coverage for JourneyHelperUtility class
    --------------------------------------------------------------------------------------------------------------------------------------
    VERSION    DATE           AUTHOR            DETAIL
    1          8 Aug, 2021    Pawel Biszczak    Initial Deployment
    2          12 Dec 2021    Pawel Biszczak    Improve test coverage, add unit tests
**************************************************************************************************************************************/
@isTest
public with sharing class JourneyHelperUtilityTest {

    @isTest
    public static void shouldProcessJourneyUpdate(){
        List<User> users = getFakeUsers();
        List<Lead> leads = getFakeLeads(true);
        List<Journey__c> journeys = getFakeJourneys(true);
        Map<Id, Map<String, SObject>> leadsIdsToParentRecords = new Map<Id, Map<String, SObject>>();
        Map<String, Map<String, Journey__c>> journeysCriteria = new Map<String, Map<String, Journey__c>>();
        Map<String, Journey__c> firstCriteria = new Map<String, Journey__c>();
        leads[0].OwnerId = users[0].Id;
        leads[1].OwnerId = users[1].Id;
        journeys[0].OwnerId = users[0].Id;
        journeys[1].OwnerId = users[0].Id;
        journeys[2].OwnerId = users[0].Id;
        journeys[3].OwnerId = users[0].Id;
        firstCriteria.put('reUse', journeys[2]);
        journeysCriteria.put(leads[1].Id, firstCriteria);
        Map<String, SObject> parents = new Map<String, SObject>();
        parents.put('lead', leads[1]);
        parents.put('newLead', leads[2]);
        leadsIdsToParentRecords.put(leads[0].Id, parents);

        Map<Id, Journey__c> journeysToUpsert = new Map<Id, Journey__c>();
        Map<Id,Id> assignments = new Map<Id,Id>();

        Test.startTest();
            System.assert(assignments.isEmpty(),'Assignments should be empty');
            JourneyHelperUtility.updateExistingJourneys(leadsIdsToParentRecords, journeysToUpsert, assignments, journeysCriteria);
        Test.stopTest();

        System.assert(!assignments.isEmpty(),'Assignments should not be empty');
        System.assert(!journeysToUpsert.isEmpty(), 'Should prepare records for parent');
    }

    @isTest
    public static void shouldProcessOnFakeJourneyCreation(){
        List<Lead> leads = getFakeLeads(false);
        List<Journey__c> journeys = getFakeJourneys(false);
        Map<String, Map<String, Journey__c>> journeysCriteria = new Map<String, Map<String, Journey__c>>();
        List<Map<String,SObject>> sobjectsToObjectTypesMap = new List<Map<String,sObject>>();
        Map<String, Journey__c> firstCriteria = new Map<String, Journey__c>();
        firstCriteria.put('reUse', journeys[2]);
        journeysCriteria.put(leads[1].Id, firstCriteria);
        leads[0].Generate_Journey__c = true;
        leads[0].Locations_Interested__c = 'TestLocation1';
        sobjectsToObjectTypesMap.add(new Map<String,SObject> { 'lead' => leads[0], 'newlead' => leads[1] });
        Integer dmlStatements = Limits.getDmlStatements();

        Test.startTest();
            JourneyHelperUtility.createJourney(sobjectsToObjectTypesMap, new List<Id>());
        Test.stopTest();

        System.assertEquals(dmlStatements, Limits.getDmlStatements(), 'Should be equal after fake journeys creation');
    }

    @isTest
    public static void shouldProcessOnPrepareFakeJourneysToUpdate(){
        initContactInfoFakeSetting();
        List<User> users = getFakeUsers();
        List<Lead> leads = getFakeLeads(false);
        List<Journey__c> journeys = getFakeJourneys(false);
        Map<String, Map<String, Journey__c>> journeysCriteria = new Map<String, Map<String, Journey__c>>();
        Map<Id, Lead> leadsToIdsMap = new Map<Id, Lead>();
        Map<String, Journey__c> firstCriteria = new Map<String, Journey__c>();
        firstCriteria.put('reUse', journeys[2]);
        journeysCriteria.put(leads[1].Id, firstCriteria);
        leads[0].Generate_Journey__c = true;
        leads[0].Locations_Interested__c = 'TestLocation1';
        journeys[0].OwnerId = users[0].Id;
        journeys[1].OwnerId = users[0].Id;
        leadsToIdsMap.put(leads[0].Id, leads[0]);
        leadsToIdsMap.put(leads[1].Id, leads[1]);
        List<Journey__c> journeysToUpdate;

        Test.startTest();
            journeysToUpdate = JourneyHelperUtility.prepareJourneys(journeys, leadsToIdsMap);
        Test.stopTest();

        System.assert(!journeysToUpdate.isEmpty(), 'Should have test records');
    }


    @isTest
    public static void shouldNotProceedWithOwnerUpdateOnFakeRecords(){
        List<Lead> leads = getFakeLeads(true);
        Map<Id, Lead> leadsToIdsMap = new Map<Id, Lead>();
        leadsToIdsMap.put(leads[0].Id, leads[0]);
        leadsToIdsMap.put(leads[1].Id, leads[1]);
        Map<Id, Journey__c> journeysToUpsert = new Map<Id, Journey__c>();
        Integer dmlStatements = Limits.getDmlStatements();

        Test.startTest();
            JourneyHelperUtility.updateJourneyOwner(leadsToIdsMap.keySet(), new List<Id>(leadsToIdsMap.keySet()));
        Test.stopTest();

        System.assertEquals(dmlStatements, Limits.getDmlStatements(), 'Should be equal after update operation');
    }

    @isTest
    public static void shouldCheckIsUniqueJourney(){
        initContactInfoFakeSetting();
        List<User> users = getFakeUsers();
        List<Lead> leads = getFakeLeads(false);
        List<Journey__c> journeys = getFakeJourneys(false);
        Map<Id, Lead> leadsToIdsMap = new Map<Id, Lead>();
        Journey__c journeyToTest = journeys.remove(0);
        journeys[0].OwnerId = users[0].Id;
        journeyToTest.OwnerId = users[0].Id;
        leadsToIdsMap.put(leads[0].Id, leads[0]);
        leadsToIdsMap.put(leads[1].Id, leads[1]);
        Map<String, Journey__c> uniquesStatusMap;

        Test.startTest();
            uniquesStatusMap = JourneyHelperUtility.checkIsUniqueJourney(journeyToTest, journeys);
        Test.stopTest();

        System.assert(!uniquesStatusMap.isEmpty(), 'Should contain uniques status');
    }

    @isTest
    public static void shouldGetProperAssigmentMode(){
        initContactInfoFakeSetting();
        List<Lead> leads = getFakeLeads(false);
        leads[0].Campaign_Id__c = getFakeCampaigns()[0].Id;
        String modeOfAssignment;

        Test.startTest();
            modeOfAssignment = JourneyHelperUtility.getJourneyModeofAssignment(leads[0]);
        Test.stopTest();

        System.assert(String.isNotBlank(modeOfAssignment), 'Should get proper mode');
    }

    @isTest
    public static void shouldGetNoAssigmentMode(){
        List<Lead> leads = getFakeLeads(false);
        String modeOfAssignment;

        Test.startTest();
            modeOfAssignment = JourneyHelperUtility.getJourneyModeofAssignment(leads[0]);
        Test.stopTest();

        System.assert(String.isBlank(modeOfAssignment), 'Should not get any mode');
    }

    @isTest
    public static void shouldNotProcessJourneyUpdate(){
        initContactInfoFakeSetting();
        List<Lead> leads = getFakeLeads(true);
        List<Journey__c> journeys = getFakeJourneys(true);
        Map<Id, Map<String, SObject>> leadsIdsToParentRecords = new Map<Id, Map<String, SObject>>();
        Map<String, Map<String, Journey__c>> journeysCriteria = new Map<String, Map<String, Journey__c>>();
        Map<String, Journey__c> firstCriteria = new Map<String, Journey__c>();
        firstCriteria.put('reUse', journeys[2]);
        journeysCriteria.put(leads[1].Id, firstCriteria);

        Map<Id, Journey__c> journeysToUpsert = new Map<Id, Journey__c>();
        Map<Id,Id> assignments = new Map<Id,Id>();

        Test.startTest();
        JourneyHelperUtility.updateExistingJourneys(leadsIdsToParentRecords, journeysToUpsert, assignments, journeysCriteria);
        Test.stopTest();

        System.assert(assignments.isEmpty(),'Assignments should be empty');
        System.assert(journeysToUpsert.isEmpty(), 'Should have no records');
    }

    static List<Lead> getFakeLeads(Boolean generateFakeIds) {
        Map<String, Object> recordsData = new Map<String, Object>();
        recordsData = new Map<String, Object>();
        recordsData.put('objectName', 'Lead');
        recordsData.put('numberOfRecords', 3);
        return MockTestingUtility.getRecords(recordsData, generateFakeIds);
    }

    static List<Journey__c> getFakeJourneys(Boolean generateFakeIds) {
        Map<String, Object> recordsData = new Map<String, Object>();
        recordsData = new Map<String, Object>();
        recordsData.put('objectName', 'Journey__c');
        recordsData.put('numberOfRecords', 4);
        return MockTestingUtility.getRecords(recordsData, generateFakeIds);
    }

    static List<Campaign> getFakeCampaigns() {
        Map<String, Object> recordsData = new Map<String, Object>();
        recordsData = new Map<String, Object>();
        recordsData.put('objectName', 'Campaign');
        recordsData.put('numberOfRecords', 1);
        return MockTestingUtility.getRecords(recordsData, true);
    }

    private static List<User> getFakeUsers() {
        Map<String, Object> recordsData = new Map<String, Object>();
        recordsData = new Map<String, Object>();
        recordsData.put('objectName', 'User');
        recordsData.put('numberOfRecords', 2);
        return MockTestingUtility.getRecords(recordsData, true);
    }

    private static void initContactInfoFakeSetting(){
        Sales_Console_Setting__mdt triggersSetting = new Sales_Console_Setting__mdt();
        triggersSetting.DeveloperName = 'APIUserContactInfo';
        triggersSetting.Data__c = getContactInfoFakeData();
    }

    private static String getContactInfoFakeData(){
        return '{"ContactId":"003F0000000000",\n' +
                '"ContactUUID":"1231313131-12312-1234-1234-123123123123",\n' +
                '"Email":"test123@wework.com",\n'+
                '"Name":"Test Test",\n' +
                '"UserId":"005F00000000000"}';
    }
}