@isTest
private class AccountSelectorTest {
    private static AccountSelector accountSelector = new AccountSelector();
    public static final Id billingRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Billing Account').getRecordTypeId();
    @testSetup
    static void makeData() {
        CI_Company__c unomyCompany = new CI_Company__c(CI_Company_Id__c = 1234, Company_Name__c = 'orgAcc1', Size__c = 500);
        TestingUtility.insertWithAssert(unomyCompany);
        Account parentAccount = TestingUtility.createAccount('Acc', true);
        parentAccount.CI_Company__c = unomyCompany.Id;
        parentAccount.CI_Updated_DateTime__c = System.now();
        update parentAccount;
        List<Account> billingAccounts = TestingUtility.createAccounts(2, 'Test Account', false);
        for (Account a: billingAccounts) {
            a.RecordTypeId = billingRecordTypeId;
            a.Ultimate_Parent_Org__c = parentAccount.Id;
        }
        insert billingAccounts;
    }

    @isTest
    static void getAccountsByIdTest() {
        Map<Id, Account> accountsMap = new Map<Id, Account>([SELECT Id FROM Account]);
        Test.startTest();
        List<Account> accounts = accountSelector.getAccountsById(new List<Id>(accountsMap.keySet()));
        List<Account> accsWithOpportunities = accountSelector.getAccountWithOpportunities(accountsMap.keySet());
        List<Account> accsWithContacts = accountSelector.getAccountWithContacts(accountsMap.keySet());
        List<Account> accsWithManager = accountSelector.getAccountManagerByAccId(new List<Id>(accountsMap.keySet()));
        List<Account> accsWithParents = accountSelector.getAccountsWithParentsDeep(accountsMap.keySet());
        Test.stopTest();
        System.assertEquals(3, accountsMap.size(), 'Should return 3 Account records.');
        System.assertEquals(3, accounts.size(), 'Should return 3 Account records.');
        System.assertEquals(3, accsWithOpportunities.size(), 'Should return 3 Account records.');
        System.assertEquals(3, accsWithContacts.size(), 'Should return 3 Account records.');
        System.assertEquals(3, accsWithManager.size(), 'Should return 3 Account records.');
        System.assertEquals(3, accsWithParents.size(), 'Should return 3 Account records.');
    }

    @isTest 
    static void getAccountsByIdOrUltimateParentTest() {
        Set<String> accTypes = new Set<String>{GlobalConstants.ACCOUNT_TYPE_ORG, GlobalConstants.ACCOUNT_TYPE_SALES};
        Map<Id, Account> businessAccountsMap = new Map<Id, Account>([SELECT Id FROM Account WHERE RecordTypeId != :billingRecordTypeId]);
        Map<Id, Account> billingAccountsMap = new Map<Id, Account>([SELECT Id FROM Account WHERE RecordTypeId = :billingRecordTypeId]);
        Set<String> parentIds = new Set<String>();
        for (Account account : billingAccountsMap.values()) {
            parentIds.add(account.Id);
        }
        Test.startTest();
        List<Account> accountsByUltimateParent = accountSelector.getAccountsByIdOrUltimateParent(new List<Id>(), new List<Id>(businessAccountsMap.keySet()));
        List<Account> accountsById = accountSelector.getAccountsByIdOrUltimateParent(new List<Id>(billingAccountsMap.keySet()), new List<Id>());
        List<Account> accountsByIdAndParent = accountSelector.getAccountsByIdOrUltimateParent(new List<Id>(businessAccountsMap.keySet()), new List<Id>(businessAccountsMap.keySet()));
        List<Account> accountsEmpty = accountSelector.getAccountsByIdOrUltimateParent(new List<Id>(), new List<Id>());
        List<Account> accsWithOpportunities = accountSelector.getAccountWithOpportunities(businessAccountsMap.keySet(), parentIds);
        List<Account> accsWithAccContactRelations = accountSelector.getAccountWithAccContactRelations(new Set<String>{'Primary Member'}, new Set<String>{'Billing_Account'}, businessAccountsMap.keySet());
        List<Account> accountsByParentAccount = accountSelector.getAccountsByParentAccount(businessAccountsMap.keySet());
        Test.stopTest();
        System.assertEquals(1, businessAccountsMap.size(), 'Should return 1 Account record.');
        System.assertEquals(2, billingAccountsMap.size(), 'Should return 2 Account records.');
        System.assertEquals(2, accountsByUltimateParent.size(), 'Should return 2 Account records.');
        System.assertEquals(2, accountsById.size(), 'Should return 2 Account records.');
        System.assertEquals(3, accountsByIdAndParent.size(), 'Should return 3 Account records.');
        System.assertEquals(0, accountsEmpty.size(), 'Should return 0 Account records.');
        System.assert(!accsWithOpportunities.isEmpty(), 'Should return Account records.');
        System.assert(!accsWithAccContactRelations.isEmpty(), 'Should return Account records.');
    }

    @isTest
    static void getAccountsByUltimateParentTest() {
        Map<Id, Account> businessAccountsMap = new Map<Id, Account>([SELECT Id FROM Account WHERE RecordTypeId != :billingRecordTypeId]);
        Test.startTest();
        List<Account> accountsByUltimateParent = accountSelector.getAccountsByUltimateParent(new List<Id>(businessAccountsMap.keySet()));
        List<Account> accountsEmpty = accountSelector.getAccountsByUltimateParent(new List<Id>());
        Test.stopTest();
        System.assertEquals(1, businessAccountsMap.size(), 'Should return 1 Account record.');
        System.assertEquals(2, accountsByUltimateParent.size(), 'Should return 2 Account records.');
        System.assertEquals(0, accountsEmpty.size(), 'Should return 0 Account records.');
    }

    @isTest
    static void getAccountsByUnomyCompanyTest() {
        Map<Id, Account> businessAccountsMap = new Map<Id, Account>([SELECT Id FROM Account WHERE RecordTypeId != :billingRecordTypeId]);
        Map<Id, CI_Company__c> unomyCompanyMap = new Map<Id, CI_Company__c> ([Select Id, Size__c From CI_Company__c]);
        Test.startTest();
        List<Account> accountsByUnomyCompany = accountSelector.getAccountsByUnomyCompany(new List<Id>(unomyCompanyMap.keySet()));
        List<Account> accountsEmpty = accountSelector.getAccountsByUnomyCompany(new List<Id>());
        List<Account> unomyAccounts = accountSelector.getUnomyAccountsById(businessAccountsMap.keySet());
        Test.stopTest();
        System.assertEquals(1, unomyCompanyMap.size(), 'Should return 1 Ci Company record.');
        System.assertEquals(1, accountsByUnomyCompany.size(), 'Should return 2 Account record.');
        System.assertEquals(0, accountsEmpty.size(), 'Should return 0 Account records.');
        System.assert(!unomyAccounts.isEmpty(), 'Should return Account records.');
    }
    
    @isTest
    static void getAccountWithAccountTeamTest() {
        Map<Id, Account> accountsMap = new Map<Id, Account>([SELECT Id FROM Account]);
        Set<String> teamMembersRoles  = new Set<String>{'Territory Co-Prime', 'Regional Co-Prime'};
        Test.startTest();
        List<Account> accounts = accountSelector.getAccountWithAccountTeam(teamMembersRoles,new Set<Id>(accountsMap.keySet()));
        Test.stopTest();
        System.assertEquals(3, accountsMap.size(), 'Should return 3 Account record.');
        System.assertEquals(3, accounts.size(), 'Should return 3 Account record.');
    }

    @isTest
    static void testGetSalesAccountsById() {
        Map<Id, Account> accountsMap = new Map<Id, Account>([SELECT Id FROM Account]);
        Test.startTest();
        List<Account> accounts = accountSelector.getSalesAccountsById(accountsMap.keySet());
        Test.stopTest();
        System.assertEquals(3, accounts.size(), 'Should return 3 Account records');
        System.assertNotEquals(null, accounts[0].Name, 'Account name should be retrieved');
    }

    @isTest
    static void testGetAccountsByParentIdsAndIdAndSalesOrgType() {
        Id businessAccountId = [SELECT Id FROM Account WHERE RecordTypeId != :billingRecordTypeId][0].Id;
        Test.startTest();
        List<Account> accounts = accountSelector.getAccountsByParentIdsAndIdAndSalesOrgType(businessAccountId, businessAccountId, businessAccountId);
        Test.stopTest();
        System.assertEquals(1, accounts.size(), 'Should return 1 Account record');
        System.assertNotEquals(null, accounts[0].Name, 'Account name should be retrieved');
    }

    @isTest
    static void testGetAccountsByParentIdsAndSalesOrgType() {
        Id businessAccountId = [SELECT Id FROM Account WHERE RecordTypeId != :billingRecordTypeId][0].Id;
        Account childAccount = new Account(ParentId = businessAccountId, Name = 'Child account');
        insert childAccount;
        Test.startTest();
        List<Account> accounts = accountSelector.getAccountsByParentIdsAndSalesOrgType(businessAccountId, businessAccountId);
        Test.stopTest();
        System.assertEquals(1, accounts.size(), 'Should return 1 Account record');
        System.assertEquals(childAccount.Id, accounts[0].Id, 'Child account should be retrieved by existing parent');
    }
}