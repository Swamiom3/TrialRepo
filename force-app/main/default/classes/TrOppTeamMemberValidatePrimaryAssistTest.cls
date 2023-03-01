/***********************************************************************************************************************
    Author 		: Ashish Sharma
    Description : This is a test class for TrOppTeamMemberValidatePrimaryAssist.
	Issue No. 	: ST-6640
    History		:   
------------------------------------------------------------------------------------------------------------------------
   VERSION         DATE           AUTHOR            DETAIL
      1         27-Aug-2020    Ashish Sharma       ST-6640
***********************************************************************************************************************/
@isTest
public class TrOppTeamMemberValidatePrimaryAssistTest {
    private static final String DUPLICATE_TEAM_MESSAGE = 'Duplicate primary assist team member should not be inserted.';
    private static final String WEWORK_INTERR_VENDOR_PROFILE = 'WeWork Interr Vendor';

    @testSetup
    private static void setup() {
        Account account = TestingUtility.createAccount('Acme', true);
        Opportunity testOpp = TestingUtility.createOpportunity(account.Id, true);
    }
    
    @isTest
    private static void testValidatePrimaryAssist(){
        Test.startTest();
        List<Opportunity> opportunities = [SELECT Id, OwnerId FROM Opportunity];
        User testUser = UtilUser.createUser([SELECT Id FROM Profile WHERE Name = :WEWORK_INTERR_VENDOR_PROFILE].Id, true);
        testPrimaryAssistOnInsert(opportunities, testUser);
        MetadataDrivenTriggerHandler.clearLoopCount('TrOppTeamMemberValidatePrimaryAssist');
        testPrimaryAssistForExistingTeamMember(opportunities, testUser);
        MetadataDrivenTriggerHandler.clearLoopCount('TrOppTeamMemberValidatePrimaryAssist');
        testPrimaryAssistOnUpdate(opportunities, testUser);
        Test.stopTest();
    }
    
    /*******************************************************************************************************************
        Author       : Ashish Sharma
        Description  : Inserting two team members with primary assist true.
        Issue No.    : ST-6640
	*******************************************************************************************************************/
    private static void testPrimaryAssistOnInsert(List<Opportunity> opportunities, User testUser) {
        List<OpportunityTeamMember> oppTeamMembers = new List<OpportunityTeamMember>();       
        oppTeamMembers.add(getOpportunityTeamMember(opportunities[0].Id, testUser.Id, true));
        oppTeamMembers.add(getOpportunityTeamMember(opportunities[0].Id, UserInfo.getUserId(), true));
        try {    
            TestingUtility.insertListWithAssert(oppTeamMembers);
            System.assert(false, DUPLICATE_TEAM_MESSAGE);
        } catch(Exception ex) {
            checkAssert(ex);
        }
    }
    
    /*******************************************************************************************************************
        Author       : Ashish Sharma
        Description  : Insert team member with with primary assist true while one already present.
        Issue No.    : ST-6640
	*******************************************************************************************************************/
    private static void testPrimaryAssistForExistingTeamMember(List<Opportunity> opportunities, User testUser) {
        OpportunityTeamMember oppTeamMemberWithAssist1 = getOpportunityTeamMember(opportunities[0].Id, testUser.Id, true);
        TestingUtility.insertWithAssert(oppTeamMemberWithAssist1);
        OpportunityTeamMember oppTeamMemberWithAssist2 = getOpportunityTeamMember(opportunities[0].Id, UserInfo.getUserId(), true);
        try {
            TestingUtility.insertWithAssert(oppTeamMemberWithAssist2);
            System.assert(false, DUPLICATE_TEAM_MESSAGE);
        } catch(Exception ex) {
            checkAssert(ex);
        }
    }
    
    /*******************************************************************************************************************
        Author       : Ashish Sharma
        Description  : Update the team member with primary assist true while already one with primary assist true.
        Issue No.    : ST-6640
	*******************************************************************************************************************/
    private static void testPrimaryAssistOnUpdate(List<Opportunity> opportunities, User testUser) {
        OpportunityTeamMember oppTeamMemberWithAssist = getOpportunityTeamMember(opportunities[0].Id, testUser.Id, true);
        OpportunityTeamMember oppTeamMemberWithoutAssist = getOpportunityTeamMember(opportunities[0].Id, UserInfo.getUserId(), false);
        List<OpportunityTeamMember> oppTeamMemberToUpdate = new List<OpportunityTeamMember>{oppTeamMemberWithAssist,oppTeamMemberWithoutAssist};
        insert oppTeamMemberToUpdate;
        oppTeamMemberWithoutAssist.Primary_Tour_Assist__c = true;
        try {    
            TestingUtility.updateWithAssert(oppTeamMemberWithoutAssist);
            System.assert(false, DUPLICATE_TEAM_MESSAGE);
        } catch(Exception ex) {
            checkAssert(ex);
        }
    }
    
    private static void checkAssert(Exception ex) {
        System.assert(ex.getMessage().contains(Label.Team_Member_Primary_Assist_Validation_Message), ex.getMessage());
    }
    
    private static OpportunityTeamMember getOpportunityTeamMember(Id opportunityId, Id testUserId, Boolean isPrimaryAssist) {
        return new OpportunityTeamMember(OpportunityId = opportunityId, 
                                         TeamMemberRole = 'Assist', 
                                         UserId =  testUserId, 
                                         OpportunityAccessLevel = 'Read', 
                                         Primary_Tour_Assist__c = isPrimaryAssist);
    }
}