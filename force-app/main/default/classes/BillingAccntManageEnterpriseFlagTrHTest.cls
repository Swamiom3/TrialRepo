/*************************************************************************************************************************************
Author      :   Salesforce
Description :   This class provides sufficient test coverage for BillingAccountManageEnterpriseFlagTrH class
--------------------------------------------------------------------------------------------------------------------------------------
VERSION         DATE            AUTHOR              DETAIL
1               01/31/2022       Salesforce         Initial Deployment
**************************************************************************************************************************************/
@isTest
public with sharing class BillingAccntManageEnterpriseFlagTrHTest {
    public static final Id billingRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Billing Account').getRecordTypeId();
    @testSetup
    static void initData() {
        Account businessAccount = TestingUtility.createAccount('Test Ultimate Parent', true);
        businessAccount.Account_Type__c = 'Org';
        update businessAccount;
        CI_Company__c unomyCompany = new CI_Company__c(CI_Company_Id__c = 1234, Company_Name__c = 'orgAcc1', Size__c = 500);
        TestingUtility.insertWithAssert(unomyCompany);
    }

    @isTest
    public static void testBillingAccountCreation() {
        Account parentAccount = [SELECT Id FROM Account];
        parentAccount.Number_of_Full_Time_Employees__c = 500;
        update parentAccount;
        List<Account> billingAccounts = TestingUtility.createAccounts(2, 'Test Account', false);
        for (Account a: billingAccounts) {
            a.RecordTypeId = billingRecordTypeId;
            a.Ultimate_Parent_Org__c = parentAccount.Id;
        }
        Test.startTest();
        insert billingAccounts;
        Test.stopTest();
        for (Account a : [SELECT Id, Customer_Group__c FROM Account WHERE RecordTypeId = :billingRecordTypeId]) {
            System.assertEquals('Enterprise', a.Customer_Group__c, 'Enterprise Flag is not set');
        }
    }

    @isTest
    public static void testBillingAccountUpdation() {
        Account parentAccount = [SELECT Id FROM Account];
        Account parentAccountFTE = TestingUtility.createAccount('Test Ultimate Parent1', true);
        parentAccountFTE.Account_Type__c = 'Org';
        parentAccountFTE.Number_of_Full_Time_Employees__c = 500;
        update parentAccountFTE;

        List<Account> billingAccounts = TestingUtility.createAccounts(2, 'Test Account', false);
        for (Account a: billingAccounts) {
            a.RecordTypeId = billingRecordTypeId;
            a.Ultimate_Parent_Org__c = parentAccount.Id;
        }
        insert billingAccounts;
        for (Account a : [SELECT Id, Customer_Group__c FROM Account WHERE RecordTypeId = :billingRecordTypeId]) {
            System.assertEquals(null, a.Customer_Group__c, 'Enterprise Flag is already set');
        }
        Test.startTest();
        for (Account a: billingAccounts) {
            a.Ultimate_Parent_Org__c = parentAccountFTE.Id;
        }
        update billingAccounts;
        Test.stopTest();
        for (Account a : [SELECT Id, Customer_Group__c FROM Account WHERE RecordTypeId = :billingRecordTypeId]) {
            System.assertEquals('Enterprise', a.Customer_Group__c, 'Enterprise Flag is not set');
        }
    }

    @isTest
    public static void testBusinessAccountUpdateFTEAddEnterprise() {
        Account parentAccount = [SELECT Id, Number_of_Full_Time_Employees__c FROM Account];
        List<Account> billingAccounts = TestingUtility.createAccounts(2, 'Test Account', false);
        for (Account a: billingAccounts) {
            a.RecordTypeId = billingRecordTypeId;
            a.Ultimate_Parent_Org__c = parentAccount.Id;
        }
        insert billingAccounts;
        for (Account a : [SELECT Id, Customer_Group__c FROM Account WHERE RecordTypeId = :billingRecordTypeId]) {
            System.assertEquals(null, a.Customer_Group__c, 'Enterprise Flag is already set');
        }
        Test.startTest();
        parentAccount.Number_of_Full_Time_Employees__c = 500;
        update parentAccount;
        Test.stopTest();
        for (Account a : [SELECT Id, Customer_Group__c FROM Account WHERE RecordTypeId = :billingRecordTypeId]) {
            System.assertEquals('Enterprise', a.Customer_Group__c, 'Enterprise Flag is not set');
        }
    }

    @isTest
    public static void testBusinessAccountUpdateCiCompany() {
        Account parentAccount = [SELECT Id FROM Account];
        CI_Company__c unomyCompany = [Select Id From CI_Company__c];
        List<Account> billingAccounts = TestingUtility.createAccounts(2, 'Test Account', false);
        for (Account a: billingAccounts) {
            a.RecordTypeId = billingRecordTypeId;
            a.Ultimate_Parent_Org__c = parentAccount.Id;
        }
        insert billingAccounts;
        for (Account a : [SELECT Id, Customer_Group__c FROM Account WHERE RecordTypeId = :billingRecordTypeId]) {
            System.assertEquals(null, a.Customer_Group__c, 'Enterprise Flag is already set');
        }
        Test.startTest();
        parentAccount.CI_Company__c = unomyCompany.Id;
        parentAccount.CI_Updated_DateTime__c = System.now();
        update parentAccount;
        Test.stopTest();
        for (Account a : [SELECT Id, Customer_Group__c FROM Account WHERE RecordTypeId = :billingRecordTypeId]) {
            System.assertEquals('Enterprise', a.Customer_Group__c, 'Enterprise Flag is not set');
        }
    }
}