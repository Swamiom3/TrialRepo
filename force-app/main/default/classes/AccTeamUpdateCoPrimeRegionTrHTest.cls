@isTest
public class AccTeamUpdateCoPrimeRegionTrHTest {
    public static final String TERRITORY_CO_PRIME = 'Territory Co-Prime';
    public static final String ALL_ACCESS = 'All Access';
    @testSetup
    static void initData(){
        Test.startTest();
        List<Account> accounts = UtilAccount.GetNewAccounts(1, true);
        Region__c region = new Region__c(
            Regional_Sales_Manager__c = UserInfo.getUserId(),
            Name = 'India',
            Region__c = 'India'+String.valueOf(Math.random())
        );
        insert region;
        Territory__c territory = new Territory__c(
            Territory_Sales_Manager__c = UserInfo.getUserId(),
            Name = 'North India',
            RegionID__c = region.Id
        );
        insert territory;
        AccountTeamMember newMember = new AccountTeamMember(
            AccountId = accounts[0].Id,
            UserId = UserInfo.getUserId(),
            TeamMemberRole = ALL_ACCESS,
            Region__c = region.Id,
            Territory__c = territory.Id
        );
        insert newMember;
        Test.stopTest();
    }
    
    @isTest
    public static void verifyUpdateCoPrimeOnAccountOnInsert(){
        Account accountRec = [SELECT Id FROM Account LIMIT 1];
        Region__c region = [SELECT Id FROM Region__c];
        Territory__c territory = [SELECT Id FROM Territory__c];
        AccountTeamMember newMember = new AccountTeamMember(
            AccountId = accountRec.Id,
            UserId = UserInfo.getUserId(),
            TeamMemberRole = TERRITORY_CO_PRIME,
            Region__c = region.Id,
            Territory__c = territory.Id
        );
        Test.startTest();
        insert newMember;
        Account account = [SELECT Id, Co_Prime_Region__c, Co_Prime__c FROM Account LIMIT 1];
		System.assertEquals(account.Co_Prime__c, true);
        System.assertEquals(account.Co_Prime_Region__c, 'India', 'Co_Prime_Region should be autopopulated with respective region');
        Test.stopTest();
    }
    
    @isTest
    public static void verifyUpdateCoPrimeOnAccountOnUpdate(){
        AccountTeamMember teamMember = [SELECT Id, TeamMemberRole From AccountTeamMember LIMIT 1];
        teamMember.TeamMemberRole = TERRITORY_CO_PRIME;
        Account accBeforeUpdateMember = [SELECT Id, Co_Prime_Region__c, Co_Prime__c FROM Account LIMIT 1];
        System.assertEquals(accBeforeUpdateMember.Co_Prime__c, false);
        System.assertEquals(accBeforeUpdateMember.Co_Prime_Region__c, null, 'Co_Prime_Region should be null');
        update teamMember ;
        Account accAfterUpdateMember = [SELECT Id, Co_Prime_Region__c, Co_Prime__c FROM Account LIMIT 1];
        System.assertEquals(accAfterUpdateMember.Co_Prime__c, true);
        System.assertEquals(accAfterUpdateMember.Co_Prime_Region__c, 'India', 'Co_Prime_Region should be autopopulated with respective region');
    }
}