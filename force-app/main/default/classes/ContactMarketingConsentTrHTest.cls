/*************************************************************************************************************************************
    Author      :   Pawel Biszczak
    Description :   This class provides sufficient test coverage for ContactMarketingConsentTrH class
    --------------------------------------------------------------------------------------------------------------------------------------
    VERSION    DATE           AUTHOR             DETAIL
    1          6 Aug, 2021    Pawel Biszczak     Initial Deployment
**************************************************************************************************************************************/
@isTest
public with sharing class ContactMarketingConsentTrHTest {

    @isTest
    public static void shouldSetMarketingConsentOnUpdate(){
        List<Contact> contacts = getFakeContacts(true);
        ContactMarketingConsentTrH handlerInstance = new ContactMarketingConsentTrH();
        Contact contactToSerialize;
        contacts[1].Contact_Broker__c = true;
        contactToSerialize = contacts[1];
        Map<String, Object> contactToDeserialize = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(contactToSerialize));
        contactToDeserialize.put('LastModifiedById', handlerInstance.BIG_MARKER_INTEGRATION_USER_ID);
        contacts[1] = (Contact) JSON.deserialize(
                JSON.serialize(contactToDeserialize),
                Contact.class
        );
        contactToSerialize = contacts[2];
        contactToDeserialize = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(contactToSerialize));
        contactToDeserialize.put('LastModifiedById', handlerInstance.BIG_MARKER_INTEGRATION_USER_ID);
        contacts[2] = (Contact) JSON.deserialize(
                JSON.serialize(contactToDeserialize),
                Contact.class
        );
        List<Contact> oldContacts = contacts.deepClone(true);

        Map<Id, Contact> oldContactsByIds = new Map<Id, Contact>();
        oldContactsByIds.putAll(new Map<Id, Contact>(oldContacts));

        Test.startTest();
        handlerInstance = new ContactMarketingConsentTrH(contacts, oldContactsByIds);
        handlerInstance.beforeUpdate();
        Test.stopTest();

        System.assert(!handlerInstance.newContacts[0].HasOptedOutOfEmail,
                      'Should set HasOptedOutOfEmail to false for the first record when no Integration User Id presented');
        System.assert(!handlerInstance.newContacts[1].HasOptedOutOfEmail,
                      'Should set HasOptedOutOfEmail to false for the second record  when Contact_Broker__c set to true');
        System.assert(handlerInstance.newContacts[2].HasOptedOutOfEmail,
                      'Should set HasOptedOutOfEmail to true for the third record when all values are correct');
    }

    @isTest
    public static void shouldSetMarketingConsentOnInsert(){
        List<Contact> contacts = getFakeContacts(true);
        ContactMarketingConsentTrH handlerInstance = new ContactMarketingConsentTrH();
        contacts[0].LeadSource = handlerInstance.WEWORK_CN;
        contacts[1].LeadSource = 'Test Source';
        contacts[0].Marketing_Consent__c = true;
        contacts[1].Marketing_Consent__c = true;
        Contact contactToSerialize;
        contactToSerialize = contacts[2];
        Map<String, Object> contactToDeserialize = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(contactToSerialize));
        contactToDeserialize.put('LastModifiedById', handlerInstance.BIG_MARKER_INTEGRATION_USER_ID);
        contacts[2] = (Contact) JSON.deserialize(
                JSON.serialize(contactToDeserialize),
                Contact.class
        );
        Test.startTest();
        handlerInstance = new ContactMarketingConsentTrH(contacts, null);
        handlerInstance.beforeInsert();
        Test.stopTest();

        System.assert(handlerInstance.newContacts[0].SMS_Opt_In__c,
                      'Should set SMS_OPT_In__c to true for the first record when LeadSource equals to WeWork_CN');
        System.assert(!handlerInstance.newContacts[1].SMS_Opt_In__c,
                      'Should set SMS_OPT_In__c to false for the second record on fake LeadSource');
        System.assert(handlerInstance.newContacts[2].HasOptedOutOfEmail,
                      'Should set HasOptedOutOfEmail to true for the third record on proper LastModifiedById');
    }

    @isTest
    public static void shouldNotSetDncAndDneForUnpopulatedFieldsOnInsert(){
        List<Contact> contacts = getFakeContacts(true);
        ContactMarketingConsentTrH handlerInstance = new ContactMarketingConsentTrH();
        contacts[0].LeadSource = 'Test Source';
        contacts[1].LeadSource = 'Test Source';
        contacts[0].Marketing_Consent__c = false;
        contacts[1].Marketing_Consent__c = false;

        Test.startTest();
        handlerInstance = new ContactMarketingConsentTrH(contacts, null);
        handlerInstance.beforeInsert();
        Test.stopTest();

        System.assert(!handlerInstance.newContacts[0].SMS_Opt_In__c,
                      'Should set SMS_OPT_In__c to false for the first record on fake LeadSource');
        System.assert(!handlerInstance.newContacts[1].SMS_Opt_In__c,
                      'Should set SMS_OPT_In__c to false for the second record on fake LeadSource');
        System.assert(!handlerInstance.newContacts[2].HasOptedOutOfEmail,
                      'Should set HasOptedOutOfEmail to false for the third record on empty fields');
    }

    @isTest
    public static void shouldNotSetDncAndDneForUnpopulatedFieldsOnUpdate(){
        List<Contact> contacts = getFakeContacts(true);
        contacts[0].LeadSource = 'Test Source';
        contacts[1].LeadSource = 'Test Source';
        contacts[0].Marketing_Consent__c = false;
        contacts[1].Marketing_Consent__c = false;
        ContactMarketingConsentTrH handlerInstance = new ContactMarketingConsentTrH();
        List<Contact> oldContacts = contacts.deepClone(true);
        Map<Id, Contact> oldContactsByIds = new Map<Id, Contact>();
        oldContactsByIds.putAll(new Map<Id, Contact>(oldContacts));

        Test.startTest();
        handlerInstance = new ContactMarketingConsentTrH(contacts, oldContactsByIds);
        handlerInstance.beforeInsert();
        Test.stopTest();

        System.assert(!handlerInstance.newContacts[0].SMS_Opt_In__c,
                      'Should set SMS_OPT_In__c to false for the first record on fake LeadSource');
        System.assert(!handlerInstance.newContacts[1].SMS_Opt_In__c,
                      'Should set SMS_OPT_In__c to false for the second record on fake LeadSource');
        System.assert(!handlerInstance.newContacts[2].HasOptedOutOfEmail,
                      'Should set HasOptedOutOfEmail to false for the third record on empty fields');
    }

    static List<Contact> getFakeContacts(Boolean isFakeIds) {
        Map<String, Object> recordsData = new Map<String, Object>();
        recordsData = new Map<String, Object>();
        recordsData.put('objectName', 'Contact');
        recordsData.put('numberOfRecords', 4);
        return MockTestingUtility.getRecords(recordsData, isFakeIds);
    }

    @isTest
    public static void testOptoutForDomains() {
        List<Contact> testContacts = getFakeContacts(true);
        Contact testContact1 = testContacts[0];
        testContact1.Email = 'testContact1@testDomain.com';
        testContact1.LeadSource = 'Id';
        testContact1.HasOptedOutOfEmail = null;
        testContact1.Marketing_Consent__c = null;

        Contact testContact2 = testContacts[1];
        testContact2.Email = 'testContact2@testDomain.com.invalid';
        testContact2.LeadSource = 'Id';
        testContact2.HasOptedOutOfEmail = null;
        testContact2.Marketing_Consent__c = null;

        Contact testContact3 = testContacts[2];
        testContact3.Email = 'testContact3@testDomain.com.invalid';
        testContact3.LeadSource = 'Other';
        testContact3.HasOptedOutOfEmail = null;
        testContact3.Marketing_Consent__c = null;

        Contact testContact4 = testContacts[3];
        testContact4.Email = 'testContact3@otherDomain.com';
        testContact4.LeadSource = 'Id';
        testContact4.HasOptedOutOfEmail = null;
        testContact4.Marketing_Consent__c = null;

        ContactMarketingConsentTrH concensentTrH = new ContactMarketingConsentTrH(testContacts, null);
        concensentTrH.OPT_OUT_DOMAINS = new Set<string>{'testDomain.com'};

        System.assertEquals('testDomain.com', concensentTrH.getDomainFromEmail(testContact1), 'Domains shuuld be equal');

        System.assertEquals(true, concensentTrH.isValidContactLeadSourceForOptOutDomainCheck(testContact1), 
                            'contact has valid lead source for domain check');
        System.assertEquals(false, concensentTrH.isValidContactLeadSourceForOptOutDomainCheck(testContact3), 
                            'contact has invalid lead source for domain check');
        System.assertEquals(true, concensentTrH.isValidContactEmailDomainForOptOutDomainCheck(testContact1), 
                            'contact has valid email for domain check');
        System.assertEquals(true, concensentTrH.isValidContactEmailDomainForOptOutDomainCheck(testContact2), 
                            'contact has valid email for domain check');
        System.assertEquals(false, concensentTrH.isValidContactEmailDomainForOptOutDomainCheck(testContact4), 
                            'contact has invalid email for domain check');

        concensentTrH.updateOptOutForPartnerDomainContact(testContact1);
        System.assertEquals(true, testContact1.HasOptedOutOfEmail, 'opt out is true');
        System.assertEquals(false, testContact1.Marketing_Consent__c, 'marketing consent is false');

        //restore marketing and optout to null
        testContact1.HasOptedOutOfEmail = null;
        testContact1.Marketing_Consent__c = null;

        Test.startTest();
        concensentTrH.beforeInsert();
        Test.stopTest();

        //positive scenario
        System.assertEquals(true, testContact1.HasOptedOutOfEmail, 'Optput is true');
        System.assertEquals(false, testContact1.Marketing_Consent__c, 'Marketing_Consent__c is false');
        System.assertEquals(true, testContact2.HasOptedOutOfEmail, 'Optput is true');
        System.assertEquals(false, testContact2.Marketing_Consent__c, 'Marketing_Consent__c is false');

        //negative scenario
        System.assert(testContact3.Marketing_Consent__c == null || testContact3.Marketing_Consent__c == false, 'Marketing_Consent__c is not set');
        System.assert(testContact4.Marketing_Consent__c == null || testContact4.Marketing_Consent__c == false, 'Marketing_Consent__c is not set');
    }
}