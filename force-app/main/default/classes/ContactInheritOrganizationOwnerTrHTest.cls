/*************************************************************************************************************************************
    Author      :   Pawel Biszczak
    Description :   This class provides sufficient test coverage for ContactInheritOrganizationOwnerTrH class
    --------------------------------------------------------------------------------------------------------------------------------------
    VERSION    DATE            AUTHOR             DETAIL
    1          18 Mar, 2022    Pawel Biszczak     Initial Deployment
**************************************************************************************************************************************/
@isTest
public with sharing class ContactInheritOrganizationOwnerTrHTest {

    @isTest
    public static void shouldInitOrganizationOwner(){
        List<Contact> contacts = getFakeContacts();
        List<User> users = getFakeUsers();
        Contact contactToSerialize;
        ContactInheritOrganizationOwnerTrH handlerInstance;
        contacts[0].LeadSource = GlobalConstants.CONTACT_LEAD_SOURCE_OUT_EMAIL_COLD_CALL;
        contacts[1].LeadSource = 'Website';
        contacts[2].LeadSource = GlobalConstants.CONTACT_LEAD_SOURCE_OUT_EMAIL_COLD_CALL;

        contacts[0].Lead_Source_Detail__c = 'Website';
        contacts[1].Lead_Source_Detail__c = null;
        contacts[2].Lead_Source_Detail__c = GlobalConstants.UNOMY;

        contactToSerialize = contacts[0];
        List<Contact> contactsWithFields = new List<Contact>();
        Map<String, Object> contactToDeserialize = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(contactToSerialize));
        contactToDeserialize.put('Account_Owner__c', users[0].Id);
        contactsWithFields.add((Contact) JSON.deserialize(
                JSON.serialize(contactToDeserialize),
                Contact.class
        ));
        contactToSerialize = contacts[1];
        contactToDeserialize = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(contactToSerialize));
        contactToDeserialize.put('Account_Owner__c', users[0].Id);
        contactsWithFields.add((Contact) JSON.deserialize(
                JSON.serialize(contactToDeserialize),
                Contact.class
        ));
        contactToSerialize = contacts[2];
        contactToDeserialize = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(contactToSerialize));
        contactToDeserialize.put('Account_Owner__c', users[0].Id);
        contactsWithFields.add((Contact) JSON.deserialize(
                JSON.serialize(contactToDeserialize),
                Contact.class
        ));
        contactsWithFields.add(contacts[3]);
        UserUtility.idToUser.put(users[0].Id, users[0]);

        Test.startTest();
        handlerInstance = new ContactInheritOrganizationOwnerTrH();
        handlerInstance.newContacts = contactsWithFields;
        handlerInstance.inheritOrganizationOwner();
        Test.stopTest();

        System.assertEquals(users[0].Id, handlerInstance.newContacts[0].OwnerId, 'Should be equal to the Account Owner (Organization)');
        System.assertEquals(users[0].Id, handlerInstance.newContacts[1].OwnerId, 'Should be equal to the Account Owner (Organization)');
        System.assertEquals(null, handlerInstance.newContacts[2].OwnerId, 'Should be equal to null on Unomy Lead Source Detail');
        System.assertEquals(null, handlerInstance.newContacts[3].OwnerId, 'Should be equal to null on missing data');
    }

    @isTest
    public static void shouldCheckIsLeadSourceValid(){
        List<Contact> contacts = getFakeContacts();
        ContactInheritOrganizationOwnerTrH handlerInstance;
        contacts[0].LeadSource = 'New Test Source';
        contacts[1].LeadSource = 'Test Source';
        contacts[2].LeadSource = GlobalConstants.CONTACT_LEAD_SOURCE_OUT_EMAIL_COLD_CALL;
        contacts[0].Lead_Source_Detail__c = 'New Test Source';
        contacts[1].Lead_Source_Detail__c = null;
        contacts[2].Lead_Source_Detail__c = GlobalConstants.UNOMY;

        Test.startTest();
        handlerInstance = new ContactInheritOrganizationOwnerTrH();
        handlerInstance.newContacts = contacts;

        System.assert(handlerInstance.isLeadSourceValid(contacts[0].LeadSource, contacts[0].Lead_Source_Detail__c),
                'Should return true for not matching lead source values');
        System.assert(handlerInstance.isLeadSourceValid(contacts[1].LeadSource, contacts[1].Lead_Source_Detail__c),
                'Should return true for blank field');
        System.assert(!handlerInstance.isLeadSourceValid(contacts[2].LeadSource, contacts[2].Lead_Source_Detail__c),
                'Should return false for matching lead source values');
        Test.stopTest();
    }

    static List<Contact> getFakeContacts() {
        Map<String, Object> recordsData = new Map<String, Object>();
        recordsData = new Map<String, Object>();
        recordsData.put('objectName', 'Contact');
        recordsData.put('numberOfRecords', 4);
        return MockTestingUtility.getRecords(recordsData, true);
    }

    static List<User> getFakeUsers() {
        Map<String, Object> recordsData = new Map<String, Object>();
        recordsData = new Map<String, Object>();
        recordsData.put('objectName', 'User');
        recordsData.put('numberOfRecords', 1);
        return MockTestingUtility.getRecords(recordsData, true);
    }
}