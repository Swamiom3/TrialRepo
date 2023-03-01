@isTest
public with sharing class ApiUsersUtilsTest {
    @isTest
    public static void testApiUser() {
        System.assertEquals( [SELECT Id
                              FROM User
                              WHERE ProfileId =: (Validation_Rule_Restriction__mdt.getInstance('Integration_Profile').Salesforce_Id__c)
                              ORDER BY Name
                              LIMIT 1].Id, ApiUsersUtils.apiUser.Id, 'Integration User should be same at any org');
    }

    @isTest
    public static void testIsApiUser() {
        User testUser = [SELECT Id FROM User WHERE ProfileId !=:(Validation_Rule_Restriction__mdt.getInstance('Integration_Profile').Salesforce_Id__c) LIMIT 1];
        System.assertEquals(false, ApiUsersUtils.isUserAnApiUser(testUser.Id),'Compare Id of other user to Id of Api User should always give false');
        System.assertEquals(true, ApiUsersUtils.isUserAnApiUser([SELECT Id
                                                                 FROM User
                                                                 WHERE ProfileId = :(Validation_Rule_Restriction__mdt.getInstance('Integration_Profile').Salesforce_Id__c)
                                                                 ORDER BY Name
                                                                 LIMIT 1].Id), 'Id of Susie Romero should be an API user at any org');
    }
    
    @isTest
    public static void apiUserContactIdTest() {
        Test.startTest();
        Account acc = UtilAccount.getNewAccounts(1, true)[0];
        Contact testContact = UtilContact.getNewContacts(1, acc, false)[0];
        testContact.Email = ApiUsersUtils.apiUser.Email;
        insert testContact;
        Test.stopTest();
        System.assertEquals(testContact.Id, ApiUsersUtils.apiUserContactId, 'Api user contact id should be present');
    }
}