@isTest
public class AccountPreventTeamMemberDeleteTrHTest {
    private static Profile weworkSystemAdminProfile = [SELECT Id FROM Profile WHERE Name = 'WeWork System Administrator'];
    private static User weworkSystemAdminUser = TestingUtility.insertUserWithAssert(weworkSystemAdminProfile.Id, new Map<String, object> {'Email'=>'user16102019001@example.com'}, true);
    private static Profile weworkSuppotProfile = [SELECT Id FROM Profile WHERE Name = 'WeWork Support & Operations'];
    private static User weworkSuppotUser = TestingUtility.insertUserWithAssert(weworkSuppotProfile.Id, new Map<String, object> {'Email'=>'user16102019002@example.com'}, true);
    
    @testSetup
    private static void setupTestData() {
        List<Account> parentOrgAccounts = new List<Account>();
        parentOrgAccounts.add(TestingUtility.createAccount(new Map<String,Object>{'Name' => 'Parent Account 1', 
            'UUID__c' => 'parent-UUID-001',
            'Account_Type__c' => 'Org'}, false));
        parentOrgAccounts.add(TestingUtility.createAccount(new Map<String,Object>{'Name' => 'Parent Account 2', 
            'UUID__c' => 'parent-UUID-002',
            'Account_Type__c' => 'Org'}, false));
        insert parentOrgAccounts;
        
        List<AccountTeamMember> accTeamMembersToInsert = new List<AccountTeamMember>();
        accTeamMembersToInsert.add(new AccountTeamMember(UserId = weworkSystemAdminUser.Id, AccountId = parentOrgAccounts[0].Id, TeamMemberRole = 'Inside Sales'));
        accTeamMembersToInsert.add(new AccountTeamMember(UserId = UserInfo.getUserId(), AccountId = parentOrgAccounts[0].Id, TeamMemberRole = 'Legal'));
        accTeamMembersToInsert.add(new AccountTeamMember(UserId = weworkSuppotUser.Id, AccountId = parentOrgAccounts[1].Id, TeamMemberRole = 'Inside Sales'));
        accTeamMembersToInsert.add(new AccountTeamMember(UserId = weworkSystemAdminUser.Id, AccountId = parentOrgAccounts[1].Id, TeamMemberRole = 'Legal'));
        insert accTeamMembersToInsert;
    }
    
    @isTest
    private static void verifyPreventAccTeamMemberDeleteOnAccOwnerChange() {
        List<Account> accounts = getAccountWithTeamMembers();
        verifyAccountTeamMembersCount(accounts, false);
        for (Account accRec: accounts) {
            accRec.OwnerId = accRec.Name == 'Parent Account 1' ? accRec.OwnerId = weworkSystemAdminUser.Id : UserInfo.getUserId();
        }
        Test.startTest();
        update accounts;
        Test.stopTest();
        List<Account> accountsWithItsTeamMembers = getAccountWithTeamMembers();
        System.assert(!accountsWithItsTeamMembers.isEmpty());
        verifyAccountTeamMembersCount(accountsWithItsTeamMembers, true);
    }
    
    private static List<Account> getAccountWithTeamMembers() {
        return [SELECT Id, Name, (SELECT Id, UserId, AccountId FROM AccountTeamMembers) FROM Account];
    }
    
    private static List<Account> verifyAccountTeamMembersCount(List<Account> accounts, Boolean isAfter) {  
        for (Account accRec: accounts) {
            if (isAfter && accRec.Name == 'Parent Account 1') {
                System.assert(accRec.AccountTeamMembers.size() == 0, 'No Account Team Member records should be created');
            } else {
                System.assert(accRec.AccountTeamMembers.size() == 2, '2 Account Team Member records should be created');   
            }
        }  
        return accounts;
    }
}