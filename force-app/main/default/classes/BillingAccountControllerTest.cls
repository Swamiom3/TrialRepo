@isTest
public class BillingAccountControllerTest {

    @isTest
    public static void getBillAccountsOfAccountHierarchy_test_positive() {
        Account ultimateParentAcc = TestingUtility.createAccount('Test Ultimate Parent', true);
        ultimateParentAcc.Account_Type__c = 'Org';
        update ultimateParentAcc;
        Opportunity opp = TestingUtility.createOpportunity(ultimateParentAcc.Id, true);

        Id billRecTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Billing Account')
            .getRecordTypeId();
        List<Account> billAccountList = TestingUtility.createAccounts(6, 'Test Account', false);
        for (Account acc: billAccountList) {
            acc.RecordTypeId = billRecTypeId;
            acc.Ultimate_Parent_Org__c = ultimateParentAcc.Id;
        }
        insert billAccountList;

        System.assert(BillingAccountController.getBillAccountsOfAccountHierarchy(opp.Id).size() == 6,
            'Number of billing accounts for this opportunity should be 6');

    }

    @isTest
    public static void getBillAccountsOfAccountHierarchy_test_negative() {
        Map<String, Object> oppFieldValues = new Map<String, Object> {
            'AccountId' => null
        };
        Opportunity opp = TestingUtility.createOpportunity(oppFieldValues, true);
        System.assert(BillingAccountController.getBillAccountsOfAccountHierarchy(opp.Id) == null,
            'Method should return null');

    }

    @isTest
    public static void getOppUltimateParentAccount_test_positive() {
        Map<String, Object> accountFieldValues = new Map<String, Object> {
            'Name' => 'Ultimate Account',
            'Account_Type__c' => 'Org'
        };
        Account ultimateAccount = TestingUtility.createAccount(accountFieldValues, true);

        Account oppAccount = TestingUtility.createAccount('Parent Account', false);
        oppAccount.ParentId = ultimateAccount.Id;
        oppAccount.Account_Type__c = 'Org';
        insert oppAccount;
        Opportunity opp = TestingUtility.createOpportunity(oppAccount.Id, true);

        BillingAccountController.OpportunityData result = BillingAccountController.getOppUltimateParentAccount(opp.Id);
        System.assert(result.parentAccountId == ultimateAccount.Id, 'failed to get ultimate parent account on opportunity ');

    }

    @isTest
    public static void getOppUltimateParentAccount_test_negative() {
        Map<String, Object> oppFieldValues = new Map<String, Object> {
            'AccountId' => null
        };

        Opportunity opp = TestingUtility.createOpportunity(oppFieldValues, true);

        System.assert(BillingAccountController.getOppUltimateParentAccount(opp.Id).parentAccountId == null,
            'null should be returned as there is no account on opportunity ');

    }

    @isTest
    public static void updateOpportunity_test_positive() {

        Account oppAccount = TestingUtility.createAccount('Test Opp Account', false);
        oppAccount.Account_Type__c = 'Org';
        insert oppAccount;
        Account oppBillAccount = TestingUtility.createAccount('Test Opp BillAccount', false);
        Id billRecTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Billing Account')
            .getRecordTypeId();
        oppBillAccount.RecordTypeId = billRecTypeId;
        insert oppBillAccount;
        Opportunity opp = TestingUtility.createOpportunity(oppAccount.Id, true);
        String result = BillingAccountController.updateOpportunityAndPrimaryQuote(opp.Id, oppBillAccount.Id, null);
        System.assert(result == 'success', 'failed to update opportunity');

    }
    
    @isTest
    public static void updateOpportunity_test_negative() {
        Account oppAccount = TestingUtility.createAccount('Test Opp Account', false);
        oppAccount.Account_Type__c = 'Org';
        insert oppAccount;
        Account oppBillAccount = TestingUtility.createAccount('Test Opp BillAccount', false);
        Id billRecTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Business Account')
            .getRecordTypeId();
        oppBillAccount.RecordTypeId = billRecTypeId;
        insert oppBillAccount;
        Opportunity opp = TestingUtility.createOpportunity(oppAccount.Id, true);
        try{
            BillingAccountController.updateOpportunityAndPrimaryQuote(opp.Id, oppBillAccount.Id, null); 
        }catch(Exception e){
            System.assert(e.getTypeName()  == 'System.AuraHandledException', 'lookup filter is present');  
        }
       
    }

    @isTest
    static void getOppParentAccountId_test_positive() {
        Map<String, Object> ultimateAccountFieldValues = new Map<String, Object> {'Name' => 'Ultimate Account','Account_Type__c' => 'Org'};
        Account ultimateAccount = TestingUtility.createAccount(ultimateAccountFieldValues, true);
        Account parentAccount = TestingUtility.createAccount('Parent Account', false);
        parentAccount.ParentId = ultimateAccount.Id;
        parentAccount.Account_Type__c = 'Org';
        insert parentAccount;
        Opportunity opportunityRecord = TestingUtility.createOpportunity(parentAccount.Id, true);
        Id parentAccountIdResult = BillingAccountController.getOppParentAccountId(opportunityRecord.Id);
        System.assertEquals(parentAccount.Id, parentAccountIdResult);
    }
    
    @isTest
    static void getOppParentAccountId_test_negative() {
        try{
            BillingAccountController.getOppParentAccountId(null);
            System.assert(false); 
        }catch(Exception exe){
            System.assertEquals('System.AuraHandledException',exe.getTypeName());  
        }
    }
}