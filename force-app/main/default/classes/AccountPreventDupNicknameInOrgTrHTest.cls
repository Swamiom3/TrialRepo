@isTest
public class AccountPreventDupNicknameInOrgTrHTest{
    
    static AccountPreventDupNicknameInOrgTrH handlerInstance = new AccountPreventDupNicknameInOrgTrH();    

    static void setupData(){
        Account insertAccount = new Account();
        insertAccount.Name = 'Test Account';
        insertAccount.Nickname__c = 'testAcc';
        insert insertAccount;
    }
    @isTest
    static void checkNewInsertionDupNicknameUnderSameOrgHierarchyTestPositive(){
        setupData();

        Test.startTest();
        List<Account> accountToCheck = [ SELECT Id, Name, Nickname__c, Parent_Org_Id__c 
                                         FROM Account
                                         WHERE Name = 'Test Account' ];
        Map<String, Account> mapParentOrg = new Map<String, Account>();
        mapParentOrg.put(accountToCheck.get(0).Nickname__c.toLowerCase(), accountToCheck.get(0));
        String parentOrg = '' + accountToCheck.get(0).Parent_Org_Id__c;
        handlerInstance.VALIDATION_BYPASS_USER_INTEGRATION = false;
        handlerInstance.accountNicknames = new Set<String>();

        handlerInstance.parentOrgIdToNicknameWithAccount = new Map<String, Map<String, Account>>{
                '12345678' => mapParentOrg
        };
        handlerInstance.checkNewInsertionDupNicknameUnderSameOrgHierarchy(accountToCheck.get(0));
        handlerInstance.checkExistingDupNicknameUnderSameOrgHierarchy(
                new Account(Name = 'test',
                            Nickname__c = 'test'));
        Boolean isInsert = handlerInstance.isValidToCheckDuplicateNickname(
                accountToCheck.get(0),
                new Account(Name = 'test', Nickname__c = 'test'),
                true);

        handlerInstance.parentOrgIdToNicknameWithAccount =
                new Map<String, Map<String, Account>>{
                        parentOrg => mapParentOrg
                };
        handlerInstance.checkNewInsertionDupNicknameUnderSameOrgHierarchy(accountToCheck.get(0));
        handlerInstance.checkExistingDupNicknameUnderSameOrgHierarchy(accountToCheck.get(0));
        isInsert = handlerInstance.isValidToCheckDuplicateNickname(
                accountToCheck.get(0),
                new Account(Name = 'test', Nickname__c = 'test'),
                false);
        Test.stopTest();

        System.assertEquals(true, isInsert, 'Nick Name must be different');
    }
    
    @isTest
    static void preventDuplicateNicknameInSameOrgHierarchyTest(){
        setupData();

        Test.startTest();
        handlerInstance.VALIDATION_BYPASS_USER_INTEGRATION = false;
        handlerInstance.newAccounts = new List<Account>{[ SELECT Id, Name, Nickname__c, Parent_Org_Id__c, Account_Type__c
                                                      FROM Account
                                                      WHERE Name = 'Test Account' ]};
        handlerInstance.preventDuplicateNicknameInSameOrgHierarchy();
        handlerInstance.beforeInsert();
        handlerInstance.beforeUpdate();
        System.assert(handlerInstance.parentOrgIdToNicknameWithAccount.isEmpty(),
                      'Mapping should remain empty for all methods on wrong account type');

        handlerInstance.newAccounts[0].Account_Type__c = 'Sales';
        handlerInstance.beforeUpdate();
        System.assert(!handlerInstance.parentOrgIdToNicknameWithAccount.isEmpty(),
                      'Mapping should contain at least one record for \'Sales\' RecordType');
        Test.stopTest();
    }

    @isTest
    static void shouldGetProperParentForAccountRecord(){
        Id firstParentId;
        Id secondParentId;
        Id thirdParentId;
        Id fourthParentId;
        List<Account> accounts = getFakeAccounts();
        accounts[0].ParentId = accounts[1].Id;
        accounts[0].Parent = accounts[1];
        accounts[1].ParentId = accounts[2].Id;
        accounts[1].Parent = accounts[2];
        accounts[2].ParentId = accounts[3].Id;
        accounts[2].Parent = accounts[3];

        Test.startTest();
        firstParentId = new AccountPreventDupNicknameInOrgTrH().getParentOrgIdForSingleRecord(accounts[0]);
        secondParentId = new AccountPreventDupNicknameInOrgTrH().getParentOrgIdForSingleRecord(accounts[1]);
        thirdParentId = new AccountPreventDupNicknameInOrgTrH().getParentOrgIdForSingleRecord(accounts[2]);
        fourthParentId = new AccountPreventDupNicknameInOrgTrH().getParentOrgIdForSingleRecord(accounts[3]);
        Test.stopTest();

        System.assertEquals(firstParentId, accounts[3].Id, 'Should get proper parent Id');
        System.assertEquals(secondParentId, accounts[3].Id, 'Should get proper parent Id');
        System.assertEquals(thirdParentId, accounts[3].Id, 'Should get proper parent Id');
        System.assertEquals(fourthParentId, accounts[3].Id, 'Should get proper parent Id');
    }

    static List<Account> getFakeAccounts() {
        Map<String, Object> recordsData = new Map<String, Object>();
        recordsData = new Map<String, Object>();
        recordsData.put('objectName', 'Account');
        recordsData.put('numberOfRecords', 4);
        return MockTestingUtility.getRecords(recordsData, true);
    }
}