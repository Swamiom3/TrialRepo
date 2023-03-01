/*************************************************************************************************************************************
Description :   This class provides sufficient test coverage for OpportunityContactRoleSelector class
--------------------------------------------------------------------------------------------------------------------------------------
VERSION         DATE            AUTHOR                   DETAIL
1               10/19/2021      Oleksandr Liesnik        Initial Deployment
**************************************************************************************************************************************/
@isTest
public with sharing class OpportunityContactRoleSelectorTest {

    private static OpportunityContactRoleSelector oppContactRoleSelector = new OpportunityContactRoleSelector();
    private static final String TEST_OPP_CON_ROLE_NAME = 'Test Opportunity Contact Role';

    @testSetup
    static void makeData() {
        Account testAccount = TestingUtility.createAccount('Acme', true);
        Contact testContact = TestingUtility.createContact(new Map<String,Object>{'LastName' => 'TestAccount',
                                                                                  'AccountId' => testAccount.Id},
                                                                                  true);
        Opportunity testOpportunity = TestingUtility.createOpportunity(testAccount.Id, true);
        OpportunityContactRole oppContactRole = new OpportunityContactRole(OpportunityId = testOpportunity.Id,
                                                                           ContactId = testContact.Id,
                                                                           Role = TEST_OPP_CON_ROLE_NAME);
        insert oppContactRole;
    }

    @isTest
    public static void testGetOpportunityContactRolesByOppIdsAndRole() {
        Id opportunityId = [SELECT Id FROM Opportunity].Id;

        Test.startTest();
        OpportunityContactRole oppContactRole = oppContactRoleSelector.getOpportunityContactRolesByOppIdsAndRole(new Set<Id>{opportunityId},
                TEST_OPP_CON_ROLE_NAME)[0];
        Test.stopTest();

        System.assertEquals(TEST_OPP_CON_ROLE_NAME, oppContactRole.Role, 'Opportunity Contact Role should be ' + TEST_OPP_CON_ROLE_NAME);
    }

    @isTest
    public static void shouldGetEmptyListForNullList() {
        List<OpportunityContactRole> oppContactRoles;

        Test.startTest();
        oppContactRoles = oppContactRoleSelector.getOpportunityContactRolesByOppIdsAndRole(null,
                                                                                           TEST_OPP_CON_ROLE_NAME);
        Test.stopTest();

        System.assert(oppContactRoles.isEmpty(), 'List should be empty');
    }

    @isTest
    public static void testGetOpportunityContactRolesByOppIds() {
        Id opportunityId = [SELECT Id FROM Opportunity].Id;
        List<OpportunityContactRole> oppContactRoles;

        Test.startTest();
        oppContactRoles = oppContactRoleSelector.getOpportunityContactRolesByOppIds(new Set<Id>{opportunityId});
        Test.stopTest();

        System.assert(!oppContactRoles.isEmpty(), 'Should contain records');
        System.assertEquals(TEST_OPP_CON_ROLE_NAME, oppContactRoles[0].Role, 'Opportunity Contact Role should be ' + TEST_OPP_CON_ROLE_NAME);
    }

    @isTest
    public static void testGetOpportunityContactRolesByOpportunityAndContact() {
        Id opportunityId = [SELECT Id FROM Opportunity].Id;
        Id contactId = [SELECT Id FROM Contact].Id;

        Test.startTest();
        List<OpportunityContactRole> rolesOk = oppContactRoleSelector.getOpportunityContactRolesByOpportunityAndContact(opportunityId, contactId);
        List<OpportunityContactRole> rolesEmptyParameter = oppContactRoleSelector.getOpportunityContactRolesByOpportunityAndContact(opportunityId, null);
        List<OpportunityContactRole> rolesFakeId = oppContactRoleSelector.getOpportunityContactRolesByOpportunityAndContact(TestUtility.getFakeId(Opportunity.SObjectType), contactId);
        Test.stopTest();

        System.assertEquals(1, rolesOk.size(), 'Opportunity contact record must be retrieved for existing opportunity and contact');
        System.assert(rolesEmptyParameter.isEmpty(), 'No records must be returned for empty parameter');
        System.assert(rolesFakeId.isEmpty(), 'No records must be returned for non existing Id');
    }
}