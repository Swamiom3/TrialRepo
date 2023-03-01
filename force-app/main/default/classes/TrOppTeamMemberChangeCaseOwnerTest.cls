/***********************************************************************************************************************
    Author        :  Ashish Sharma
    Description   :  This is a test class for TrOppTeamMemberChangeCaseOwner.
    Issue No.     :  ST-6640
    History       :
------------------------------------------------------------------------------------------------------------------------
    VERSION        DATE          AUTHOR           DETAIL
      1         27-Aug-2020    Ashish Sharma      ST-6640
***********************************************************************************************************************/
@isTest
public class TrOppTeamMemberChangeCaseOwnerTest {

    private static final String WEWORK_INTERR_VENDOR_PROFILE = 'WeWork Interr Vendor';

    @testSetup
    private static void setup() {
        Test.startTest();
        Account account = TestingUtility.createAccount('Acme', true);
        Opportunity testOpp = TestingUtility.createOpportunity(account.Id, true);
        Id loggedInUserId = UserInfo.getUserId();
        Id caseRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Enterprise Finance & Strategy').getRecordTypeId();
        Case objCase = UtilCase.createCaseRelatedToOpp(testOpp.Id, loggedInUserId, caseRecordTypeId, true);
        OpportunityTeamMember oppTeamMember = new OpportunityTeamMember (
            OpportunityId   = testOpp.Id,
            TeamMemberRole = 'Legal Counsel',
            UserId = loggedInUserId
        );
        insert oppTeamMember;
        TestingUtility.insertWithAssert(oppTeamMember);
        Test.stopTest();
    }
    
    @isTest
    private static void changeCaseOwnerTest() {        
        Test.startTest();
        //get current Case Owner
        Id currentOwnerId = [SELECT OwnerId FROM Case].OwnerId;
        User testUser = UtilUser.createUser([SELECT Id FROM Profile WHERE Name = :WEWORK_INTERR_VENDOR_PROFILE].Id, true);
        Opportunity testOpportunity = [SELECT Id, AccountId, (SELECT Id FROM OpportunityTeamMembers) FROM Opportunity LIMIT 1];
        OpportunityTeamMember testOppTeamMember1 = testOpportunity.OpportunityTeamMembers;
        delete testOppTeamMember1;

        OpportunityTeamMember testOppTeamMember2 = new OpportunityTeamMember(
            OpportunityId   = testOpportunity.Id,
            TeamMemberRole = 'Legal Counsel',
            UserId = testUser.Id
        );
        TestingUtility.insertWithAssert(testOppTeamMember2);
        Test.stopTest();
        Case updatedCase = [SELECT OwnerId FROM Case];
        System.assertEquals(currentOwnerId, updatedCase.OwnerId, 'Case owner has not been updated.');
    }
}