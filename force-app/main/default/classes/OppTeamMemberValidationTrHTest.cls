/****************************************************************************************************************************************************
    Author        :  Tomasz Sadowski
    Description   :  This is a test class for OppTeamMemberValidationTrH.
    Issue No.     :  ST-8827
    History       :
-----------------------------------------------------------------------------------------------------------------------------------------------------
    VERSION        DATE             AUTHOR              Issue       Description
    1              12 Aug 2021      Tomasz Sadowski     ST-8827     Test class for validation of Opportunity Team Member changes
****************************************************************************************************************************************************/
@isTest
private class OppTeamMemberValidationTrHTest {
    private static String OTM_SHOULD_BE_INSERTED = 'Member should be inserted';
    private static String OTM_SHOULD_NOT_BE_INSERTED = 'Member should not be inserted';
    private static String OTM_SHOULD_BE_UPDATED = 'Member should be updated';
    private static String OTM_SHOULD_NOT_BE_UPDATED = 'Member should not be updated';
    private static String OTM_SHOULD_BE_DELETED = 'Member should be deleted';
    private static String OTM_SHOULD_NOT_BE_DELETED = 'Member should not be deleted';

    @testSetup
    private static void setup() {
        Test.startTest();
        Map<String, Object> mapData = new Map<String, Object>{
            'objName' => 'Opportunity',
            'numberOfRecords' => 1,
            'doInsert' => true,
            'mapFieldValues' => new Map<String, List<Object>>{
                'StageName' => new List<Object>{'Closed Won'}
        }};
        Id adminId = Validation_Rule_Restriction__mdt.getInstance('WeWork_System_Administrator').Salesforce_Id__c;
        Id nonAdminId = Validation_Rule_Restriction__mdt.getInstance('WeWork_Interr_Vendor').Salesforce_Id__c ;
        List<User> usersToInsert = new List<User>();
        usersToInsert.add(UtilUser.createUser(adminId, false));
        usersToInsert[0].Username = usersToInsert[0].Email = 'john1admin@example.com';
        usersToInsert.add(UtilUser.createUser(nonAdminId, false));
        usersToInsert[1].Username = usersToInsert[1].Email = 'john2beta@example.com';
        insert usersToInsert;
        System.runAs(usersToInsert[0]) {
            List<Opportunity> opportunities = TestingUtility.getRecords(mapData);
            
            insert new OpportunityShare(
                OpportunityId  = opportunities[0].Id,
                UserOrGroupId = usersToInsert[1].Id,
                RowCause = Schema.OpportunityShare.RowCause.Manual,
                OpportunityAccessLevel = 'Edit'
            );
        }
        
        Test.stopTest();
    }
    
    @isTest
    private static void validateClosedWon() {
        Opportunity testOpp = [SELECT Id, IsWon FROM Opportunity LIMIT 1];
        User testUser = [SELECT Id FROM User WHERE Email = 'john2beta@example.com' LIMIT 1];
        User adminUser = [SELECT Id FROM User WHERE Email = 'john1admin@example.com' LIMIT 1];
        OpportunityTeamMember oppTeamMember = new OpportunityTeamMember(OpportunityId = testOpp.Id, UserId = testUser.Id, TeamMemberRole = 'Billing Associate');
        Database.SaveResult saveResult;
        Database.DeleteResult deleteResult;
        Test.startTest();
        System.runAs(testUser) {
            saveResult = Database.insert(oppTeamMember, false);
        }
        System.assertEquals(false, saveResult.isSuccess(), OTM_SHOULD_NOT_BE_INSERTED);
        
        System.runAs(adminUser) {
            saveResult = Database.insert(oppTeamMember, false);
        }
        System.assertEquals(true, saveResult.isSuccess(), OTM_SHOULD_BE_INSERTED);

        oppTeamMember.TeamMemberRole = 'Assist';
        System.runAs(testUser) {
            saveResult = Database.update(oppTeamMember, false);
        }
        System.assertEquals(false, saveResult.isSuccess(), OTM_SHOULD_NOT_BE_UPDATED);

        System.runAs(adminUser) {
            saveResult = Database.update(oppTeamMember, false);
        }
        System.assertEquals(true, saveResult.isSuccess(), OTM_SHOULD_BE_UPDATED);

        System.runAs(testUser) {
            deleteResult = Database.delete(oppTeamMember, false);
        }
        System.assertEquals(false, deleteResult.isSuccess(), OTM_SHOULD_NOT_BE_DELETED);

        System.runAs(adminUser) {
            deleteResult = Database.delete(oppTeamMember, false);
        }
        System.assertEquals(true, deleteResult.isSuccess(), OTM_SHOULD_BE_DELETED);
        Test.stopTest();
    }
}