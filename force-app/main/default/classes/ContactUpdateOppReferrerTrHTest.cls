/*************************************************************************************************************************************
    Author      :   Pawel Biszczak
    Description :   This class provides sufficient test coverage for ContactUpdateOppReferrerTrH class
    --------------------------------------------------------------------------------------------------------------------------------------
    VERSION    DATE           AUTHOR             DETAIL
    1          6 Aug, 2021    Pawel Biszczak     Initial Deployment
**************************************************************************************************************************************/
@isTest
public with sharing class ContactUpdateOppReferrerTrHTest {

    @isTest
    public static void shouldTryToUpdateOpportunityReferrerOnUpdate(){
        List<Contact> contacts = getFakeContacts(true);
        List<Account> accounts = getFakeAccounts(true);
        contacts[0].AccountId = accounts[0].Id;
        contacts[1].AccountId = accounts[1].Id;
        List<Contact> oldContacts = contacts.deepClone(true);
        Map<Id, Contact> oldContactsByIds = new Map<Id, Contact>(oldContacts);
        Map<Id, Contact> newContactsByIds = new Map<Id, Contact>(contacts);

        ContactUpdateOppReferrerTrH handlerInstance;
        Test.startTest();
        handlerInstance = new ContactUpdateOppReferrerTrH(contacts, newContactsByIds, oldContactsByIds);
        handlerInstance.registerDmlConsolidator(DmlConsolidatorDefault.getInstance());
        handlerInstance.afterUpdate();
        Test.stopTest();

        System.assert(handlerInstance.dml.recordsToUpdate.isEmpty(), 'Records to update should be empty on empty opportunities');
    }

    @isTest
    public static void shouldPrepareOpportunityForUpdate() {
        List<Contact> contacts = getFakeContacts(true);
        List<Opportunity> opportunities = getFakeOpportunities(true);
        List<Account> accounts = getFakeAccounts(true);
        contacts[0].AccountId = accounts[0].Id;
        contacts[1].AccountId = accounts[1].Id;
        List<Contact> oldContacts = contacts.deepClone(true);
        opportunities[0].Referrer_Account__c = accounts[1].Id;
        opportunities[1].Referrer_Account__c = accounts[0].Id;
        opportunities[0].Referrer__c = contacts[0].Id;
        opportunities[1].Referrer__c = contacts[1].Id;
        Map<Id, Contact> oldContactsByIds = new Map<Id, Contact>(oldContacts);
        Map<Id, Contact> newContactsByIds = new Map<Id, Contact>(contacts);

        ContactUpdateOppReferrerTrH handlerInstance;
        Test.startTest();
        handlerInstance = new ContactUpdateOppReferrerTrH(contacts, newContactsByIds, oldContactsByIds);
        handlerInstance.registerDmlConsolidator(DmlConsolidatorDefault.getInstance());
        handlerInstance.checkReferrerAccountAndPrepareOpportunityForUpdate(opportunities[0]);
        handlerInstance.checkReferrerAccountAndPrepareOpportunityForUpdate(opportunities[1]);
        handlerInstance.updateOpportunities();
        Test.stopTest();

        System.assert(!handlerInstance.dml.recordsToUpdate.isEmpty(), 'Records to update should not be empty');
    }

    @isTest
    public static void shouldPrepareOpportunitiesForDMLConsolidator(){
        List<Contact> contacts = getFakeContacts(true);
        List<Opportunity> opportunities = getFakeOpportunities(true);
        List<Account> accounts = getFakeAccounts(true);
        contacts[0].AccountId = accounts[0].Id;
        contacts[1].AccountId = accounts[1].Id;
        opportunities[0].Referrer_Account__c = accounts[1].Id;
        opportunities[1].Referrer_Account__c = accounts[0].Id;
        opportunities[0].Referrer__c = contacts[0].Id;
        opportunities[1].Referrer__c = contacts[1].Id;
        Map<Id, Contact> newContactsByIds = new Map<Id, Contact>(contacts);

        ContactUpdateOppReferrerTrH handlerInstance;

        Test.startTest();
        handlerInstance = new ContactUpdateOppReferrerTrH();
        handlerInstance.opportunitiesToUpdate = opportunities;
        handlerInstance.newContactsMap = newContactsByIds;
        handlerInstance.registerDmlConsolidator(DmlConsolidatorDefault.getInstance());
        handlerInstance.updateOpportunities();
        Test.stopTest();

        System.assert(!handlerInstance.dml.recordsToUpdate.isEmpty(), 'Records to update should not be empty');
        System.assert(String.isNotBlank((String) handlerInstance.dml.recordsToUpdate.values()[0].get('Referrer_Account__c')), 'Referrer Account should not be null');
    }

    static List<Account> getFakeAccounts(Boolean isFakeIds) {
        Map<String, Object> recordsData = new Map<String, Object>();
        recordsData = new Map<String, Object>();
        recordsData.put('objectName', 'Account');
        recordsData.put('numberOfRecords', 4);
        return MockTestingUtility.getRecords(recordsData, isFakeIds);
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