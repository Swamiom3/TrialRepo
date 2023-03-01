/*************************************************************************************************************************************
    Author      :   Pawel Biszczak
    Description :   This class provides sufficient test coverage for ContactSelector class
    --------------------------------------------------------------------------------------------------------------------------------------
    VERSION    DATE            AUTHOR             DETAIL
    1          13 Apr, 2021    Pawel Biszczak     Initial Deployment
**************************************************************************************************************************************/
@isTest
public with sharing class ContactSelectorTest {
    private static ContactSelector contactSelector = new ContactSelector();

    @TestSetup
    static void makeData(){

        Map<String, Object> recordsData = new Map<String, Object>();
        recordsData = new Map<String, Object>();
        recordsData.put('objName', 'Contact');
        recordsData.put('numberOfRecords', 2);
        recordsData.put('doInsert', false);
        recordsData.put('lstEmails', new List<String> { 'testContact1@test.com', 'testContact2@test.com' });
        List<Contact> contacts = TestingUtility.getRecords(recordsData);

        contacts[0].UUID__c = '12345';
        contacts[1].UUID__c = '123456';
        contacts[0].Company__c = 'test Comapany';
        contacts[1].Company__c = 'test Comapany';
        TestingUtility.insertListWithAssert(contacts);
    }
    
    @isTest
    static void shouldGetContactsByUUIDs(){
        List<Contact> contacts;

        Test.startTest();
        contacts = contactSelector.getContactsByUUIDs(new List<String>{'12345'});
        Test.stopTest();

        System.assertEquals(1, contacts.size(), 'Should get 1 contact');
    }

    @isTest
    static void shouldGetFieldsByMultipleIds(){
        List<Contact> contacts;

        Test.startTest();
        Contact onlyContact = [SELECT Id
                               FROM Contact
                               LIMIT 1];
        contacts = contactSelector.getContactsByIdAndNotNullEmail(new List<Id>{ onlyContact.Id });
        Test.stopTest();

        System.assertNotEquals(null, contacts[0].UUID__c, 'Field should be retrieved');
        System.assertNotEquals(null, contacts[0].Email, 'Field should be not null');
        System.assertEquals(onlyContact.Id, contacts[0].Id, 'Should have same value');
    }

    @isTest
    static void testGetContactsByIds() {
        Contact contact = [SELECT Id FROM Contact LIMIT 1];
        Test.startTest();
        List<Contact> resContacts = contactSelector.getContactsByIds(new Set<Id>{ contact.Id});
        Test.stopTest();
        System.assertEquals(contact.Id, resContacts[0].Id, 'Id field should have same value');
    }

    @isTest
    static void shouldGetPersonFieldsByMultipleIds(){
        List<Contact> contacts;

        Test.startTest();
        Contact onlyContact = [SELECT Id
                               FROM Contact
                               LIMIT 1];
        contacts = contactSelector.getContactsWithPersonFieldsByIds(new List<Id>{ onlyContact.Id });
        Test.stopTest();

        System.assertNotEquals(null, contacts[0].UUID__c, 'Field should be retrieved');
        System.assertNotEquals(null, contacts[0].Email, 'Field should be not null');
        System.assertNotEquals(null, contacts[0].Company__c, 'Field should be not null');
        System.assertEquals(onlyContact.Id, contacts[0].Id, 'Should have same value');
    }

    @isTest
    static void shouldGetPersonFieldsByMultipleEmails(){
        List<Contact> contacts;

        Test.startTest();
        contacts = contactSelector.getContactsWithPersonFieldsByEmails(new List<String>{ 'testContact1@test.com', 'testContact2@test.com' });
        Test.stopTest();

        System.assertEquals(2, contacts.size(), '2 records should be retrieved');
        System.assertNotEquals(null, contacts[0].UUID__c, 'Field should be retrieved');
        System.assertNotEquals(null, contacts[0].Email, 'Field should be not null');
        System.assertNotEquals(null, contacts[0].Company__c, 'Field should be retrieved');
    }
}