@isTest
public class BuildingSetOpportunityContactTeamTrHTest {    
    @testSetup
    static void makeData(){
        Account account = TestingUtility.createAccount('strAccountName', true);
        
        Contact contact = TestingUtility.createContact(new Map<String, Object>{
            'FirstName' => 'John', 
            'LastName' => 'Rambo', 
            'Email' => 'testContact1@example.com',
            'AccountId' => account.Id
        }, false);
        
        Contact contact2 = TestingUtility.createContact(new Map<String, Object>{
            'FirstName' => 'John2', 
            'LastName' => 'Rambo2', 
            'Email' => 'testContact2@example.com',
            'AccountId' => account.Id
        }, false);
        
        Contact contact3 = TestingUtility.createContact(new Map<String, Object>{
            'FirstName' => 'John3', 
            'LastName' => 'Rambo3', 
            'Email' => 'testContact3@example.com',
            'AccountId' => account.Id
        }, false);

        List<Contact> contacts = new List<Contact>();
        contacts.add(contact);
        contacts.add(contact2);
        contacts.add(contact3);

        TestingUtility.insertListWithAssert(contacts);
        
        Building__c building = TestingUtility.createBuilding(new Map<String, Object>{
            'Name' => 'Test Building 1',
            'UUID__c' => 'building-0001-0001'
        }, false);

        Building__c building2 = TestingUtility.createBuilding(new Map<String, Object>{
            'Name' => 'Test Building 2',
            'UUID__c' => 'building-0001-0002',
            'Agency_broker__c' => contact2.Id
        }, false);

        List<Building__c> buildings = new List<Building__c>();
        buildings.add(building);
        buildings.add(building2);

        TestingUtility.insertListWithAssert(buildings);

        Opportunity opportunity = TestingUtility.createOpportunity(account.Id, false);
        opportunity.Primary_Member__c = contact.Id;
        opportunity.CloseDate = system.today().addDays(5);
        opportunity.Building__c = building.Id;

        Opportunity opportunity2 = TestingUtility.createOpportunity(account.Id, false);
        opportunity2.Primary_Member__c = contact.Id;
        opportunity2.CloseDate = system.today().addDays(5);
        opportunity2.Building__c = building2.Id;
        opportunity2.Opportunity_Creation_Source__c = GlobalConstants.OPPORTUNITY_CREATION_SOURCE_VTS;

        List<Opportunity> opportunities = new List<Opportunity>();
        opportunities.add(opportunity);
        opportunities.add(opportunity2);

        TestingUtility.insertListWithAssert(opportunities);
    }

    @isTest
    public static void testUpdateOpportunityRole() {
        Building__c building = [SELECT Id FROM Building__c WHERE UUID__c = 'building-0001-0001' LIMIT 1];
        List<Contact> contacts = [SELECT Id FROM Contact];
        Opportunity opportunity = [SELECT Id FROM Opportunity WHERE Building__c = :building.Id LIMIT 1];

        Test.startTest();
        building.Agency_broker__c = contacts[1].Id;
        update building;
        Test.stopTest();

        List<OpportunityContactRole> opportunityContactRoles = [
            SELECT OpportunityId, ContactId, Role, IsPrimary
            FROM OpportunityContactRole
            WHERE OpportunityId = :opportunity.Id
            ORDER BY CreatedDate
            LIMIT 50000
        ];

        System.assertEquals(2, opportunityContactRoles.size(), 'Opportunity contact role should be created when Agency Broker field has value');
        System.assertEquals(GlobalConstants.OPP_CONTACT_ROLE_MAIN_CONTACT, opportunityContactRoles[0].Role,
                            'Opportunity contact role should be ' + GlobalConstants.OPP_CONTACT_ROLE_MAIN_CONTACT);
        System.assertEquals(GlobalConstants.OPP_CONTACT_ROLE_AGENCY_BROKER, opportunityContactRoles[1].Role,
                            'Opportunity contact role should be ' + GlobalConstants.OPP_CONTACT_ROLE_AGENCY_BROKER);

        building.Agency_Broker__c = contacts[0].Id;
        update building;
        
        opportunityContactRoles = [
            SELECT OpportunityId, ContactId, Role, IsPrimary
            FROM OpportunityContactRole
            WHERE OpportunityId = :opportunity.Id
            ORDER BY CreatedDate
            LIMIT 50000
        ];

        System.assertEquals(1, opportunityContactRoles.size(), 'There should be 1 contact role only');
        System.assertEquals(GlobalConstants.OPP_CONTACT_ROLE_MAIN_CONTACT, opportunityContactRoles[0].Role,
                            'Opportunity contact role should be ' + GlobalConstants.OPP_CONTACT_ROLE_MAIN_CONTACT);

        SObjectTriggerHandler.clearLoopCount();

        building.Agency_broker__c = contacts[2].Id;
        update building;

        opportunityContactRoles = [
            SELECT OpportunityId, ContactId, Role, IsPrimary
            FROM OpportunityContactRole
            WHERE OpportunityId = :opportunity.Id
            ORDER BY CreatedDate
            LIMIT 50000
        ];

        System.assertEquals(2, opportunityContactRoles.size(), 'Opportunity contact role should be created when Agency Broker field has value');
        System.assertEquals(GlobalConstants.OPP_CONTACT_ROLE_MAIN_CONTACT, opportunityContactRoles[0].Role,
                            'Opportunity contact role should be ' + GlobalConstants.OPP_CONTACT_ROLE_MAIN_CONTACT);
        System.assertEquals(GlobalConstants.OPP_CONTACT_ROLE_AGENCY_BROKER, opportunityContactRoles[1].Role,
                            'Opportunity contact role should be ' + GlobalConstants.OPP_CONTACT_ROLE_AGENCY_BROKER);

        building.Agency_Broker__c = contacts[1].Id;
        update building;
        
        opportunityContactRoles = [
            SELECT OpportunityId, ContactId, Role, IsPrimary
            FROM OpportunityContactRole
            WHERE OpportunityId = :opportunity.Id
            ORDER BY CreatedDate
            LIMIT 50000
        ];

        System.assertEquals(2, opportunityContactRoles.size(), 'There should remain 2 contacts roles');
        System.assertEquals(GlobalConstants.OPP_CONTACT_ROLE_MAIN_CONTACT, opportunityContactRoles[0].Role,
                            'Opportunity contact role should be ' + GlobalConstants.OPP_CONTACT_ROLE_MAIN_CONTACT);
        System.assertEquals(GlobalConstants.OPP_CONTACT_ROLE_AGENCY_BROKER, opportunityContactRoles[1].Role, 
                            'Opportunity contact role should be ' + GlobalConstants.OPP_CONTACT_ROLE_AGENCY_BROKER);
    } 

    @isTest
    public static void testUpdateOpportunityRoleNegative() {
        Building__c building = [SELECT Id FROM Building__c WHERE UUID__c = 'building-0001-0002' LIMIT 1];
        Opportunity opportunity = [SELECT Id FROM Opportunity WHERE Building__c = :building.Id LIMIT 1];
        
        List<OpportunityContactRole> opportunityContactRoles = [
            SELECT OpportunityId, ContactId, Role, IsPrimary
            FROM OpportunityContactRole
            WHERE OpportunityId = :opportunity.Id AND Role = :GlobalConstants.OPP_CONTACT_ROLE_AGENCY_BROKER
            ORDER BY CreatedDate
            LIMIT 50000
        ];

        for (OpportunityContactRole item : opportunityContactRoles) {
            item.Role = GlobalConstants.OPP_CONTACT_ROLE_BUSINESS_USER;
        } 

        try {
            update opportunityContactRoles;
            System.assert(false, Label.BuildingAgencyBrokerValidationError + ' error shold be thrown');
        } catch (Exception ex) {
            System.assertEquals(true, ex.getMessage().contains(Label.BuildingAgencyBrokerValidationError), Label.BuildingAgencyBrokerValidationError + ' error shold be thrown');
        }
    }

}