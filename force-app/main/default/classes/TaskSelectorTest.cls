/*************************************************************************************************************************************
    Author      :   Pawel Biszczak
    Description :   This class provides sufficient test coverage for TaskSelector class
    --------------------------------------------------------------------------------------------------------------------------------------
    VERSION    DATE            AUTHOR             DETAIL
    1          19 Feb, 2021    Pawel Biszczak     Initial Deployment
    2          20 Nov, 2021    Vamsi              To Increase Code Coverage
**************************************************************************************************************************************/
@isTest
public with sharing class TaskSelectorTest {
    private static TaskSelector taskSelector = new TaskSelector();

    @testSetup
    static void makeData(){

        Map<String, Object> recordsData = new Map<String, Object>();
        recordsData.put('objName', 'User');
        recordsData.put('numberOfRecords', 1);
        List<User> users = TestingUtility.getRecords(recordsData);

        recordsData = new Map<String, Object>();
        recordsData.put('objName', 'Account');
        recordsData.put('numberOfRecords', 2);
        List<Account> accounts = TestingUtility.getRecords(recordsData);

        recordsData = new Map<String, Object>();
        recordsData.put('objName', 'Lead');
        recordsData.put('numberOfRecords', 2);
        List<Lead> leads = TestingUtility.getRecords(recordsData);

        recordsData = new Map<String, Object>();
        recordsData.put('objName', 'Contact');
        recordsData.put('numberOfRecords', 2);
        recordsData.put('doInsert', true);
        recordsData.put('lstEmails', new List<String> { 'testContact1@test.com', 'testContact2@test.com' });
        List<Contact> contacts = TestingUtility.getRecords(recordsData);

        recordsData = new Map<String, Object>();
        recordsData.put('objName', 'Journey');
        recordsData.put('numberOfRecords', 2);
        recordsData.put('doInsert', false);
        
        List<Task> tasks = new List<Task>();
        tasks.add(new Task(WhoId = contacts[0].Id, Subject = 'subject1: quote for xyz', Saleslady_Contact_UUID__c = '1111', WhatId = accounts[0].Id, Type='Send Letter/Quote', Status = 'Not Started'));
        tasks.add(new Task(WhoId = contacts[0].Id, Subject = 'subject2: xyz', Saleslady_Contact_UUID__c = '2222', WhatId = accounts[0].Id, Status = 'Not Started'));
        tasks.add(new Task(WhoId = contacts[1].Id, Subject = 'subject3: abc', Saleslady_Contact_UUID__c = '3333', WhatId = accounts[1].Id, Status = 'Not Started'));
        tasks.add(new Task(WhoId = contacts[1].Id, Subject = 'subject4: xyz', Saleslady_Contact_UUID__c = '4444', WhatId = accounts[1].Id, Status = 'Not Started'));
             
    tasks.add(new Task(Subject = 'subject7: task for leads', OwnerId = users[0].Id, Saleslady_Contact_UUID__c = '7777', WhoId = leads[0].Id, Status = 'Not Started'));
        tasks.add(new Task(Subject = 'subject8: task for leads', OwnerId = users[0].Id, Saleslady_Contact_UUID__c = '8888', WhoId = leads[1].Id, Status = 'Not Started'));
        TestingUtility.insertListWithAssert(tasks);
        
    }

    @isTest
    static void getDefaultFieldsTest(){
        Set<String> fields;

        Test.startTest();
            fields = taskSelector.getDefaultFields();
        Test.stopTest();

        System.assert(!taskSelector.defaultFields.isEmpty());
    }

    @isTest
    static void shouldGetTasks(){
        List<Task> tasks;

        Test.startTest();
            tasks = taskSelector.getTasks();
        Test.stopTest();

        Integer totalTask = [SELECT Id FROM Task].size();
        System.assertEquals(totalTask, tasks.size(), 'Should get '+totalTask+' tasks');
    }

    @isTest
    static void shouldGetTasksWithRelatedObjects(){
        List<Task> tasks;

        Test.startTest();
            tasks = taskSelector.getTasksWithRelatedObjectsFields();
        Test.stopTest();

        System.assertNotEquals(null, tasks, 'List should not be empty');
        System.assertNotEquals(null, tasks[0].WhoId, 'Should get WhoId value');
    }
    
    @isTest
    static void shouldGetTasksWithAdditionalFields(){
        List<Task> tasks;

        Test.startTest();
            tasks = taskSelector.getTasksWithAdditionalFields();
        Test.stopTest();
        System.assertNotEquals(null, tasks[0].Saleslady_Contact_UUID__c, 'Field should be retrieved');
    }

    @isTest
    static void shouldGetAdditionalFieldsByMultipleIds(){
        List<Task> tasks;

        Test.startTest();
            Task secondTask = [SELECT Id
                               FROM Task
                               WHERE Subject LIKE '%subject2%'
                               LIMIT 1];
            tasks = taskSelector.getTasksWithAdditionalFieldsByIds(new List<Id>{ secondTask.Id });
        Test.stopTest();
        System.assertNotEquals(null, tasks[0].Saleslady_Contact_UUID__c, 'Field should be retrieved');
        System.assertEquals('2222', tasks[0].Saleslady_Contact_UUID__c, 'Should have same value');
    }

    @isTest
    static void shouldGetNullResult(){
        List<Task> tasks;

        Test.startTest();
            tasks = taskSelector.getTasksWithAdditionalFieldsByIds(new List<Id>{});
        Test.stopTest();

        System.assertEquals(null, tasks, 'Should return null');
    }

    @isTest
    static void shouldGetRelatedObjectFieldsForMultipleContactRecords(){
        List<Task> tasks;
        List<Task> tasks1;
        List<Contact> contacts;
        List<Id> contactIds = new List<Id>();

        Test.startTest();
            contacts = [SELECT Id
                        FROM Contact];
            contactIds.addAll(new Map<Id, Contact>(contacts).keySet());
            tasks = taskSelector.getTasksWithRelatedObjectsFieldsByWhoIds(contactIds);
          
          tasks1 = taskSelector.getTasksWithRelatedObjectsFieldsByWhoIds(new List<Id>());
        Test.stopTest();

        System.assertNotEquals(null, tasks[0].WhoId, 'Field should be retrieved');
        System.assert(contactIds.contains(tasks[0].WhoId), 'contactsIds should contain first Task WhoID');
        System.assert(contactIds.contains(tasks[1].WhoId), 'contactsIds should contain second Task WhoID');
        System.assertEquals(null, tasks1,'Should get empty List');
    }

    @isTest
    static void shouldGetRelatedObjectFieldsForMultipleContactRecordsLimited(){
        List<Task> tasks;
        List<Task> tasks1;
        List<Contact> contacts;
        List<Id> contactIds = new List<Id>();

        Test.startTest();
            contacts = [SELECT Id
                        FROM Contact];
            contactIds.addAll(new Map<Id, Contact>(contacts).keySet());
            tasks1 = taskSelector.getTasksWithRelatedObjectsFieldsByWhoIdsLimited(contactIds, 4);
        
        contactIds = new List<Id>();
        tasks = taskSelector.getTasksWithRelatedObjectsFieldsByWhoIdsLimited(contactIds,4);
        Test.stopTest();

        System.assertNotEquals(null, tasks1[0].WhoId, 'Field should be retrieved');
        System.assertEquals(4, tasks1.size(), 'Should get only 4 tasks');
        System.assertEquals(null, tasks,'Should get empty List');
    }

    @isTest
    static void shouldGetRelatedObjectFieldsForMultipleAccountRecords(){
        List<Task> tasks;
        List<Task> tasks1;
        List<Account> accounts;
        List<Id> accountsIds = new List<Id>();

        Test.startTest();
            accounts = [SELECT Id
                        FROM Account];
            accountsIds.addAll(new Map<Id, Account>(accounts).keySet());
            tasks = taskSelector.getTasksWithRelatedObjectsFieldsByWhatIds(accountsIds);
        
          tasks1 = taskSelector.getTasksWithRelatedObjectsFieldsByWhatIds(new List<Id>());
        Test.stopTest();

        System.assertNotEquals(null, tasks[0].WhatId, 'Field should be retrieved');
        System.assert(accountsIds.contains(tasks[0].WhatId), 'accountsIds should contain first Task WhatID');
        System.assert(accountsIds.contains(tasks[1].WhatId), 'accountsIds should contain second Task WhatID');
        System.assertEquals(null, tasks1,'Should get empty List');
    }

    @isTest
    static void shouldGetRelatedObjectFieldsForMultipleAccountRecordsLimited(){
        List<Task> tasks;
        List<Task> tasks1;
        List<Account> accounts;
        List<Id> accountsIds = new List<Id>();

        Test.startTest();
            accounts = [SELECT Id
                        FROM Account];
            accountsIds.addAll(new Map<Id, Account>(accounts).keySet());
            tasks1 = taskSelector.getTasksWithRelatedObjectsFieldsByWhatIdsLimited(accountsIds, 2);

        
        accountsIds = new List<Id>();
        tasks = taskSelector.getTasksWithRelatedObjectsFieldsByWhatIdsLimited(accountsIds,2);
        Test.stopTest();
        
        System.assertNotEquals(null, tasks1[0].WhatId, 'Field should be retrieved');
        System.assertEquals(2, tasks1.size(), 'Should get only 2 tasks');
        System.assertEquals(null, tasks,'Should get empty List');
    }

    @isTest
    static void shouldGetQuoteTasks(){
        List<Task> tasks;

        Test.startTest();
            tasks = taskSelector.getQuoteTasks();
        Test.stopTest();

        System.assertNotEquals(null, tasks, 'List should not be empty');
        System.assertEquals(1, tasks.size(), 'Should get only one quote task');
        System.assertEquals('Send Letter/Quote', tasks[0].Type, 'Should return proper task type');
    }
    
    @isTest
    static void getSalesInquiryTasksByWhatIdsTest(){
        List<Task> tasks;
        List<Journey__c> journeys;
        List<Id> journeysIds = new List<Id>();

        Test.startTest();
        journeys = [SELECT Id
                    FROM Journey__c];
        journeysIds.addAll(new Map<Id, Journey__c>(journeys).keySet());
        tasks = taskSelector.getSalesInquiryTasksByWhatIds(journeysIds);
        Test.stopTest();
        
    }
  
    @isTest
    static void shouldGetTasksForInactiveUsersByLeads(){
        List<Task> tasks;
        List<Task> tasks1;
        List<Lead> leads;
        List<User> users;
        List<Id> leadsIds = new List<Id>();
        Set<String> leadsEmails = new Set<String>();

        Test.startTest();
            users = [SELECT Id, Email
                     FROM User
                     WHERE Email = 'testUserEmail1@test.com'];
            users[0].IsActive = false;
            update users;

            leads = [SELECT Id, Email
                     FROM Lead];
            for (Lead leadRecord : leads) {
                leadsEmails.add(leadRecord.Email);
            }
            leadsIds.addAll(new Map<Id, Lead>(leads).keySet());

            tasks1 = taskSelector.getTasksWithRelatedObjectsFieldsForInactiveOwnersByLeadsEmails(leadsEmails, 1);
        
        leadsEmails = new Set<String>(); 
        tasks = taskSelector.getTasksWithRelatedObjectsFieldsForInactiveOwnersByLeadsEmails(leadsEmails, 1);
        Test.stopTest();
        
        System.assertNotEquals(null, tasks1[0].WhoId, 'Field should be retrieved');
        System.assert(leadsIds.contains(tasks1[0].WhoId), 'leadsIds should contain WhoId');
        System.assertEquals(1, tasks1.size(), 'Should get only 1 task');
        System.assertEquals(null, tasks,'Should get empty List');
    }
}