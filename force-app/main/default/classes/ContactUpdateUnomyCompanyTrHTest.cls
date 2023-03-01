/*************************************************************************************************************************************
    Author      :   Pawel Biszczak
    Description :   This class provides sufficient test coverage for ContactUpdateUnomyCompanyTrH class
    --------------------------------------------------------------------------------------------------------------------------------------
    VERSION    DATE           AUTHOR             DETAIL
    1          6 Aug, 2021    Pawel Biszczak     Initial Deployment
**************************************************************************************************************************************/
@isTest
public with sharing class ContactUpdateUnomyCompanyTrHTest {

    @isTest
    public static void shouldPrepareCICompanyDataForContacts() {
        List<Account> accounts = getFakeAccounts(true);
        List<CI_Company__c> ciCompanies = getFakeCICompanies(true);
        List<Contact> contacts = getFakeContacts(true);
        contacts[0].AccountId = accounts[0].Id;
        contacts[1].AccountId = accounts[1].Id;
        contacts[2].AccountId = accounts[2].Id;
        contacts[2].CI_Company__c = ciCompanies[2].Id;
        accounts[0].CI_Company__c = ciCompanies[0].Id;
        accounts[1].CI_Company__c = ciCompanies[1].Id;
        accounts[2].CI_Company__c = ciCompanies[2].Id;

        ContactUpdateUnomyCompanyTrH handlerInstance;
        Map<Id, Account> accountsByIds = new Map<Id, Account>(accounts);

        Test.startTest();
        handlerInstance = new ContactUpdateUnomyCompanyTrH();
        handlerInstance.prepareCICompanyDataForContacts(contacts, accountsByIds);
        Test.stopTest();

        System.assertEquals(contacts[0].CI_Company__c, accounts[0].CI_Company__c, 'CI Companies should be set to the same value');
        System.assertEquals(contacts[1].CI_Company__c, accounts[1].CI_Company__c, 'CI Companies should be set to the same value');
    }

    @isTest
    public static void shouldPrepareContactsForUnomyUpdate() {
        List<Account> accounts = getFakeAccounts(true);
        List<CI_Company__c> ciCompanies = getFakeCICompanies(true);
        List<Contact> contacts = getFakeContacts(true);
        contacts[0].AccountId = accounts[0].Id;
        contacts[1].AccountId = accounts[1].Id;
        contacts[2].AccountId = accounts[2].Id;
        contacts[2].CI_Company__c = ciCompanies[2].Id;
        accounts[0].CI_Company__c = ciCompanies[0].Id;
        accounts[1].CI_Company__c = ciCompanies[1].Id;
        accounts[2].CI_Company__c = ciCompanies[2].Id;
        ContactUpdateUnomyCompanyTrH handlerInstance;

        Test.startTest();
        handlerInstance = new ContactUpdateUnomyCompanyTrH(contacts);
        handlerInstance.beforeInsert();
        Test.stopTest();

        System.assertNotEquals(handlerInstance.newContacts[2].CI_Company__c, null, 'CI Company should be not null');
    }

    static List<CI_Company__c> getFakeCICompanies(Boolean isFakeIds) {
        Map<String, Object> recordsData = new Map<String, Object>();
        recordsData = new Map<String, Object>();
        recordsData.put('objectName', 'CI_Company__c');
        recordsData.put('numberOfRecords', 4);
        return MockTestingUtility.getRecords(recordsData, isFakeIds);
    }

    static List<Account> getFakeAccounts(Boolean isFakeIds) {
        Map<String, Object> recordsData = new Map<String, Object>();
        recordsData = new Map<String, Object>();
        recordsData.put('objectName', 'Account');
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