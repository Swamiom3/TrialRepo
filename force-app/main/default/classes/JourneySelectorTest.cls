/*************************************************************************************************************************************
    Author      :   Pawel Biszczak
    Description :   This class provides sufficient test coverage for JourneySelector class
    --------------------------------------------------------------------------------------------------------------------------------------
    VERSION    DATE            AUTHOR             DETAIL
    1          13 Apr, 2021    Pawel Biszczak     Initial Deployment
**************************************************************************************************************************************/
@isTest
public with sharing class JourneySelectorTest {
    private static JourneySelector journeySelector = new JourneySelector();

    @testSetup
    static void makeData(){
        MetadataDrivenTriggerHandler.disableExecution();
        Map<String, Object> recordsData = new Map<String, Object>();
        recordsData = new Map<String, Object>();
        recordsData.put('objName', 'Lead');
        recordsData.put('numberOfRecords', 2);
        recordsData.put('doInsert', true);
        List<Lead> leads = TestingUtility.getRecords(recordsData);
        
        recordsData = new Map<String, Object>();
        recordsData.put('objName', 'Contact');
        recordsData.put('numberOfRecords', 2);
        recordsData.put('doInsert', true);
        List<Contact> contacts = TestingUtility.getRecords(recordsData);

        recordsData = new Map<String, Object>();
        recordsData.put('objName', 'Journey');
        recordsData.put('numberOfRecords', 4);
        recordsData.put('doInsert', false);
        List<Journey__c> journeys = TestingUtility.getRecords(recordsData);

        journeys[0].Primary_Lead__c = leads[0].Id;
        journeys[0].Primary_Email__c = 'testprim@wework.com';
        journeys[0].Primary_Contact__c = null;
        journeys[0].Lead_Id__c = leads[0].Id;
        journeys[0].Creation_Source__c = 'Inbound Lead';
        journeys[0].Referrer__c = contacts[0].Id;
        
        journeys[1].Primary_Lead__c = null;
        journeys[1].Primary_Email__c = 'testprim@wework.com';
        journeys[1].Primary_Contact__c = contacts[0].Id;
        TestingUtility.insertListWithAssert(journeys);
    }

    @isTest
    static void shouldGetJourneysWithAdditionalFieldsByIds(){
        List<Journey__c> journeys;
        Set<Id> journeysIds = new Map <Id, Journey__c> ([SELECT Id, Status__c
                                                         FROM Journey__c]).keySet();

        Test.startTest();
        journeys = journeySelector.getJourneysWithAdditionalFieldsByIds(new List<Id>(journeysIds));
        Test.stopTest();

        System.assertNotEquals(null, journeys[0].NMD_Next_Contact_Date__c, 'Field should be retrieved');
        System.assertEquals(2, journeys.size(), 'Should get 2 journeys');
    }

    @isTest
    static void shouldGetJourneysByLeadIds(){
        List<Journey__c> journeys;
        Set<Id> leadIds = new Map <Id, Lead> ([SELECT Id
                                               FROM Lead]).keySet();

        Test.startTest();
        journeys = journeySelector.getJourneysByLeadsIds(new List<Id>(leadIds));
        Test.stopTest();

        System.assertEquals(1, journeys.size(), 'Should get 1 journeys');
    }

    @isTest
    static void shouldGetJourneysByStatusAndLeadIds(){
        List<Journey__c> journeys;
        Set<Id> leadIds = new Map <Id, Lead> ([SELECT Id
                                               FROM Lead]).keySet();

        Test.startTest();
        journeys = journeySelector.getJourneysByStatusAndContactAndLeadIds('Known', null, new List<Id>(leadIds));
        Test.stopTest();

        System.assertEquals(1, journeys.size(), 'Should get 1 journeys');
        System.assertEquals('Known', journeys[0].Status__c, 'Field should be equal to \'Known\'');
    }

    @isTest
    static void shouldGetRecordForIdsAndStatus(){
        List<Journey__c> journeys;
        Set<Id> journeysIds = new Map <Id, Journey__c> ([SELECT Id, Status__c
                                                         FROM Journey__c]).keySet();

        Test.startTest();
        journeys = journeySelector.getJourneysByStatusAndIds('Known', new List<Id>(journeysIds));
        Test.stopTest();

        System.assertEquals(2, journeysIds.size(), 'Should contain 2 journeys ids');
        System.assertEquals(2, journeys.size(), 'Should get 2 journeys from query');
        System.assertEquals('Known', journeys[0].Status__c, 'Field should be equal to \'Known\'');
    }
    
    @isTest
    static void shouldGetJourneyByPrimaryEmailsAndNotNullPrimaryLead(){
        List<Journey__c> journeys;
        List<Journey__c> journeysWithPrimaryEmails;

        Test.startTest();
        journeysWithPrimaryEmails = [SELECT Id, Primary_Email__c
                                     FROM Journey__c
                                     WHERE Primary_Email__c != null
                                           AND Primary_Lead__c != null];
        List<String> primaryEmails = new List<String>();
        for (Journey__c journey : journeysWithPrimaryEmails) {
            primaryEmails.add(journey.Primary_Email__c);
        }

        System.assert(!primaryEmails.isEmpty(), 'Should contain Primary Emails for Journeys with connected Leads');
        journeys = journeySelector.getJourneysByPrimaryEmailsWhenPrimaryLeadPresented(primaryEmails);
        Test.stopTest();

        System.assertEquals(journeysWithPrimaryEmails.size(), journeys.size(), 'Should contain same number of records');
    }
    
    @isTest
    static void shouldGetAcceptedJourneysMatchingParentIds(){
        List<Journey__c> journeys;
        Set<Id> leadIds = new Map <Id, Lead> ([SELECT Id
                                               FROM Lead LIMIT 1]).keySet();
        
        Test.startTest();
        journeys = journeySelector.getAcceptedJourneysMatchingParentIds('Known', new List<Id>(leadIds));
        Test.stopTest();
        
        System.assertEquals(1, journeys.size(), 'Should get 1 journeys from query');
        System.assertEquals('Known', journeys[0].Status__c, 'Field should be equal to \'Known\'');
        
    }
    
    @isTest
    static void shouldGetJourneysWithMoreAdditionalFieldsByIds(){
        String journeys;

        Test.startTest();
        journeys = journeySelector.getJourneysWithMoreAdditionalFieldsByIds();
        Test.stopTest();

        System.assertNotEquals(null, journeys, 'Should get a query');
    }
    
    @isTest
    static void shouldGetJourneysByCreatedDateAndStatus(){
        String journeys;

        Test.startTest();
        journeys = journeySelector.getJourneysWithMoreAdditionalFieldsByIds();
        Test.stopTest();

        System.assertNotEquals(null, journeys, 'Should get a query');
    }
    
    @isTest
    static void shouldGetJourneysByIdsWithLeadOrContactPresent(){
        List<Journey__c> journeys;
        Set<Id> journeysIds = new Map <Id, Journey__c> ([SELECT Id, Primary_Lead__c
                                                         FROM Journey__c]).keySet();

        Test.startTest();
        journeys = journeySelector.getJourneysByIdsWithLeadOrContactPresent(new List<Id>(journeysIds));
        Test.stopTest();
        System.assertEquals(2, journeys.size(), 'Should get 2 journeys from query');
    }
    
    @isTest
    static void shouldGetJourneysByLeadOrContactPresent(){
        List<Journey__c> journeys;
        Set<Id> leadIds = new Map <Id, Lead> ([SELECT Id
                                               FROM Lead LIMIT 1]).keySet();
		
        Test.startTest();
        journeys = journeySelector.getJourneysByLeadOrContactPresent(new List<Id>(leadIds));
        Test.stopTest();
        
        System.assertEquals(1, journeys.size(), 'Should get 1 journeys from query');
    }
    
    @isTest
    static void shouldGetOpenJourneysByPrimaryContact(){
        List<Journey__c> journeys;
        Id contactId = [SELECT Id FROM Contact][0].Id;
        List<String> journeyClosedStages = new List<String>{'Deferred', 'Converted'};
        
        Test.startTest();
        journeys = journeySelector.getOpenJourneysByPrimaryContact(contactId, journeyClosedStages);
        Test.stopTest();
        
        System.assertEquals(1, journeys.size(), 'Should get 1 journeys from query');
    }
    
    @isTest
    static void shouldGetDuplicateJourneysCreatedToday(){
        List<Journey__c> journeys;
        List<Journey__c> journeysWithPrimaryEmails;

        Test.startTest();
        journeysWithPrimaryEmails = [SELECT Id, Primary_Email__c, First_Name__c, Last_Name__c
                                     FROM Journey__c
                                     WHERE Primary_Email__c != null
                                           AND Primary_Lead__c != null];
        List<String> emails = new List<String>();
        List<String> firstNames = new List<String>();
        List<String> lastNames = new List<String>();
        for (Journey__c journey : journeysWithPrimaryEmails) {
            emails.add(journey.Primary_Email__c);
            firstNames.add(journey.First_Name__c);
            lastNames.add(journey.Last_Name__c);
        }

        journeys = journeySelector.getDuplicateJourneysCreatedToday(emails, firstNames, lastNames);
        Test.stopTest();
        System.assertEquals(journeysWithPrimaryEmails.size(), journeys.size(), 'Should contain same number of records');
    }
    
    @isTest
    static void shouldGetJourneysByLeadAndStatus(){
        List<Journey__c> journeys;
        Id leadId = [SELECT Id FROM Lead][0].Id;
        List<String> setOfStatus = new List<String>{'Deferred', 'Converted'};
        
        Test.startTest();
        journeys = journeySelector.getJourneysByLeadAndStatus(leadId, setOfStatus);
        Test.stopTest();
        
        System.assertEquals(1, journeys.size(), 'Should get 1 journeys from query');
    }
    
    @isTest
    static void shouldGetOpenJourneysByLeadOrContact(){
        List<sObject> journeys;
        Set<Id> leadIds = new Map <Id, Lead> ([SELECT Id
                                               FROM Lead LIMIT 1]).keySet();
        List<String> listOfJourneyCloseStages = new List<String>{'Deferred', 'Converted'};
        
        Test.startTest();
        journeys = journeySelector.getOpenJourneysByLeadOrContact(new List<Id>(leadIds), listOfJourneyCloseStages);
        Test.stopTest();
        System.assertEquals(1, journeys.size(), 'Should get 1 journeys from query');
    }
    
    @isTest
    static void shouldGetJourneysByIds(){
        List<Journey__c> journeys;
        Set<Id> journeysIds = new Map <Id, Journey__c> ([SELECT Id, Primary_Lead__c
                                                         FROM Journey__c]).keySet();
        List<String> customFields = new List<String>{ 'Id', 'Status__c'};
        
        Test.startTest();
        journeys = journeySelector.getJourneysByIds(customFields, new List<Id>(journeysIds));
        Test.stopTest();
        
        System.assertEquals(2, journeys.size(), 'Should get 2 journeys from query');
    }
    
    @isTest
    static void shouldGetJourneyByCreatedDateAndLeadId(){
        List<Journey__c> journeys;
        Id opportunityId = [SELECT Id FROM Lead][0].Id;
        List<String> customFields = new List<String>{ 'Id', 'Status__c'};
        
        Test.startTest();
        journeys = journeySelector.getJourneyByCreatedDateAndLeadId(customFields, opportunityId);
        Test.stopTest();
        
        System.assertEquals(1, journeys.size(), 'Should get 1 journeys from query');
    }
    
    @isTest
    static void shouldGetJourneysByLead(){
        List<Journey__c> journeys;
        Set<Lead> leadIds = new Set<Lead> ([SELECT Id
                                            FROM Lead LIMIT 1]);
        List<String> customFields = new List<String>{ 'Id', 'Status__c'};
            
        Test.startTest();
        journeys = journeySelector.getJourneysByLead(customFields, new List<Lead>(leadIds));
        Test.stopTest();
        
        System.assertEquals(1, journeys.size(), 'Should get 1 journeys from query');
    }
    
    @isTest
    static void shouldGetJourneysCreatedTodayByLeadIds(){
        List<Journey__c> journeys;
        Set<Id> leadIds = new Map <Id, Lead> ([SELECT Id
                                               FROM Lead LIMIT 1]).keySet();
        List<String> customFields = new List<String>{ 'Id', 'Status__c'};
            
        Test.startTest();
        journeys = journeySelector.getJourneysCreatedTodayByLeadIds(customFields, new List<Id>(leadIds));
        Test.stopTest();
        
        System.assertEquals(1, journeys.size(), 'Should get 1 journeys from query');
    }
    
    @isTest
    static void shouldGetJourneysByEmailWithOrderByCreatedDate(){
        List<Journey__c> journeys;
        List<String> customFields = new List<String>{ 'Id', 'Status__c'};
        List<Journey__c> journeysWithPrimaryEmails;

        Test.startTest();
        journeysWithPrimaryEmails = [SELECT Id, Primary_Email__c, First_Name__c, Last_Name__c
                                     FROM Journey__c
                                     WHERE Primary_Email__c != null
                                           AND Primary_Lead__c != null];
        List<String> emails = new List<String>();
        for (Journey__c journey : journeysWithPrimaryEmails) {
            emails.add(journey.Primary_Email__c);
        }
        journeys = journeySelector.getJourneysByEmailWithOrderByCreatedDate(customFields, emails);
        Test.stopTest();
        
        System.assertEquals(2, journeys.size(), 'Should get 2 journeys from query');
    }
    
    @isTest
    static void shouldgetQueryWithIdAndLeadAndContact(){
        String journeys;

        Test.startTest();
        journeys = journeySelector.getQueryWithIdAndLeadAndContact();
        Test.stopTest();

        System.assertNotEquals(null, journeys, 'Should get a query');
    }
    
    @isTest
    static void shouldGetQueryWithLeadOrContact(){
        String journeys;

        Test.startTest();
        journeys = journeySelector.getQueryWithLeadOrContact();
        Test.stopTest();

        System.assertNotEquals(null, journeys, 'Should get a query');
    }
    
    @isTest
    static void shouldGetQueryWithId(){
        String journeys;
        Id leadId = [SELECT Id FROM Lead][0].Id;

        Test.startTest();
        journeys = journeySelector.getQueryWithId(leadId);
        Test.stopTest();
        System.assertNotEquals(null, journeys, 'Should get a query');
    }
    
    @isTest
    static void shouldGetQueryWithJourneyId(){
        String journeys;

        Test.startTest();
        journeys = journeySelector.getQueryWithJourneyId();
        Test.stopTest();

        System.assertNotEquals(null, journeys, 'Should get a query');
    }
    
    @isTest
    static void shouldGetJourneysWithReferrer(){
        List<Journey__c> journeys;
        Set<Id> journeysIds = new Map <Id, Journey__c> ([SELECT Id, Referrer__c 
                                                        FROM Journey__c]).keySet();
        
        Test.startTest();
        journeys = journeySelector.getJourneysWithReferrer(journeysIds , 'Inbound Lead');
        Test.stopTest();

        System.assertEquals(2, journeysIds.size(), 'Should contain 2 journeys ids');
        System.assertEquals(1, journeys.size(), 'Should get 1 journeys from query');
    }
}