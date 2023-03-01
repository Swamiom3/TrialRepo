/*************************************************************************************************************************************
    Author      :   Pawel Biszczak
    Description :   This class provides sufficient test coverage for ContactUpdateReferrerTypeTrH class
    --------------------------------------------------------------------------------------------------------------------------------------
    VERSION    DATE           AUTHOR             DETAIL
    1          6 Aug, 2021    Pawel Biszczak     Initial Deployment
**************************************************************************************************************************************/
@isTest
public with sharing class ContactUpdateReferrerTypeTrHTest {

    @isTest
    public static void shouldProceedWithOpportunitiesOnUpdate() {
        List<Contact> contacts = getFakeContacts(true);
        contacts[0].Type__c = 'Office Space';
        contacts[1].Type__c = 'Office Space';
        List<Contact> oldContacts = contacts.deepClone(true);
        oldContacts[0].Type__c = 'Broker';
        oldContacts[1].Type__c = 'Broker';
        Map<Id, Contact> oldContactsByIds = new Map<Id, Contact>(oldContacts);
        List<Opportunity> opportunities = getFakeOpportunities(true);
        opportunities[0].Referrer__c = contacts[0].Id;
        opportunities[1].Referrer__c = contacts[1].Id;
        opportunities[0].Referrer__r = contacts[0];
        opportunities[1].Referrer__r = contacts[1];

        ContactUpdateReferrerTypeTrH handlerInstance;
        Test.startTest();
        handlerInstance = new ContactUpdateReferrerTypeTrH(contacts, oldContactsByIds);
        handlerInstance.registerDmlConsolidator(DmlConsolidatorDefault.getInstance());
        handlerInstance.opportunitiesToUpdate = opportunities;
        handlerInstance.afterUpdate();
        Test.stopTest();

        System.assert(!handlerInstance.dml.recordsToUpdate.isEmpty(), 'Records to update should be empty on empty opportunities');
    }

    @isTest
    public static void shouldPrepareOpportunitiesForUpdate() {
        List<Contact> contacts = getFakeContacts(true);
        contacts[0].Type__c = 'Office Space';
        contacts[1].Type__c = 'Office Space';
        List<Contact> oldContacts = contacts.deepClone(true);
        oldContacts[0].Type__c = 'Broker';
        oldContacts[1].Type__c = 'Broker';
        Map<Id, Contact> oldContactsByIds = new Map<Id, Contact>(oldContacts);
        List<Opportunity> opportunities = getFakeOpportunities(true);
        opportunities[0].Referrer__c = contacts[0].Id;
        opportunities[1].Referrer__c = contacts[1].Id;
        opportunities[0].Referrer__r = contacts[0];
        opportunities[1].Referrer__r = contacts[1];

        ContactUpdateReferrerTypeTrH handlerInstance;
        Test.startTest();
        handlerInstance = new ContactUpdateReferrerTypeTrH(contacts, oldContactsByIds);
        handlerInstance.registerDmlConsolidator(DmlConsolidatorDefault.getInstance());
        handlerInstance.opportunitiesToUpdate = opportunities;
        handlerInstance.updateOpportunities();
        Test.stopTest();

        System.assert(!handlerInstance.dml.recordsToUpdate.isEmpty(), 'Records to update should be empty on empty opportunities');
    }

    @isTest
    public static void shouldProceedWithOpportunitiesOnInsert() {
        List<Contact> contacts = getFakeContacts(true);
        contacts[0].Type__c = 'Office Space';
        contacts[1].Type__c = 'Office Space';
        List<Contact> oldContacts = contacts.deepClone(true);
        oldContacts[0].Type__c = 'Broker';
        oldContacts[1].Type__c = 'Broker';
        List<Opportunity> opportunities = getFakeOpportunities(true);
        opportunities[0].Referrer__c = contacts[0].Id;
        opportunities[1].Referrer__c = contacts[1].Id;
        opportunities[0].Referrer__r = contacts[0];
        opportunities[1].Referrer__r = contacts[1];

        ContactUpdateReferrerTypeTrH handlerInstance;
        Test.startTest();
        handlerInstance = new ContactUpdateReferrerTypeTrH(contacts, null);
        handlerInstance.registerDmlConsolidator(DmlConsolidatorDefault.getInstance());
        handlerInstance.opportunitiesToUpdate = opportunities;
        handlerInstance.afterInsert();
        Test.stopTest();

        System.assert(!handlerInstance.dml.recordsToUpdate.isEmpty(), 'Records to update should be empty on empty opportunities');
    }

    @isTest
    public static void shouldPrepareOpportunity() {
        List<Contact> contacts = getFakeContacts(true);
        contacts[0].Type__c = 'Office Space';
        contacts[1].Type__c = 'Broker';
        List<Opportunity> opportunities = getFakeOpportunities(true);
        opportunities[0].Referrer__c = contacts[0].Id;
        opportunities[1].Referrer__c = contacts[1].Id;
        opportunities[0].Referrer__r = contacts[0];
        opportunities[1].Referrer__r = contacts[1];

        ContactUpdateReferrerTypeTrH handlerInstance;
        Test.startTest();
        handlerInstance = new ContactUpdateReferrerTypeTrH();
        handlerInstance.changeReferrerContactType(opportunities[0]);
        handlerInstance.changeReferrerContactType(opportunities[1]);
        Test.stopTest();

        System.assert(!handlerInstance.opportunitiesToUpdate.isEmpty(), 'Records to update should be empty on empty opportunities');
        System.assertEquals(handlerInstance.opportunitiesToUpdate[0].Referrer_Contact_Type__c, 'Office Space', 'Referrer Contact Type should be equal to Contact type');
        System.assertEquals(handlerInstance.opportunitiesToUpdate[1].Referrer_Contact_Type__c, 'Broker', 'Referrer Contact Type should be equal to Contact type');
    }

    static List<Opportunity> getFakeOpportunities(Boolean isFakeIds) {
        Map<String, Object> recordsData = new Map<String, Object>();
        recordsData = new Map<String, Object>();
        recordsData.put('objectName', 'Opportunity');
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
}