/**********************************************************************************************************
    Author        :  Ashish Sharma
    Description   :  This is a test class for OppTeamMemberValidateMembers.
    Issue No.     :  ST-7390
    History       :
-----------------------------------------------------------------------------------------------------------
    VERSION        DATE          AUTHOR           DETAIL
      1         26-Mar-2021    Ashish Sharma      ST-8013
**********************************************************************************************************/
@isTest
private class OppTeamMemberValidateMembersTrHTest {
    @testSetup
    private static void setup() {
        Test.startTest();
        Id nmdBetaId = Validation_Rule_Restriction__mdt.getInstance('WeWork_Inside_Sales').Salesforce_Id__c;
        Id wwSysAdmId = Validation_Rule_Restriction__mdt.getInstance('System_Administrator').Salesforce_Id__c;
        
        List<User> usersToInsert = new List<User>();
        usersToInsert.addAll(UtilUser.createUsers(4, nmdBetaId, false));
        usersToInsert.addAll(UtilUser.createUsers(1, wwSysAdmId, false));
        usersToInsert[0].Username = usersToInsert[0].Email = 'john2beta@example.com';
        usersToInsert[1].Username = usersToInsert[1].Email = 'john3beta@example.com';
        usersToInsert[2].Username = usersToInsert[2].Email = 'john4beta@example.com';
        usersToInsert[3].Username = usersToInsert[3].Email = 'john5beta@example.com';
        usersToInsert[4].Username = usersToInsert[4].Email = 'wwadm333@example.com';
        insert usersToInsert;
        
        Opportunity opportunities = TestingUtility.createOpportunity(new Map<String,Object>(), true);
        
        Test.stopTest();
    }

    @isTest
    private static void validateAllAccessMembersInsert() {
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];
        List<User> testUsers = [SELECT Id FROM User WHERE Email LIKE '%beta@example.com'];

        List<OpportunityTeamMember> oppTeamMembers = new List<OpportunityTeamMember>();       
        oppTeamMembers.add(new OpportunityTeamMember(OpportunityId = testOpp.Id, UserId = testUsers[0].Id, TeamMemberRole = 'All Access'));
        oppTeamMembers.add(new OpportunityTeamMember(OpportunityId = testOpp.Id, UserId = testUsers[1].Id, TeamMemberRole = 'Inside Sales'));
        oppTeamMembers.add(new OpportunityTeamMember(OpportunityId = testOpp.Id, UserId = testUsers[2].Id, TeamMemberRole = 'Account Manager'));
        oppTeamMembers.add(new OpportunityTeamMember(OpportunityId = testOpp.Id, UserId = testUsers[3].Id, TeamMemberRole = 'All Access'));
        List<Database.SaveResult> results;
        Test.startTest();
        System.runAs([SELECT Id FROM User WHERE Email = 'wwadm333@example.com'][0]) {
            results = Database.insert(oppTeamMembers, false);
        }
        Test.stopTest();

        System.assertEquals(false, results[0].isSuccess());
        System.assertEquals(true, results[1].isSuccess(), 'Member should be inserted');
        System.assertEquals(true, results[2].isSuccess(), 'Member should be inserted');
        System.assertEquals(false, results[3].isSuccess());
    }

    @isTest
    private static void validateAllAccessMembersUpdate() {
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];
        List<User> testUsers = [SELECT Id FROM User WHERE Email LIKE '%beta@example.com'];
        
        List<OpportunityTeamMember> oppTeamMembers = new List<OpportunityTeamMember>();       
        oppTeamMembers.add(new OpportunityTeamMember(OpportunityId = testOpp.Id, UserId = testUsers[0].Id, TeamMemberRole = 'All Access'));
        oppTeamMembers.add(new OpportunityTeamMember(OpportunityId = testOpp.Id, UserId = testUsers[1].Id, TeamMemberRole = 'Inside Sales'));
        oppTeamMembers.add(new OpportunityTeamMember(OpportunityId = testOpp.Id, UserId = testUsers[2].Id, TeamMemberRole = 'Account Manager'));
        List<Database.SaveResult> results;
        Database.SaveResult result;
        Test.startTest();
        System.runAs([SELECT Id FROM User WHERE Email = 'wwadm333@example.com'][0]) {
            results = Database.insert(oppTeamMembers, false);

            oppTeamMembers[1].TeamMemberRole = 'All Access';
            result = Database.update(oppTeamMembers[1], false);
        }

        Test.stopTest();
    
        System.assertEquals(false, result.isSuccess());
    }
}