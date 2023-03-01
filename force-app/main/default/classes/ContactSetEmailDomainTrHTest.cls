/*************************************************************************************************************************************
    Author      :   Pawel Biszczak
    Description :   This class provides sufficient test coverage for ContactSetEmailDomainTrH class
    --------------------------------------------------------------------------------------------------------------------------------------
    VERSION    DATE           AUTHOR             DETAIL
    1          6 Aug, 2021    Pawel Biszczak     Initial Deployment
**************************************************************************************************************************************/
@isTest
public with sharing class ContactSetEmailDomainTrHTest {
    private static final String EMAIL_DOMAIN_TO_TEST = 'weworkexample.com';
    private static final String AT_SYMBOL = '@';

    @isTest
    public static void shouldSetEmailDomainsOnUpdate(){
        List<Contact> contacts = getFakeContacts(true);
        contacts[0].LastName = 'Test Name 1';
        contacts[1].LastName = 'Test Name 2';
        contacts[2].LastName = 'Test Name 3';
        contacts[3].LastName = 'Test Name 4';
        contacts[0].Email = 'test1' + AT_SYMBOL + EMAIL_DOMAIN_TO_TEST;
        contacts[3].Email = 'test4' + AT_SYMBOL + EMAIL_DOMAIN_TO_TEST;
        List<Contact> oldContacts = contacts.deepClone(true);
        contacts[0].Email = 'test0' + AT_SYMBOL + EMAIL_DOMAIN_TO_TEST;
        contacts[3].Email = 'test4' + AT_SYMBOL + EMAIL_DOMAIN_TO_TEST;
        Map<Id, Contact> oldContactsByIds = new Map<Id, Contact>();
        oldContactsByIds.putAll(new Map<Id, Contact>(oldContacts));

        ContactSetEmailDomainTrH handlerInstance;
        Test.startTest();
        handlerInstance = new ContactSetEmailDomainTrH(contacts, oldContactsByIds);
        handlerInstance.beforeUpdate();
        Test.stopTest();

        System.assertEquals(handlerInstance.newContacts[0].Email_Domain_Text__c, EMAIL_DOMAIN_TO_TEST,
                            'Should contain proper domain text');
        System.assertEquals(handlerInstance.newContacts[3].Email_Domain_Text__c, null,
                            'Email_Domain_Text__c should be null as the email was not changed');
        System.assertEquals(handlerInstance.newContacts[1].Email_Domain_Text__c, null,
                            'Email_Domain_Text__c should be null');
        System.assertEquals(handlerInstance.newContacts[2].Email_Domain_Text__c, null,
                            'Email_Domain_Text__c should be null');
        System.assert(!handlerInstance.newContacts[0].Email_Domain_Text__c.contains(AT_SYMBOL),
                      'Should not contain \'at\' symbol');
    }

    @isTest
    public static void shouldSetEmailDomainsOnInsert(){
        List<Contact> contacts = getFakeContacts(true);
        contacts[0].LastName = 'Test Name 1';
        contacts[1].LastName = 'Test Name 2';
        contacts[2].LastName = 'Test Name 3';
        contacts[3].LastName = 'Test Name 4';
        contacts[0].Email = 'test1' + AT_SYMBOL + EMAIL_DOMAIN_TO_TEST;
        contacts[3].Email = 'test4' + AT_SYMBOL + EMAIL_DOMAIN_TO_TEST;

        ContactSetEmailDomainTrH handlerInstance;
        Test.startTest();
        handlerInstance = new ContactSetEmailDomainTrH(contacts, null);
        handlerInstance.beforeInsert();
        Test.stopTest();

        System.assertEquals(handlerInstance.newContacts[0].Email_Domain_Text__c, EMAIL_DOMAIN_TO_TEST,
                            'Should contain proper domain text');
        System.assertEquals(handlerInstance.newContacts[3].Email_Domain_Text__c, EMAIL_DOMAIN_TO_TEST,
                            'Should contain proper domain text');
        System.assertEquals(handlerInstance.newContacts[1].Email_Domain_Text__c, null,
                            'Email_Domain_Text__c should be null');
        System.assertEquals(handlerInstance.newContacts[2].Email_Domain_Text__c, null,
                            'Email_Domain_Text__c should be null');
        System.assert(!handlerInstance.newContacts[0].Email_Domain_Text__c.contains(AT_SYMBOL),
                      'Should not contain \'at\' symbol');
    }

    @isTest
    public static void shouldProceedWithEmptyList(){
        List<Contact> contactsAfterExecution;

        Test.startTest();
        ContactSetEmailDomainTrH handlerInstance = new ContactSetEmailDomainTrH();
        handlerInstance.newContacts = new List<Contact>();
        handlerInstance.beforeInsert();
        contactsAfterExecution = handlerInstance.newContacts;
        Test.stopTest();

        System.assertNotEquals(contactsAfterExecution, null, 'Should properly assign the variable after execution');
        System.assert(contactsAfterExecution.isEmpty(), 'List should remain empty');
    }

    static List<Contact> getFakeContacts(Boolean isFakeIds) {
        Map<String, Object> recordsData = new Map<String, Object>();
        recordsData = new Map<String, Object>();
        recordsData.put('objectName', 'Contact');
        recordsData.put('numberOfRecords', 4);
        return MockTestingUtility.getRecords(recordsData, isFakeIds);
    }
}