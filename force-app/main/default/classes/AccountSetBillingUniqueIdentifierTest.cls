/************************************************************************************************************************************
    Author       :  Shubham Nandwana   
    @Description :  Test class for AccountSetBillingUniqueIdentifier
    Issue No     :  TWSPG-711
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION     DATE                AUTHOR              ISSUE NO        DETAIL
    1           20 August 2021      Shubham Nandwana    TWSPG-711       Initial Developement              
**************************************************************************************************************************************/
@isTest
public class AccountSetBillingUniqueIdentifierTest {
    @isTest
    public static void testAccountSetBillingUniqueIdentifier_positive() {
        Id billRecTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Billing Account').getRecordTypeId();
        TestingUtility.createAccount(new Map<String,Object>{'Name' => 'Account-2', 
            'RecordTypeId' => billRecTypeId,
            'Account_Type__c' => 'Org',
            'uuid__c' => '7f1ed9c0-7b81-0139-7a63-1288dc637d31'}, true);
        List<Account> accounts = [SELECT Id, Member_Short_Code__c FROM Account WHERE Name = 'Account-2'];
        System.assertEquals('5YH052', accounts.get(0).Member_Short_Code__c, 'Short code is not generated correctly');
    }

    @isTest
    public static void testAccountSetBillingUniqueIdentifier_negative() {
        Id billRecTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Billing Account').getRecordTypeId();
        TestingUtility.createAccount(new Map<String,Object>{'Name' => 'Account-2', 
            'RecordTypeId' => billRecTypeId,
            'Account_Type__c' => 'Org'
            }, true);
        List<Account> accounts = [SELECT Id, Member_Short_Code__c FROM Account WHERE Name = 'Account-2'];
        System.assertEquals(null, accounts.get(0).Member_Short_Code__c, 'Short code should not be generated when UUID is null');
    }
}