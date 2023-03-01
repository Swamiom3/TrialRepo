/************************************************************************************************************************************
    Author      :   Oleksandr Liesnik	
    Description :   This class contains test methods for TrOpportunityTeamMemberRestrictCoOwner
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION     DATE                AUTHOR                  DETAIL
    1           Feb 21, 2022        Oleksandr Liesnik       Initial version
**************************************************************************************************************************************/
@isTest
public class TrOppTeamMemberRestrictCoOwnerTest {
    
    @TestSetup
    static void makeData(){
        Profile adminProfile = [SELECT Id FROM Profile WHERE Name = 'Wework System Administrator'];
        Account account = TestingUtility.createAccount('Acme', true);
        Opportunity opp = TestingUtility.createOpportunity(account.Id, true);
        List<User> users = UtilUser.createUsers(4, adminProfile.Id, true);
        List<OpportunityTeamMember> oppMembers = new  List<OpportunityTeamMember>();
        OpportunityTeamMember oppMember1 = new OpportunityTeamMember(OpportunityId = opp.Id,
                                                                     UserId = users[0].Id,
                                                                     TeamMemberRole = 'Co-Owner');
        OpportunityTeamMember oppMember2 = new OpportunityTeamMember(OpportunityId = opp.Id,
                                                                     UserId = users[1].Id,
                                                                     TeamMemberRole = 'Inside Sales');
        OpportunityTeamMember oppMember3 = new OpportunityTeamMember(OpportunityId = opp.Id,
                                                                     UserId = users[2].Id,
                                                                     TeamMemberRole = 'Inside Sales');
        oppMembers.add(oppMember1);
        oppMembers.add(oppMember2);
        oppMembers.add(oppMember3);
        TestingUtility.insertListWithAssert(oppMembers);
    }
    
    @isTest
    static void test_negative() {
        List<OpportunityTeamMember> oppMembers = [SELECT Id, OpportunityId, TeamMemberRole FROM OpportunityTeamMember WHERE TeamMemberRole != 'Co-Owner'];    
        oppMembers[0].TeamMemberRole = 'Co-Owner';
        oppMembers[1].TeamMemberRole = 'Co-Owner';
        Exception customException;
        Test.startTest();
        try {
            TestingUtility.updateListWithAssert(oppMembers);
            System.assert(false, 'Exception should be thrown');
        } catch (Exception ex) {
            customException = ex;
        }
        Test.stopTest();
        System.assert(customException.getMessage().contains('Only 2 co-owner(s) is(are) permitted per opportunity team'), 'Opp team has more then two co-owners');
    }

    @isTest
    static void test_positive() {
        Opportunity opp = [SELECT Id, Name FROM Opportunity];
        List<User> users = [SELECT Id, Name FROM User WHERE Name LIKE 'UtilUser_%'];
        OpportunityTeamMember oppMember = new OpportunityTeamMember(OpportunityId = opp.Id,
                                                                    UserId = users[3].Id,
                                                                    TeamMemberRole = 'Co-Owner');
        TestingUtility.insertWithAssert(oppMember);
        List<OpportunityTeamMember> coowners;
        Test.startTest();
        coowners = [SELECT Id, Name FROM OpportunityTeamMember WHERE OpportunityId = :opp.Id AND TeamMemberRole = 'Co-Owner'];
        Test.stopTest();
        System.assertEquals(2, coowners.size(), 'Should be two Opportunity TeamMembers with Co-Owner role');
    }
}