/*************************************************************************************************************************************
    Author      :   Pawel Biszczak
    Description :   This class provides sufficient test coverage for ContactTriggerHandler class
    --------------------------------------------------------------------------------------------------------------------------------------
    VERSION    DATE            AUTHOR             DETAIL
    1          6 Aug, 2021     Pawel Biszczak     Initial Deployment
    2          13 Jan, 2022    Pawel Biszczak     Small refactor
**************************************************************************************************************************************/
@isTest
public class ContactTriggerHandlerTest {

    @isTest
    public static void shouldGenerateUUIDsForContacts(){
        List<Contact> contacts = getFakeContacts(true);
        ContactTriggerHandler handlerInstance;
        contacts.get(2).UUID__c = 'Test_UUID';
        Contact contactToCheck = contacts.get(2);

        Test.startTest();
        handlerInstance = new ContactTriggerHandler(contacts, null, null, null);
        handlerInstance.generateUUID();
        Test.stopTest();

        System.assert(String.isNotBlank(handlerInstance.newContacts.get(0).UUID__c),
                      'First record UUID should not be blank after generateUUID execution');
        System.assert(String.isNotBlank(handlerInstance.newContacts.get(1).UUID__c),
                      'Second record UUID should not be blank after generateUUID execution');
        System.assertEquals(contactToCheck.UUID__c, handlerInstance.newContacts.get(2).UUID__c,
                            'Third contact UUID should not be changed');
    }

    @isTest
    public static void shouldCheckEmailDuplicatesAndPassValidationForContactsWithDML(){
        List<Contact> contacts = getFakeContacts(false);
        ContactTriggerHandler handlerInstance;
        contacts[0].FirstName = 'Test First Name 1';
        contacts[0].LastName = 'Test Name 1';
        contacts[1].FirstName = 'Test First Name 2';
        contacts[1].LastName = 'Test Name 2';
        contacts[2].FirstName = 'Test First Name 3';
        contacts[2].LastName = 'Test Name 3';
        contacts[3].FirstName = 'Test First Name 4';
        contacts[3].LastName = 'Test Name 4';
        contacts[0].Email = 'test1@weworkexample.com';
        contacts[1].Email = 'test2@weworkexample.com';
        contacts[2].Email = 'test3@weworkexample.com';
        contacts[3].Email = 'test4@weworkexample.com';

        Test.startTest();
        handlerInstance = new ContactTriggerHandler(contacts, null, null, null);
        handlerInstance.setTriggerContext('before insert',true);
        handlerInstance.checkForDuplicateEmail();
        insert handlerInstance.newContacts;
        handlerInstance.newContacts[3].Email = 'test5@weworkexample.com';
        update handlerInstance.newContacts;
        Test.stopTest();

        System.assert(handlerInstance.newContacts[0].getErrors().isEmpty(),
                      'Error shouldn\'t be added to the first contact');
        System.assert(handlerInstance.newContacts[3].getErrors().isEmpty(),
                      'Error shouldn\'t be added to the fourth contact');
    }

    @isTest
    public static void shouldCheckEmailDuplicatesAndThrownAnExceptionForContactsWithDML(){
        List<Map<String,Object>> userData = new List<Map<String,Object>>();
        Profile wwSalesProfile = [SELECT Id FROM Profile WHERE Name = 'WeWork Sales User'];
        userData.add(new Map<String,Object>{'LastName' => 'Testing1', 'Email' => 'standarduser1@example.com'});
        User testUser = TestingUtility.insertUserWithAssert(wwSalesProfile.Id, userData, true)[0];
        System.runAs(testUser) {
            insert new Contact(FirstName = 'First Name Test 0', LastName = 'Test Name 0', Email = 'test1@weworkexample.com');
            List<Contact> contacts = getFakeContacts(false);
            ContactTriggerHandler handlerInstance;
            String exceptionMessage;
            contacts[0].LastName = 'Test Name 1';
            contacts[1].LastName = 'Test Name 2';
            contacts[2].LastName = 'Test Name 3';
            contacts[3].LastName = 'Test Name 4';
            contacts[0].Email = 'test1@weworkexample.com';
            contacts[1].Email = 'test1@weworkexample.com';
            contacts[2].Email = 'test1@weworkexample.com';
            contacts[3].Email = 'test1@weworkexample.com';
            Test.startTest();
            handlerInstance = new ContactTriggerHandler(contacts, null, null, null);
            handlerInstance.setTriggerContext('before insert',true);
            handlerInstance.checkForDuplicateEmail();
            Test.stopTest();
            System.assert(handlerInstance.newContacts[0].getErrors()[0].getMessage().contains(ContactTriggerHandler.DUPLICATE_EMAIL), 'Thrown error is not correct');
            System.assert(handlerInstance.newContacts[1].getErrors()[0].getMessage().contains(ContactTriggerHandler.DUPLICATE_NEW_EMAIL), 'Thrown error is not correct');
        }
    }

    @isTest
    public static void shouldUpdateActiveReferrer(){
        List<Contact> contacts = getFakeContacts(true);
        ContactTriggerHandler handlerInstance;
        contacts[0].Email = 'testreferrer1@example.com';
        contacts[1].Email = 'testreferrer2@example.com';
        contacts[2].Email = 'testreferrer3@example.com';
        Contact contactToCheck = contacts[2];

        Test.startTest();
        handlerInstance = new ContactTriggerHandler(contacts, null, null, null);
        ReferenceHandler.activeReferenceMap.put(contacts[0].Email.toLowerCase(), contacts[2].Id);
        ReferenceHandler.activeReferenceMap.put(contacts[1].Email.toLowerCase(), contacts[2].Id);
        handlerInstance.updateActiveReferrerOnContact();
        Test.stopTest();

        System.assertEquals(handlerInstance.newContacts[0].Referrer__c, contacts[2].Id,
                            'Referrer should be equal to second contact');
        System.assertEquals(handlerInstance.newContacts[1].Referrer__c, contacts[2].Id,
                            'Referrer should be equal to first contact');
        System.assertEquals(handlerInstance.newContacts[2].Referrer__c, null,
                            'Referrer should be equal to first contact');
        System.assert(!ReferenceHandler.activeReferenceMap.containsKey(contactToCheck.Email),
                      'Third contact UUID should not be changed');
    }

    @isTest
    public static void shouldRestartJourney(){
        List<Contact> contacts = getFakeContacts(true);
        Integer queriesBeforeRestart;
        Integer queriesAfterRestart;
        ContactTriggerHandler handlerInstance;
        contacts[0].Restart_Journey__c = true;
        contacts[1].Restart_Journey__c = true;
        contacts[2].Restart_Journey__c = false;
        List<Contact> oldContacts = contacts.deepClone(true);
        oldContacts[0].Restart_Journey__c = false;
        oldContacts[1].Restart_Journey__c = true;
        oldContacts[2].Restart_Journey__c = false;

        Map<Id, Contact> oldContactsByIds = new Map<Id, Contact>();
        oldContactsByIds.putAll(new Map<Id, Contact>(oldContacts));

        Test.startTest();
        queriesBeforeRestart = Limits.getQueries();
        handlerInstance = new ContactTriggerHandler(contacts, null, null, oldContactsByIds);
        handlerInstance.restartJourney();
        ContactTriggerHandler.restartJourneyInFuture(oldContactsByIds.keySet());
        queriesAfterRestart = Limits.getQueries();
        Test.stopTest();

        System.assertNotEquals(queriesAfterRestart, queriesBeforeRestart, 'Should execute query on restart Journey');
    }

    @isTest
    public static void shouldRunConvertMatchingLead(){
        List<Contact> contacts = getFakeContacts(true);
        ContactTriggerHandler handlerInstance;
        contacts[0].Convert_Lead__c = true;
        contacts[1].Convert_Lead__c = true;
        contacts[2].Convert_Lead__c = false;

        List<Contact> oldContacts = contacts.deepClone(true);
        oldContacts[0].Convert_Lead__c = false;
        oldContacts[1].Convert_Lead__c = true;
        oldContacts[2].Convert_Lead__c = false;

        Map<Id, Contact> oldContactsByIds = new Map<Id, Contact>();
        oldContactsByIds.putAll(new Map<Id, Contact>(oldContacts));

        Test.startTest();
        handlerInstance = new ContactTriggerHandler(contacts, null, null, oldContactsByIds);
        handlerInstance.setTriggerContext('after insert',true);
        handlerInstance.convertMatchingLead();
        handlerInstance.setTriggerContext('after update',true);
        handlerInstance.convertMatchingLead();
        Test.stopTest();

        System.assertEquals(handlerInstance.newContacts[0].Convert_Lead__c, true, 'Should be equal to true');
    }

    @isTest
    public static void shouldConvertLeadsInFuture(){
        List<Lead> leads = getFakeLeads(true);

        Test.startTest();
        ContactTriggerHandler.convertMatchingLeadInFuture(JSON.serialize(leads));
        Test.stopTest();

        System.assert(LeadConverterHelper.isCreateActivity, 'IsCreateActivity should be true on lead convert');
    }

    @isTest
    public static void shouldvalidateMergeLeadSourceAsId(){
        ContactTriggerHandler handlerInstance;

        Account account = new Account();
        account.Name = 'Test Account feature';
        insert account;
        
        List<Contact> contacts = new List<Contact>();        
		Contact Con = new Contact();
		Con.FirstName = 'Test';
		Con.LastName = 'contact';
		Con.Email = 'testcontact@wework.com';
		Con.LeadSource = 'Id';
		Con.Account = account;
		contacts.add(Con);
        insert contacts;

        Map<Id, Contact> oldContactsByIds = new Map<Id, Contact>();
        oldContactsByIds.putAll(new Map<Id, Contact>(contacts));
        
        Test.startTest();
        Lead lead = new Lead();
        lead.FirstName = 'Test';
        lead.LastName = 'Lead';
        lead.Email = Con.Email;
        lead.Company = 'XYZ';
        lead.LeadSource = 'Event';
        lead.LeadSource_Sub_Type__c = 'Broker';
        lead.Lead_Source_Detail__c = 'Test';
        insert lead;
        handlerInstance = new ContactTriggerHandler(contacts, null, null, oldContactsByIds);
        handlerInstance.setTriggerContext('before update',true);
        handlerInstance.validateMergeLeadSourceAsId();
        Test.stopTest();
        
        System.assertEquals(handlerInstance.newContacts[0].LeadSource_Sub_Type__c, null);
        System.assertEquals(handlerInstance.newContacts[0].Lead_Source_Detail__c, null);
    }

    static List<Contact> getFakeContacts(Boolean isFakeIds) {
        Map<String, Object> recordsData = new Map<String, Object>();
        recordsData = new Map<String, Object>();
        recordsData.put('objectName', 'Contact');
        recordsData.put('numberOfRecords', 4);
        return MockTestingUtility.getRecords(recordsData, isFakeIds);
    }

    static List<Lead> getFakeLeads(Boolean isFakeIds) {
        Map<String, Object> recordsData = new Map<String, Object>();
        recordsData = new Map<String, Object>();
        recordsData.put('objectName', 'Lead');
        recordsData.put('numberOfRecords', 3);
        return MockTestingUtility.getRecords(recordsData, isFakeIds);
    }
}