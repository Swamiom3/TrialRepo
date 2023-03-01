/*************************************************************************************************************************************
    Author      :   Pawel Biszczak
    Description :   This class provides sufficient test coverage for OpportunitySetBrokerInvolvedTrH class
    --------------------------------------------------------------------------------------------------------------------------------------
    VERSION    DATE            AUTHOR             DETAIL
    1          14 Feb, 2022    Pawel Biszczak     Initial Deployment
**************************************************************************************************************************************/
@isTest
public with sharing class OpportunitySetBrokerInvolvedTrHTest {
    @isTest
    private static void shouldSetBrokerInvolvedOnDML(){
        Account testAccount = TestingUtility.createAccount('Acme', true);
        Contact testContact = TestingUtility.createContact(testAccount.Id, 'Doe', false);
        testContact.Type__c = GlobalConstants.CONTACT_TYPE_BROKER;
        insert testContact;

        Test.startTest();
        Opportunity testOpportunity = TestingUtility.createOpportunity(testAccount.Id, false);
        testOpportunity.LeadSource = GlobalConstants.OPP_LEAD_SOURCE_BROKER_REF;
        testOpportunity.Referrer__c = testContact.Id;
        insert testOpportunity;
        testOpportunity = [ SELECT Id, Broker_Involvement_Indicated__c
                            FROM Opportunity
                            WHERE Id =: testOpportunity.Id
                            LIMIT 1 ];
        Test.stopTest();


        System.assertEquals(GlobalConstants.YES, testOpportunity.Broker_Involvement_Indicated__c,
                            'Broker_Involvement_Indicated__c should be set to "Yes"');
    }

    @isTest
    private static void shouldSetBrokerInvolved(){
        List<Opportunity> opportunities = getFakeOpportunities();
        List<Contact> contacts = getFakeContacts();
        opportunities[0].LeadSource = GlobalConstants.OPP_LEAD_SOURCE_BROKER_REF;
        opportunities[0].LeadSource = GlobalConstants.OPP_LEAD_SOURCE_BROKER_REF;
        opportunities[0].Referrer__c = contacts[0].Id;
        contacts[0].Type__c = GlobalConstants.CONTACT_TYPE_BROKER;
        OpportunitySetBrokerInvolvedTrH handlerInstance;

        Test.startTest();
        handlerInstance = new OpportunitySetBrokerInvolvedTrH();
        handlerInstance.contactSelector = (ContactSelector) MockService.createMock(
                ContactSelector.class,
                new Map<String, Object>{
                        'getContactsByIds' => contacts });
        handlerInstance.newOpportunities = opportunities;
        handlerInstance.setBrokerInvolved();
        Test.stopTest();

        System.assertEquals(GlobalConstants.YES, opportunities[0].Broker_Involvement_Indicated__c,
                            'Broker_Involvement_Indicated__c should be set to "Yes"');
    }

    @isTest
    private static void shouldNotSetBrokerInvolved(){
        List<Opportunity> opportunities = getFakeOpportunities();
        List<Contact> contacts = getFakeContacts();
        opportunities[0].LeadSource = 'Other';
        contacts[0].Type__c = GlobalConstants.CONTACT_TYPE_BROKER;
        OpportunitySetBrokerInvolvedTrH handlerInstance;

        Test.startTest();
        handlerInstance = new OpportunitySetBrokerInvolvedTrH();
        handlerInstance.contactSelector = (ContactSelector) MockService.createMock(
                ContactSelector.class,
                new Map<String, Object>{
                        'getContactsByIds' => contacts });
        handlerInstance.newOpportunities = opportunities;
        handlerInstance.setBrokerInvolved();
        Test.stopTest();

        System.assertNotEquals(GlobalConstants.YES, opportunities[0].Broker_Involvement_Indicated__c,
                               'Broker_Involvement_Indicated__c should not be set to "Yes"');
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