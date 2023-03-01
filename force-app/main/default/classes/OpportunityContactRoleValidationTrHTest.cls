@isTest
public class OpportunityContactRoleValidationTrHTest {    

    @isTest
    public static void testUpdateOpportunityRole() {
        Map<String, Id> oppRecordType = TestingUtility.getRecordTypeMapByName(Opportunity.SObjectType);

        Account accRec = TestingUtility.createAccount('strAccountName', true);
        System.assertNotEquals(null, accRec.Id, 'Account should have been created');
        
        Contact conRec1 = new Contact(
            FirstName  = 'John',
            LastName   = 'Rambo',
            Email     = 'testContact1@example.com',
            AccountId  = accRec.Id
        );
        insert conRec1;
        System.assertNotEquals(null, conRec1.Id, 'Contact should have been created');
        
        Opportunity oppRec1 = TestingUtility.createOpportunity(accRec.Id, false);
        oppRec1.Primary_Member__c = conRec1.Id;
        oppRec1.StageName = 'Qualifying';
        oppRec1.CloseDate = system.today().addDays(5);
        oppRec1.Amount = 150;
        oppRec1.RecordTypeId = oppRecordType.get('New Business');
        TestingUtility.insertWithAssert(oppRec1);
        System.assertNotEquals(null, oppRec1.Id, 'Opportunity should have been created');
        
        
        List<OpportunityContactRole> opportunityRoles = [SELECT Id, OpportunityId, ContactId, IsPrimary, Role FROM OpportunityContactRole WHERE OpportunityId =:oppRec1.Id];
        System.assertEquals(1, opportunityRoles.size(), 'There should be only one child role created for the opportunity');
        System.assertEquals(oppRec1.Id, opportunityRoles[0].OpportunityId, 'Role is not created for proper opportunity');
        System.assertEquals(conRec1.Id, opportunityRoles[0].ContactId, 'Role is not created for proper contact');
        System.assert(opportunityRoles[0].IsPrimary, 'Role created should be primary for opportunity');
        System.assertEquals(GlobalConstants.OPP_CONTACT_ROLE_MAIN_CONTACT, opportunityRoles[0].Role, 'Role should be equal to \'Main Contact\'');
        
        OpportunityContactRole oppRoleRec1 = new OpportunityContactRole(
            OpportunityId = opportunityRoles[0].OpportunityId,
            ContactId = opportunityRoles[0].ContactId,
            IsPrimary = true,
            Role = 'Primary Role'
        );
        
        try {
            insert oppRoleRec1;
        } catch(Exception e){
            System.assert(e instanceof DmlException, 'Thrown exception is not of correct type');
            Boolean expectedExceptionThrown = e.getMessage().contains(Label.Opportunity_Contact_Role_Same_Parents_Error_Message);
            System.assert(expectedExceptionThrown, 'Validation error message is not correct');
        }	    
        
        opportunityRoles = [SELECT Id, OpportunityId, ContactId, IsPrimary, Role FROM OpportunityContactRole WHERE OpportunityId =:oppRec1.Id];
        System.assertEquals(1, opportunityRoles.size(), 'There should be only one child role created for the opportunity');
        System.assertEquals(oppRec1.Id, opportunityRoles[0].OpportunityId, 'Role is not created for proper opportunity');
        System.assertEquals(conRec1.Id, opportunityRoles[0].ContactId, 'Role is not created for proper contact');
        System.assertEquals(true, opportunityRoles[0].IsPrimary, 'Role created should be primary for opportunity');
        oppRoleRec1 = opportunityRoles[0];
        
        Contact conRec2 = new Contact(
            FirstName  = 'John',
            LastName   = 'Rambo',
            Email     = 'testContact2@example.com',
            AccountId  = accRec.Id
        );
        insert conRec2;
        System.assertNotEquals(null, conRec2.Id, 'Contact should have been created');
        
        OpportunityContactRole oppRoleRec2 = new OpportunityContactRole(
            OpportunityId = oppRec1.Id,
            ContactId = conRec2.Id,
            IsPrimary = true,
            Role = 'Primary Role'
        );
        insert oppRoleRec2;
        System.assertNotEquals(null, oppRoleRec2.Id, 'Opportunity contact role should have been created');
        
        opportunityRoles = [SELECT Id, OpportunityId, ContactId, IsPrimary, Role FROM OpportunityContactRole WHERE OpportunityId =:oppRec1.Id];
        System.assertEquals(2, opportunityRoles.size(), 'There should be two child roles created for the opportunity');
        for (OpportunityContactRole oppRole : opportunityRoles) {
            if (conRec1.Id == oppRole.ContactId) {
                System.assert(!oppRole.IsPrimary, 'Role created must not be primary for opportunity');
            } else if (conRec2.Id == oppRole.ContactId) {
                System.assert(oppRole.IsPrimary, 'Role created must be primary for opportunity');
            }
        }
        
        oppRoleRec1.IsPrimary = true;
        update oppRoleRec1;
        
        opportunityRoles = [SELECT Id, OpportunityId, ContactId, IsPrimary, Role FROM OpportunityContactRole WHERE  OpportunityId =:oppRec1.Id];
        System.assertEquals(2, opportunityRoles.size(), 'There should be two child roles created for the opportunity');
        for (OpportunityContactRole oppRole : opportunityRoles) {
            if (conRec1.Id == oppRole.ContactId) {
                System.assert(oppRole.IsPrimary, 'Role created must be primary for opportunity');
            } else if(conRec2.Id == oppRole.ContactId) {
                System.assert(!oppRole.IsPrimary, 'Role created must not be primary for opportunity');
            }
        }
        oppRoleRec1.ContactId = conRec2.Id;
        oppRoleRec1.IsPrimary = true;
        try {
            update oppRoleRec1;
        } catch (Exception e) {
            System.assert(e instanceof DmlException, 'Thrown exception is not of correct type');
            Boolean expectedExceptionThrown =  e.getMessage().contains(Label.Opportunity_Contact_Role_Same_Parents_Error_Message);
            System.assert(expectedExceptionThrown, 'Validation error message is not correct');
        }	
    } 
}