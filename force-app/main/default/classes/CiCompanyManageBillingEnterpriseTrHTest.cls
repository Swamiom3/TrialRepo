/*************************************************************************************************************************************
Author      :   Salesforce
Description :   This class provides sufficient test coverage for CiCompanyManageBillingEnterpriseTrH class
--------------------------------------------------------------------------------------------------------------------------------------
VERSION         DATE            AUTHOR              DETAIL
1               01/31/2022       Salesforce         Initial Deployment
**************************************************************************************************************************************/
@isTest
public with sharing class CiCompanyManageBillingEnterpriseTrHTest {
    public static final Id billingRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Billing Account').getRecordTypeId();
    @testSetup
    static void initData() {
        CI_Company__c unomyCompany = new CI_Company__c(CI_Company_Id__c = 1234, Company_Name__c = 'orgAcc1');
        TestingUtility.insertWithAssert(unomyCompany);
        Account businessAccount = TestingUtility.createAccount('Test Ultimate Parent', true);
        businessAccount.Account_Type__c = 'Org';
        businessAccount.CI_Company__c = unomyCompany.Id;
        businessAccount.CI_Updated_DateTime__c = System.now();
        update businessAccount;
        List<Account> billingAccounts = TestingUtility.createAccounts(2, 'Test Account', false);
        for (Account a: billingAccounts) {
            a.RecordTypeId = billingRecordTypeId;
            a.Ultimate_Parent_Org__c = businessAccount.Id;
        }
        insert billingAccounts;
    }

    @isTest
    public static void testUpdateCICompanySizeAddEnterprise() {
        CI_Company__c unomyCompany = [Select Id, Size__c From CI_Company__c];
        for (Account a : [SELECT Id, Customer_Group__c FROM Account WHERE RecordTypeId = :billingRecordTypeId]) {
            System.assertEquals(null, a.Customer_Group__c, 'Enterprise Flag is already set');
        }
        Test.startTest();
        unomyCompany.Size__c = 500;
        update unomyCompany;
        Test.stopTest();
        for (Account a : [SELECT Id, Customer_Group__c FROM Account WHERE RecordTypeId = :billingRecordTypeId]) {
            System.assertEquals('Enterprise', a.Customer_Group__c, 'Enterprise Flag is not set');
        }
    }

    @isTest
    public static void testUpdateCICompanySizeRemoveEnterprise() {
        CI_Company__c unomyCompany = [Select Id, Size__c From CI_Company__c];
        unomyCompany.Size__c = 500;
        update unomyCompany;
        for (Account a : [SELECT Id, Customer_Group__c FROM Account WHERE RecordTypeId = :billingRecordTypeId]) {
            System.assertEquals('Enterprise', a.Customer_Group__c, 'Enterprise Flag is not set');
        }
        Test.startTest();
        unomyCompany.Size__c = 400;
        update unomyCompany;
        Test.stopTest();
        for (Account a : [SELECT Id, Customer_Group__c FROM Account WHERE RecordTypeId = :billingRecordTypeId]) {
            System.assertEquals(null, a.Customer_Group__c, 'Enterprise Flag is already set');
        }
    }

    @isTest
    public static void testUpdateCIOverRideHeadCountAddEnterprise() {
        CI_Company__c unomyCompany = [Select Id, Override_Estimated_Headcount__c From CI_Company__c];
        for (Account a : [SELECT Id, Customer_Group__c FROM Account WHERE RecordTypeId = :billingRecordTypeId]) {
            System.assertEquals(null, a.Customer_Group__c, 'Enterprise Flag is already set');
        }
        Test.startTest();
        unomyCompany.Override_Estimated_Headcount__c = 500;
        update unomyCompany;
        Test.stopTest();
        for (Account a : [SELECT Id, Customer_Group__c FROM Account WHERE RecordTypeId = :billingRecordTypeId]) {
            System.assertEquals('Enterprise', a.Customer_Group__c, 'Enterprise Flag is not set');
        }
    }

    @isTest
    public static void testUpdateCIOverRideHeadCountRemoveEnterprise() {
        CI_Company__c unomyCompany = [Select Id, Override_Estimated_Headcount__c From CI_Company__c];
        unomyCompany.Override_Estimated_Headcount__c = 500;
        update unomyCompany;
        for (Account a : [SELECT Id, Customer_Group__c FROM Account WHERE RecordTypeId = :billingRecordTypeId]) {
            System.assertEquals('Enterprise', a.Customer_Group__c, 'Enterprise Flag is not set');
        }
        Test.startTest();
        unomyCompany.Override_Estimated_Headcount__c = 400;
        update unomyCompany;
        Test.stopTest();
        for (Account a : [SELECT Id, Customer_Group__c FROM Account WHERE RecordTypeId = :billingRecordTypeId]) {
            System.assertEquals(null, a.Customer_Group__c, 'Enterprise Flag is already set');
        }
    }
}