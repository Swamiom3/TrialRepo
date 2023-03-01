/*************************************************************************************************************************************
Author      :   Salesforce
Description :   This class provides sufficient test coverage for BillingAccountManageEnterpriseFlagUtils class
--------------------------------------------------------------------------------------------------------------------------------------
VERSION         DATE            AUTHOR              DETAIL
1               01/31/2022       Salesforce         Initial Deployment
**************************************************************************************************************************************/
@isTest
public with sharing class BillingAcntManageEnterpriseFlagUtilsTest {
    public static final Id billingRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Billing Account').getRecordTypeId();
    @testSetup
    static void initData() {
        Account businessAccount = TestingUtility.createAccount('Test Ultimate Parent', true);
        businessAccount.Account_Type__c = 'Org';
        update businessAccount;
        List<Account> billingAccounts = TestingUtility.createAccounts(2, 'Test Account', false);
        for (Account a: billingAccounts) {
            a.RecordTypeId = billingRecordTypeId;
            a.Customer_Group__c = 'Membership';
            a.Ultimate_Parent_Org__c = businessAccount.Id;
        }
        insert billingAccounts;
    }

    @isTest
    public static void testUpdateCustomerGroupAddEnterprise() {
        Account billingAccount = [SELECT Id, Customer_Group__c FROM Account WHERE RecordTypeId = :billingRecordTypeId LIMIT 1];
        System.assertEquals('Membership', billingAccount.Customer_Group__c, 'Enterprise Flag is already set');
        Test.startTest();
        billingAccount = BillingAccountManageEnterpriseFlagUtils.updateCustomerGroup(billingAccount, false);
        Test.stopTest();
        System.assertEquals('Membership;Enterprise', billingAccount.Customer_Group__c, 'Enterprise Flag is not set');
    }

    @isTest
    public static void testUpdateCustomerGroupRemoveEnterprise() {
        Account billingAccount = [SELECT Id, Customer_Group__c FROM Account WHERE RecordTypeId = :billingRecordTypeId LIMIT 1];
        billingAccount.Customer_Group__c = 'Membership;Enterprise';
        update billingAccount;
        System.assertEquals('Membership;Enterprise', billingAccount.Customer_Group__c, 'Enterprise Flag is not set');
        Test.startTest();
        billingAccount = BillingAccountManageEnterpriseFlagUtils.updateCustomerGroup(billingAccount, true);
        Test.stopTest();
        System.assertEquals('Membership', billingAccount.Customer_Group__c, 'Enterprise Flag is not removed');
    }
}