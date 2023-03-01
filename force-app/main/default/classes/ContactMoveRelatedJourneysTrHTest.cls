/*************************************************************************************************************************************
    Author      :   Pawel Biszczak
    Description :   This class provides sufficient test coverage for ContactMoveRelatedJourneysTrH class
    --------------------------------------------------------------------------------------------------------------------------------------
    VERSION    DATE           AUTHOR             DETAIL
    1          6 Aug, 2021    Pawel Biszczak     Initial Deployment
**************************************************************************************************************************************/
@isTest
public with sharing class ContactMoveRelatedJourneysTrHTest {

    @isTest
    public static void shouldReturnEmptyList(){
        List<Journey__c> journeys = new List<Journey__c>();
        List<Journey__c> journeysToUpdate;

        ContactMoveRelatedJourneysTrH handlerInstance;
        Test.startTest();
        handlerInstance = new ContactMoveRelatedJourneysTrH();
        journeysToUpdate = handlerInstance.getJourneysForUpdatePrimaryContactAndLead(journeys);
        Test.stopTest();

        System.assert(journeysToUpdate.isEmpty(), 'Should return empty list');
    }

    @isTest
    public static void shouldUpdateJourneysWithDML(){
       // SalesConsoleSettings.createSettings();
        List<Contact> contacts = getFakeContacts(false);
        contacts[0].LastName = 'Test Name 1';
        contacts[0].Email = 'test1@weworkexample.com';
        List<Lead> leads = getFakeLeads(false);
        leads[0].Email = 'test1@weworkexample.com';
        leads[0].Phone = '123456789';
        leads[0].LastName = 'Test Name';
        leads[0].Company = 'Test Company';
        insert leads;
        List<Journey__c> journeys = new List<Journey__c>{getFakeJourneys(false)[0]};
        journeys[0].Primary_Email__c = 'test1@weworkexample.com';
        journeys[0].Primary_Lead__c = leads[0].Id;
        journeys[0].NMD_Next_Contact_Date__c = System.today();
        insert journeys;
        List<Journey__c> journeysAfterUpdate;
        ContactMoveRelatedJourneysTrH handlerInstance;

        Test.startTest();
        handlerInstance = new ContactMoveRelatedJourneysTrH(contacts);
        handlerInstance.registerDmlConsolidator(DmlConsolidatorDefault.getInstance());
        handlerInstance.afterInsert();
        journeysAfterUpdate = [SELECT Id, Primary_Contact__c
                               FROM Journey__c];
        Test.stopTest();

        System.assert(!journeysAfterUpdate.isEmpty(), 'Records after update should not be empty');
        System.assertEquals(journeysAfterUpdate[0].Primary_Contact__c, contacts[0].Id, 'Primary Contact should be properly assigned');
    }

    @isTest
    public static void shouldUpdateJourneysOnMockedSelector(){
        List<Contact> contacts = getFakeContacts(false);
        contacts[0].LastName = 'Test Name 1';
        contacts[1].LastName = 'Test Name 2';
        contacts[2].LastName = 'Test Name 3';
        contacts[3].LastName = 'Test Name 4';
        contacts[0].Email = 'test1@weworkexample.com';
        contacts[1].Email = 'test2@weworkexample.com';
        contacts[2].Email = 'test3@weworkexample.com';
        contacts[3].Email = 'test4@weworkexample.com';
        List<Journey__c> journeys = getFakeJourneys(false);
        journeys[0].Primary_Email__c = 'test1@weworkexample.com';
        journeys[1].Primary_Email__c = 'test2@weworkexample.com';
        journeys[2].Primary_Email__c = 'test3@weworkexample.com';
        journeys[3].Primary_Email__c = 'test4@weworkexample.com';

        ContactMoveRelatedJourneysTrH handlerInstance;
        Test.startTest();
        handlerInstance = new ContactMoveRelatedJourneysTrH(contacts);
        handlerInstance.registerDmlConsolidator(DmlConsolidatorDefault.getInstance());
        handlerInstance.journeySelector = (JourneySelector) MockService.createMock(
                JourneySelector.class,
                new Map<String, Object>{
                        'getJourneysByPrimaryEmailsWhenPrimaryLeadPresented' => journeys});
        handlerInstance.afterInsert();
        Test.stopTest();

        System.assert(!handlerInstance.dml.recordsToUpdate.isEmpty(), 'Records to update should not be empty');
    }

    @isTest
    public static void shouldPrepareJourneysToUpdate(){
        List<Contact> contacts = getFakeContacts(true);
        contacts[0].LastName = 'Test Name 1';
        contacts[1].LastName = 'Test Name 2';
        contacts[2].LastName = 'Test Name 3';
        contacts[3].LastName = 'Test Name 4';
        contacts[0].Email = 'test1@weworkexample.com';
        contacts[1].Email = 'test2@weworkexample.com';
        contacts[2].Email = 'test3@weworkexample.com';
        contacts[3].Email = 'test4@weworkexample.com';
        List<Journey__c> journeys = getFakeJourneys(true);
        journeys[0].Primary_Email__c = 'test1@weworkexample.com';
        journeys[1].Primary_Email__c = 'test2@weworkexample.com';
        journeys[2].Primary_Email__c = 'test3@weworkexample.com';
        journeys[3].Primary_Email__c = 'test4@weworkexample.com';
        List<Journey__c> journeysToUpdate;

        ContactMoveRelatedJourneysTrH handlerInstance;
        Test.startTest();
        handlerInstance = new ContactMoveRelatedJourneysTrH(contacts);
        handlerInstance.journeySelector = (JourneySelector) MockService.createMock(
                JourneySelector.class,
                new Map<String, Object>{
                        'getJourneysByPrimaryEmailsWhenPrimaryLeadPresented' => journeys});
        journeysToUpdate = handlerInstance.moveRelatedJourneys();
        Test.stopTest();

        System.assert(!journeysToUpdate.isEmpty(), 'Should prepare map for contacts');
    }

    @isTest
    public static void shouldPrepareJourneysToUpdatePrimaryContact(){
        List<Contact> contacts = getFakeContacts(true);
        contacts[0].LastName = 'Test Name 1';
        contacts[1].LastName = 'Test Name 2';
        contacts[2].LastName = 'Test Name 3';
        contacts[3].LastName = 'Test Name 4';
        contacts[0].Email = 'test1@weworkexample.com';
        contacts[1].Email = 'test2@weworkexample.com';
        contacts[2].Email = 'test3@weworkexample.com';
        contacts[3].Email = 'test4@weworkexample.com';
        List<Journey__c> journeys = getFakeJourneys(true);
        journeys[0].Primary_Email__c = 'test1@weworkexample.com';
        journeys[1].Primary_Email__c = 'test2@weworkexample.com';
        journeys[2].Primary_Email__c = 'test3@weworkexample.com';
        journeys[3].Primary_Email__c = 'test4@weworkexample.com';
        List<Journey__c> journeysToUpdate;

        ContactMoveRelatedJourneysTrH handlerInstance;
        Test.startTest();
        handlerInstance = new ContactMoveRelatedJourneysTrH(contacts);
        handlerInstance.getEmailToContactsByPrimaryEmails();
        System.assert(!handlerInstance.emailToContact.isEmpty(), 'Should prepare map for contacts');
        journeysToUpdate = handlerInstance.getJourneysForUpdatePrimaryContactAndLead(journeys);
        Test.stopTest();

        System.assert(!journeysToUpdate.isEmpty(), 'Should prepare map for contacts');
    }

    @isTest
    public static void shouldPrepareEmailToContactMap(){
        List<Contact> contacts = getFakeContacts(true);
        contacts[0].LastName = 'Test Name 1';
        contacts[1].LastName = 'Test Name 2';
        contacts[2].LastName = 'Test Name 3';
        contacts[3].LastName = 'Test Name 4';
        contacts[0].Email = 'test1@weworkexample.com';
        contacts[1].Email = 'test2@weworkexample.com';
        contacts[2].Email = 'test3@weworkexample.com';
        contacts[3].Email = 'test4@weworkexample.com';

        ContactMoveRelatedJourneysTrH handlerInstance;
        Test.startTest();
        handlerInstance = new ContactMoveRelatedJourneysTrH(contacts);
        handlerInstance.getEmailToContactsByPrimaryEmails();
        Test.stopTest();

        System.assert(!handlerInstance.emailToContact.isEmpty(), 'Should prepare map for contacts');
    }

    static List<Journey__c> getFakeJourneys(Boolean isFakeIds) {
        Map<String, Object> recordsData = new Map<String, Object>();
        recordsData = new Map<String, Object>();
        recordsData.put('objectName', 'Journey__c');
        recordsData.put('numberOfRecords', 4);
        return MockTestingUtility.getRecords(recordsData, isFakeIds);
    }

    static List<Contact> getFakeContacts(Boolean isFakeIds) {
        Map<String, Object> recordsData = new Map<String, Object>();
        recordsData = new Map<String, Object>();
        recordsData.put('objectName', 'Contact');
        recordsData.put('numberOfRecords', 4);
        return MockTestingUtility.getRecords(recordsData, isFakeIds);
    }

    static List<Lead> getFakeLeads(Boolean isFakeIds) {
        Map<String, Object> recordsData = new Map<String, Object>();
        recordsData = new Map<String, Object>();
        recordsData.put('objectName', 'Lead');
        recordsData.put('numberOfRecords', 1);
        return MockTestingUtility.getRecords(recordsData, isFakeIds);
    }
}