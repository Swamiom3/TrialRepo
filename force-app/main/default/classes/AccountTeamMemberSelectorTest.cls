/*************************************************************************************************************************************
    Author      :   Stepan Vardzal
    Description :   Test class for AccountTeamMemberSelector
    History:        New test class
    --------------------------------------------------------------------------------------------------------------------------------------
    VERSION         DATE            AUTHOR                      DETAIL							                            ISSUE
    1.0             06 Sept, 2021   Stepan Vardzal              Refactor triggers: AccountTeamMember                        ST-8430
**************************************************************************************************************************************/
@isTest
public class AccountTeamMemberSelectorTest {
    private static AccountTeamMemberSelector selector = new AccountTeamMemberSelector();

    @testSetup
    static void makeData() {
        List<Account> testAccounts = UtilAccount.GetNewAccounts(2, true);
        Account testGlobalAccount = (Account) TestingUtility.createTestRecords(Account.sObjectType, new Map<String, Object>{'Name' => 'Test Account', 'Named_Account_Segment__c' => 'Global Account'}, true);
        List<AccountTeamMember> testTeamMembers = new List<AccountTeamMember>();
        testTeamMembers.add(new AccountTeamMember(AccountId = testAccounts[0].Id, UserId = UserInfo.getUserId(), TeamMemberRole = 'Legal'));
        testTeamMembers.add(new AccountTeamMember(AccountId = testAccounts[1].Id, UserId = UserInfo.getUserId(), TeamMemberRole = 'Legal'));
        testTeamMembers.add(new AccountTeamMember(AccountId = testGlobalAccount.Id, UserId = UserInfo.getUserId(), TeamMemberRole = 'Inside Sales'));
        insert testTeamMembers;
    }

    @isTest
    public static void testGetAccountTeamMembers() {
        List<AccountTeamMember> newAccountTeamMembers = [SELECT Id, AccountId FROM AccountTeamMember LIMIT 1];
        Set<Id> newTeamMemberAccountIds = new Map<Id, Account>([SELECT Id FROM Account]).keySet();

        Test.startTest();
        List<AccountTeamMember> accountTeamMember = selector.getAccountTeamMembers(newAccountTeamMembers, newTeamMemberAccountIds);
        Test.stopTest();

        System.assertEquals(false, accountTeamMember.isEmpty(), 'List of AccountTeamMembers should not be empty');
        System.assertEquals(2, accountTeamMember.size(), 'List of AccountTeamMembers should contain 1 record');
        System.assertNotEquals(newAccountTeamMembers[0].AccountId, accountTeamMember[0].Id, 'AccountId of AccountTeamMember should not be equal to Id of newTeamMemberAccountIds');
    }

    @isTest
    public static void testGetAccountTeamMembersWithGlobalAccount() {
        Set<Id> globalAccountIds = new Map<Id, Account>([SELECT Id FROM Account WHERE Named_Account_Segment__c = 'Global Account']).keySet();
        Test.startTest();
        List<AccountTeamMember> accountTeamMembers = selector.getAccountTeamMembersWithGlobalAccount(globalAccountIds, 'Inside Sales');
        Test.stopTest();
        System.assertEquals(false, accountTeamMembers.isEmpty(), 'List of AccountTeamMembers should not be empty');
    }
}