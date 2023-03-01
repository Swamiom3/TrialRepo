/*************************************************************************************************************************************
    Author      :   Pawel Biszczak
    Description :   This class provides sufficient test coverage for ContactRestrictOverrideFieldsTrH class
    --------------------------------------------------------------------------------------------------------------------------------------
    VERSION    DATE            AUTHOR            DETAIL
    1          19 Jan, 2022    Pawel Biszczak    Initial Deployment
**************************************************************************************************************************************/
@isTest
public with sharing class ContactRestrictOverrideFieldsTrHTest {

    private static final String FIELD_TO_TEST_NAME = 'FirstName';

    @isTest
    public static void shouldGetRestrictedValuesFromMedata(){
        ContactRestrictOverrideFieldsTrH handlerInstance;

        Test.startTest();
        handlerInstance = new ContactRestrictOverrideFieldsTrH();
        Test.stopTest();

        System.assert(!handlerInstance.restrictedFields.isEmpty(), 'Should contain restricted fields');
    }

    @isTest
    public static void shouldNotOverrideRestrictedField(){
        ContactRestrictOverrideFieldsTrH handlerInstance;
        List<Contact> contacts = getFakeContacts(true);
        contacts[0].FirstName = 'Test One';
        contacts[1].FirstName = 'Test Two';
        List<Contact> contactsBeforeUpdate = contacts.deepClone(true);
        contactsBeforeUpdate[0].FirstName = null;
        contactsBeforeUpdate[1].FirstName = 'Test Two Updated';
        contactsBeforeUpdate[2].FirstName = 'Test Threse Updated';
        Map<Id, Contact> contactsBeforeUpdateMap = new Map<Id, Contact>(contactsBeforeUpdate);
        
        Test.startTest();
        handlerInstance = new ContactRestrictOverrideFieldsTrH();
        handlerInstance.restrictedFields = new List<String>{ FIELD_TO_TEST_NAME };
        handlerInstance.newContacts = contacts;
        handlerInstance.oldContactsMap = contactsBeforeUpdateMap;
        handlerInstance.restrictOverrideFields();
        Test.stopTest();
        
        System.assertNotEquals(handlerInstance.newContacts[0].FirstName, contactsBeforeUpdate[0].FirstName,
                               'Should allow to override on old null value');
        System.assertEquals(handlerInstance.newContacts[1].FirstName, contactsBeforeUpdate[1].FirstName,
                            'Value should remain not overridden');
        System.assertEquals(handlerInstance.newContacts[2].FirstName, contactsBeforeUpdate[2].FirstName,
                            'Value should remain not overridden');
    }

    @isTest
    public static void shouldOverrideNonRestrictedField(){
        ContactRestrictOverrideFieldsTrH handlerInstance;
        List<Contact> contacts = getFakeContacts(true);
        contacts[0].LastName = 'Test One';
        contacts[1].LastName = 'Test Two';
        List<Contact> contactsBeforeUpdate = contacts.deepClone(true);
        contactsBeforeUpdate[0].LastName = null;
        contactsBeforeUpdate[1].LastName = 'Test Two Updated';
        contactsBeforeUpdate[2].LastName = 'Test Three Updated';
        Map<Id, Contact> contactsBeforeUpdateMap = new Map<Id, Contact>(contactsBeforeUpdate);

        Test.startTest();
        handlerInstance = new ContactRestrictOverrideFieldsTrH();
        handlerInstance.restrictedFields = new List<String>{ FIELD_TO_TEST_NAME };
        handlerInstance.newContacts = contacts;
        handlerInstance.oldContactsMap = contactsBeforeUpdateMap;
        handlerInstance.restrictOverrideFields();
        Test.stopTest();

        System.assertNotEquals(handlerInstance.newContacts[0].LastName, contactsBeforeUpdate[0].LastName,
                               'Should allow to override field not presented in restricted fields');
        System.assertNotEquals(handlerInstance.newContacts[1].LastName, contactsBeforeUpdate[1].LastName,
                               'Should allow to override field not presented in restricted fields');
        System.assertNotEquals(handlerInstance.newContacts[2].LastName, contactsBeforeUpdate[2].LastName,
                               'Should allow to override field not presented in restricted fields');
    }

    
    @isTest
    public static void restrictLocationChangeFoContactWithinIdRailsTest(){
        Contact oldCon = new Contact();
        oldCon.Id = TestUtility.getFakeId(Contact.getSObjectType());
        oldCon.Location__c = TestUtility.getFakeId(Building__c.getSObjectType());
        oldCon.exists_in_id__c = true;

        Contact newCon = oldCon.clone(true, true, false, false);
        newCon.Location__c = TestUtility.getFakeId(Building__c.getSObjectType());

        Test.startTest();
        ContactRestrictOverrideFieldsTrH handlerInstance;
        handlerInstance = new ContactRestrictOverrideFieldsTrH();
        handlerInstance.newContacts = new List<Contact>{newCon};
        handlerInstance.oldContactsMap = new Map<Id, Contact>(new List<Contact>{oldCon});
        handlerInstance.restrictLocationChangeFoContactWithinIdRails();
        Test.stopTest();

        System.assertEquals(oldCon.Location__c, newCon.Location__c, 'Building should not be changed.');
    }
    
    @isTest
    public static void shouldvalidateMergeLeadSourceAsId(){
        ContactRestrictOverrideFieldsTrH handlerInstance;

        Account account = new Account();
        account.Name = 'Test Account feature';
        insert account;
        
        List<Contact> contacts = new List<Contact>();        
        Contact Con = new Contact();
        Con.FirstName = 'Test';
        Con.LastName = 'contact';
        Con.Email = 'testcontact@wework.com';
        Con.LeadSource = 'Id';
        Con.Account = account;
        contacts.add(Con);
        insert contacts;

        Map<Id, Contact> oldContactsByIds = new Map<Id, Contact>();
        oldContactsByIds.putAll(new Map<Id, Contact>(contacts));
        
        Test.startTest();
        Lead lead = new Lead();
        lead.FirstName = 'Test';
        lead.LastName = 'Lead';
        lead.Email = Con.Email;
        lead.Company = 'XYZ';
        lead.LeadSource = 'Event';
        lead.LeadSource_Sub_Type__c = 'Broker';
        lead.Lead_Source_Detail__c = 'Test';
        insert lead;
        handlerInstance = new ContactRestrictOverrideFieldsTrH(contacts, oldContactsByIds);
        handlerInstance.validateMergeLeadSourceAsId();
        Test.stopTest();
        
        System.assertEquals(handlerInstance.newContacts[0].LeadSource_Sub_Type__c, null, 'LeadSource Sub Type should not be overwritten');
        System.assertNotEquals(handlerInstance.newContacts[0].Lead_Source_Detail__c, 'Test', 'LeadSource Detail should not be overwritten');
    }

    static List<Contact> getFakeContacts(Boolean isFakeIds) {
        Map<String, Object> recordsData = new Map<String, Object>();
        recordsData = new Map<String, Object>();
        recordsData.put('objectName', 'Contact');
        recordsData.put('numberOfRecords', 3);
        return MockTestingUtility.getRecords(recordsData, isFakeIds);
    }
}