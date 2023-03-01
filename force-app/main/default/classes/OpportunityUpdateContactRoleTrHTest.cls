/*************************************************************************************************************************************
    Author      :   Pawel Biszczak
    Description :   This class provides sufficient test coverage for OpportunityUpdateContactRoleTrH class
    --------------------------------------------------------------------------------------------------------------------------------------
    VERSION    DATE            AUTHOR             DETAIL
    1          14 Feb, 2022    Pawel Biszczak     Initial Deployment
**************************************************************************************************************************************/
@isTest
public with sharing class OpportunityUpdateContactRoleTrHTest {

    @isTest
    private static void shouldCreateOpportunityRolesOnDML(){
        Account testAccount = TestingUtility.createAccount('Acme', true);
        Contact firstContact = TestingUtility.createContact(testAccount.Id, 'Doe', false);
        firstContact.Email = 'referral@email.com';
        Contact secondContact = TestingUtility.createContact(testAccount.Id, 'Doe2', false);
        secondContact.Email = 'referral2@email.com';
        insert new List<SObject>{firstContact, secondContact};
        Opportunity testOpportunity = TestingUtility.createOpportunity(testAccount.Id, false);
        testOpportunity.Primary_Member__c = firstContact.Id;
        insert testOpportunity;

        Test.startTest();
        List<OpportunityContactRole> opportunityRoles = [ SELECT Id, Role
                                                          FROM OpportunityContactRole ];
        System.assertEquals(1, opportunityRoles.size(),
                            'One OpportunityContactRole record should be created');
        opportunityRoles = [ SELECT Id, Role
                             FROM OpportunityContactRole ];
        testOpportunity.Primary_Member__c = secondContact.Id;
        update testOpportunity;
        opportunityRoles= [ SELECT Id, Role
                            FROM OpportunityContactRole ];
        Test.stopTest();

        System.assertEquals(2, opportunityRoles.size(),
                            'Two OpportunityContactRole record should be created');
    }

    @isTest
    private static void shouldCreateContactRolesForUpdate(){
        List<Opportunity> opportunities = getFakeOpportunities();
        List<Contact> contacts = getFakeContacts();
        opportunities[0].Primary_Member__c = contacts[0].Id;
        opportunities[1].Primary_Member__c = contacts[1].Id;
        OpportunityUpdateContactRoleTrH handlerInstance;

        Test.startTest();
        handlerInstance = new OpportunityUpdateContactRoleTrH();
        handlerInstance.newOpportunities = opportunities;
        handlerInstance.prepareOpportunityContactRolesOnInsert();
        Test.stopTest();

        System.assertEquals(2, handlerInstance.opportunityRolesForUpsert.size(),
                            'Two OpportunityContactRole records should be created');
    }
    @isTest
    private static void shouldNotCreateContactRolesForUpdate(){
        List<Opportunity> opportunities = getFakeOpportunities();
        List<Contact> contacts = getFakeContacts();
        opportunities[0].Primary_Member__c = null;
        opportunities[1].Primary_Member__c = contacts[0].Id;
        opportunities[1].Do_Not_Create_Opportunity_Role__c = true;
        OpportunityUpdateContactRoleTrH handlerInstance;

        Test.startTest();
        handlerInstance = new OpportunityUpdateContactRoleTrH();
        handlerInstance.newOpportunities = opportunities;
        handlerInstance.prepareOpportunityContactRolesOnInsert();
        Test.stopTest();

        System.assert(handlerInstance.opportunityRolesForUpsert.isEmpty(),
                      'OpportunityContactRole record should be not created');
    }

    static List<Opportunity> getFakeOpportunities() {
        Map<String, Object> recordsData = new Map<String, Object>();
        recordsData = new Map<String, Object>();
        recordsData.put('objectName', 'Opportunity');
        recordsData.put('numberOfRecords', 2);
        return MockTestingUtility.getRecords(recordsData, true);
    }

    static List<Contact> getFakeContacts() {
        Map<String, Object> recordsData = new Map<String, Object>();
        recordsData = new Map<String, Object>();
        recordsData.put('objectName', 'Contact');
        recordsData.put('numberOfRecords', 2);
        return MockTestingUtility.getRecords(recordsData, true);
    }
}