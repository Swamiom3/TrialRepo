@isTest
public class AccountUpdateOrderBillingAccTrHTest {
      
    @testSetup
    static void setupTestData() {
        List<Account> parentOrgAccounts = new List<Account>();
        parentOrgAccounts.add(TestingUtility.createAccount(new Map<String,Object>{'Name' => 'Parent Account 1', 
            'UUID__c' => 'parent-UUID-001',
            'Account_Type__c' => 'Org'}, false));
        parentOrgAccounts.add(TestingUtility.createAccount(new Map<String,Object>{'Name' => 'Parent Account 2', 
            'UUID__c' => 'parent-UUID-002',
            'Account_Type__c' => 'Org'}, false));
        insert parentOrgAccounts;  
        
        Order objOrder = new Order();
        objOrder.AccountId = parentOrgAccounts[0].Id;
        objOrder.blng__BillingAccount__c = parentOrgAccounts[0].Id;
        objOrder.EffectiveDate = system.today();
        objOrder.Status = 'Draft';
        objOrder.Account_Billing_Frequency__c = 'Annual';
        insert objOrder;

        Building_Account__c buildAccount = new Building_Account__c();
        buildAccount.Account_Id__c = parentOrgAccounts[0].Id;
        buildAccount.Name = 'Test Building Account';
        buildAccount.Billing_Account_Id__c = parentOrgAccounts[0].Id;
        buildAccount.Status__c = 'Onboarding';
        insert buildAccount;
        
    }
    
    @isTest
    private static void testexecuteFlow() {
        Test.startTest();
        List<Account> lstAcc = [SELECT Id FROM Account];
        lstAcc[0].Account_Billing_Frequency__c = 'Monthly';
        lstAcc[0].Submit_for_Dedicated_Billing_Support__c = TRUE;
        lstAcc[0].Dedicated_Billing_Associate_Id__c = System.UserInfo.getUserId();
        lstAcc[0].Dedicated_Billing_Support__c = 'Yes';
        lstAcc[0].Reason_for_Dedicated_Billing_Support__c = 'need';
        lstAcc[0].Taxation_Status__c = 'Pending Tax Exempt';
        update lstAcc;
        Test.stopTest();
        
        // Confirm order has been updated successfully.
        List<Building_Account__c> buildingAccounts = [SELECT Id FROM Building_Account__c WHERE Collections_Agent_Id__c = :System.UserInfo.getUserId()];
        system.assert(buildingAccounts.size() > 0, 'Collections Agent Updated Successfully.');
    }
}