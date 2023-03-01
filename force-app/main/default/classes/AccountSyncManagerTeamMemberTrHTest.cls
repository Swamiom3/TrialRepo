@isTest
public class AccountSyncManagerTeamMemberTrHTest {
    private static final String WEWORK_SYSADM_PROFILE = 'System Administrator';
    private static User suppOpsUser = [SELECT Id FROM User WHERE Profile.Name = :WEWORK_SYSADM_PROFILE AND isActive = true LIMIT 1];
    private static final String ACC_ACCESS_LEVEL = 'Edit';
    private static final String ACC_MNGR_ROLE = 'Account Manager';
    private static final String INSIDE_SALES_ROLE = 'Inside Sales';
    
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

        
        List<AccountTeamMember> accTeamMembersToInsert = new List<AccountTeamMember>();
        accTeamMembersToInsert.add(new AccountTeamMember(UserId = suppOpsUser.Id, AccountId = parentOrgAccounts[0].Id, TeamMemberRole = INSIDE_SALES_ROLE));
        accTeamMembersToInsert.add(new AccountTeamMember(UserId = UserInfo.getUserId(), AccountId = parentOrgAccounts[1].Id, TeamMemberRole = ACC_MNGR_ROLE));
        //set bypass as normally not allowed to set manager team role manually 
        SObjectTriggerHandler.bypass('AccountTeamMemberValidationTrH');
        insert accTeamMembersToInsert;  
        SObjectTriggerHandler.clearAllBypasses();
    }
    
    @isTest
    private static void testAccTeamInsertOnAccOwnerChange() {
        Account accWithTeam = TestingUtility.createAccount(new Map<String,Object>{'Name' => 'Parent Account 3', 
            'UUID__c' => 'parent-UUID-003', 
            'Account_Type__c' => 'Org'}, false);
        
        List<Account> accounts = getTestAccounts();
        for(Account accRec: accounts){
            accRec.Account_Manager_Lookup__c = suppOpsUser.Id;
        } 
        Test.startTest();
        accWithTeam.Account_Manager_Lookup__c = suppOpsUser.Id;
        insert accWithTeam;
        update accounts;
        Test.stopTest();
        List<Account> accountsWithItsTeamMembers = getTestAccounts();
        verifyAccountTeamMembersCount(accountsWithItsTeamMembers);
    }
    
    private static List<Account> getTestAccounts(){
        return [SELECT Id, Name, Account_Manager_Lookup__c, (SELECT Id, UserId, AccountId, AccountAccessLevel,TeamMemberRole FROM AccountTeamMembers) FROM Account];
    }
    
    private static  void  verifyAccountTeamMembersCount(List<Account> accounts){  
        for(Account accRec: accounts){
            System.assert(accRec.AccountTeamMembers.size() == 1, 'Account Team Member record should be created');
        }    
    }
}