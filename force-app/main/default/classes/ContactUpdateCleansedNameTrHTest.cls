/*************************************************************************************************************************************
    Author      :   Pawel Biszczak
    Description :   This class provides sufficient test coverage for ContactUpdateCleansedNameTrH class
    --------------------------------------------------------------------------------------------------------------------------------------
    VERSION    DATE            AUTHOR            DETAIL
    1          19 Jan, 2022    Pawel Biszczak    Initial Deployment
**************************************************************************************************************************************/
@isTest
public with sharing class ContactUpdateCleansedNameTrHTest {

    @isTest
    public static void shouldUpdateCleansedName(){
        List<Contact> contacts = getFakeContacts(true);
        ContactUpdateCleansedNameTrH handlerInstance;
        Contact contactToSerialize;
        List<Contact> contactsWithFields = new List<Contact>();
        contactToSerialize = contacts[0];
        Map<String, Object> contactToDeserialize =
                (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(contactToSerialize));
        contactToDeserialize.put('Company__c', 'Test Company');
        contactsWithFields.add((Contact) JSON.deserialize(
                JSON.serialize(contactToDeserialize),
                Contact.class
        ));
        contacts[1].FirstName = 'Test First Name';
        contacts[1].LastName = 'Test Last Name';
        contactsWithFields.add(contacts[1]);
        contactToSerialize = contacts[2];
        contactToDeserialize = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(contactToSerialize));
        contactToDeserialize.put('Account_Name__c', 'Test Account Name');
        contactsWithFields.add((Contact) JSON.deserialize(
                JSON.serialize(contactToDeserialize),
                Contact.class
        ));

        Test.startTest();
        handlerInstance = new ContactUpdateCleansedNameTrH(contactsWithFields);
        handlerInstance.updateCleansedName();
        Test.stopTest();

        System.assertNotEquals(handlerInstance.newContacts[0].Cleansed_Company_Name__c, null,
                               'Should be not null when Company__c provided');
        System.assertNotEquals(handlerInstance.newContacts[1].Cleansed_Company_Name__c, null,
                               'Should be not null when FirstName and LastName provided');
        System.assertNotEquals(handlerInstance.newContacts[2].Cleansed_Company_Name__c, null,
                               'Should be not null when Account_Name__c provided');
        System.assertEquals(handlerInstance.newContacts.size(), 3, 'Should contain 3 records');
    }

    @isTest
    public static void shouldNotUpdateCleansedName(){
        List<Contact> contacts = getFakeContacts(true);
        ContactUpdateCleansedNameTrH handlerInstance;

        Test.startTest();
        handlerInstance = new ContactUpdateCleansedNameTrH(contacts);
        handlerInstance.updateCleansedName();
        Test.stopTest();

        System.assertEquals(handlerInstance.newContacts[0].Cleansed_Company_Name__c, null,
                            'Should remain null for empty fields');
        System.assertEquals(handlerInstance.newContacts[1].Cleansed_Company_Name__c, null,
                            'Should remain null for empty fields');
        System.assertEquals(handlerInstance.newContacts[2].Cleansed_Company_Name__c, null,
                            'Should remain null for empty fields');
        System.assertEquals(handlerInstance.newContacts.size(), 3, 'Should contain 3 records');
    }

    @isTest
    public static void shouldUpdateCleansedNameOnTriggerHandlerMethods() {
        List<Contact> contacts = getFakeContacts(true);
        ContactUpdateCleansedNameTrH handlerInstance;
        Contact contactToSerialize;
        List<Contact> contactsWithFields = new List<Contact>();
        contactToSerialize = contacts[0];
        Map<String, Object> contactToDeserialize =
                (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(contactToSerialize));
        contactToDeserialize.put('Company__c', 'Test Company');
        contactsWithFields.add((Contact) JSON.deserialize(
                JSON.serialize(contactToDeserialize),
                Contact.class
        ));

        Test.startTest();
        handlerInstance = new ContactUpdateCleansedNameTrH();
        handlerInstance.newContacts = contactsWithFields.deepClone();
        handlerInstance.beforeInsert();
        System.assertNotEquals(handlerInstance.newContacts[0].Cleansed_Company_Name__c, null,
                               'Should be not null when Company__c provided');
        handlerInstance.newContacts = contactsWithFields.deepClone();
        handlerInstance.beforeUpdate();
        System.assertNotEquals(handlerInstance.newContacts[0].Cleansed_Company_Name__c, null,
                               'Should be not null when Company__c provided');
        Test.stopTest();
    }

    static List<Contact> getFakeContacts(Boolean isFakeIds) {
        Map<String, Object> recordsData = new Map<String, Object>();
        recordsData = new Map<String, Object>();
        recordsData.put('objectName', 'Contact');
        recordsData.put('numberOfRecords', 3);
        return MockTestingUtility.getRecords(recordsData, isFakeIds);
    }
}