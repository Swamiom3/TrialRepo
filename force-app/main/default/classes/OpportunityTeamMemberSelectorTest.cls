@isTest
public class OpportunityTeamMemberSelectorTest {
    private static OpportunityTeamMemberSelector selector = new OpportunityTeamMemberSelector();

    @testSetup
    static void makeData() {
        List<Account> testAccounts = UtilAccount.GetNewAccounts(1, true);
        List<Opportunity> testOpps = new List<Opportunity>();
        List<OpportunityTeamMember> testTeamMembers = new List<OpportunityTeamMember>();

        for (Account testAccount : testAccounts) {
            testOpps.addAll(UtilOpportunity.getNewOpportunity(1, testAccount, false));
        }
        insert testOpps;
        
        for (Opportunity testOpp : testOpps) {
            testTeamMembers.add(new OpportunityTeamMember(OpportunityId = testOpp.Id, UserId = UserInfo.getUserId()));
        }
        insert testTeamMembers;
    }

    @isTest
    public static void testGetOpportunityTeamMembersOnAccOwnerChange() {
        Set<Id> opportunityIds = new Map<Id, Opportunity>([SELECT Id FROM Opportunity]).keySet();
        Set<Id> ownerChangedAccountIds = new Map<Id, Account>([SELECT Id FROM Account]).keySet();

        Test.startTest();
        List<OpportunityTeamMember> opportunityTeamMember = selector.getOpportunityTeamMembersOnAccOwnerChange(opportunityIds, ownerChangedAccountIds);
        Test.stopTest();

        System.assertEquals(false, opportunityTeamMember.isEmpty(), 'List of OpportunityTeamMembers should not be empty');
        System.assertEquals(1, opportunityTeamMember.size(), 'List of OpportunityTeamMembers should contain 1 record');
        System.assertEquals(new List<Id>(opportunityIds)[0], opportunityTeamMember[0].OpportunityId, 'Id of OpportunityTeamMembers should be equal to Id of opportunityIds');
    }

    @isTest
    public static void testGetExistingOpportunityTeamMemberIds() {
        Set<Id> opportunityIds = new Map<Id, Opportunity>([SELECT Id FROM Opportunity]).keySet();
        Test.startTest();
        List<OpportunityTeamMember> oppTeamMembers = selector.getExistingOpportunityTeamMemberIds(opportunityIds);
        Test.stopTest();
        System.assertEquals(false, oppTeamMembers.isEmpty(), 'List of OpportunityTeamMembers should not be empty');
    }
}