/**********************************************************************************************************************************
    Author      :   RamseySolutions
    Description :   This class provides sufficient test coverage for TaskTriggerHandler class
    ---------------------------------------------------------------------------------------------------------------------------------
    VERSION    AUTHOR             DATE            DETAIL
    1          RamseySolutions    18 Jan, 2016    Test methods for different Task triggers
    2          Rupesh Patil       7 Jun, 2018     Modifications,Optimization for Revamp
    3          Ashish Sharma      26 Dec, 2019    Modification according to new test structure ST-5472
    4          Pawel Biszczak     9 Apr, 2021     Refactor and mocking data
    5          Ishwar Shinde      17 Feb, 2022    Migration to new trigger framework
*****************************************************************************************************************************************/
@isTest
private class TaskTriggerHandlerTest {
    private static TaskSelector taskSelector = new TaskSelector();

    private static void initializeRecordsWithDMLsForLeads() {
        List<Lead> leads = new List<Lead>();
        List<Task> tasks = new List<Task>();
        List<Journey__c> journeys = new List<Journey__c>();

        leads.addAll((List<Lead>)TestingUtility.getRecords(new Map<String, Object>{'doInsert' => 'false', 'objName' => 'Lead', 'numberOfRecords'=> '1', 'mapFieldValues' => new Map<String,List<Object>>{'FirstName'=> new List<Object>{'Test1'}, 'LastName'=> new List<Object>{'Test1'}, 'Company' => new List<Object>{'Test'}, 'Phone' => new List<Object>{'1236547890'}, 'Email'=> new List<Object>{'ukClient@wework.com'}, 'Generate_Journey__c' => new List<Object>{true}}}));
        leads.addAll((List<Lead>)TestingUtility.getRecords(new Map<String, Object>{'doInsert' => 'false', 'objName' => 'Lead', 'numberOfRecords'=> '1', 'mapFieldValues' => new Map<String,List<Object>>{'FirstName'=> new List<Object>{'Test'}, 'LastName'=> new List<Object>{'Test'}, 'Company' => new List<Object>{'Test'}, 'Phone' => new List<Object>{'9874563210'}, 'Email'=> new List<Object>{'usaClient@wework.com'}, 'Status' => new List<Object>{GlobalConstants.JOURNEY_STATUS_KNOWN}, 'Locations_Interested__c' => new List<Object>{'B1; B2;'}}}));

        TestingUtility.insertListWithAssert(leads);

        journeys.add(new Journey__c(Name = 'Test11 Journey', Status__c = GlobalConstants.JOURNEY_STATUS_KNOWN, NMD_Next_Contact_Date__c = Date.today(), Outreach_Stage__c = '', Primary_Lead__c = leads[1].Id));
        journeys.add(new Journey__c(Name = 'TestJourney22', Status__c = GlobalConstants.JOURNEY_STATUS_KNOWN, NMD_Next_Contact_Date__c = Date.today(), Outreach_Stage__c = '', Primary_Lead__c = leads[1].Id));

        TestingUtility.insertListWithAssert(journeys);
        
        tasks.add(new Task(WhatId = journeys[0].Id, Subject = 'FastCall Outbound Call', Status = 'Not Started'));
        tasks.add(new Task(WhatId = journeys[1].Id, Subject = 'FastCall Outbound Call', Status = 'Not Started'));
        tasks.add(new Task(
            WhoId = leads[0].Id, 
            Subject = GlobalConstants.TASK_SUBJECT_ENGAGE_CAMPAIGN, 
            Vonage_Call_Disposition__c = GlobalConstants.TASK_CALL_DISPOSITION_COVID19, 
            Status = 'Not Started'
        ));

        TestingUtility.insertListWithAssert(tasks);
    }

    private static void initializeRecordsWithDMLsForContactsAndAccounts() {
        List<Task> tasks = new List<Task>();
        List<Account> accounts = new List<Account>();
        List<Contact> contacts = new List<Contact>();
        List<Journey__c> journeys = new List<Journey__c>();
        List<Referral__c> referrals = new List<Referral__c>();

        accounts.add(TestingUtility.createAccount(new Map<String, Object>{'Name' => 'Test1 Account', 'UUID__c' => 'account-uuId', 'Lead_Source__c' => 'Id'}, false));
        accounts.add(TestingUtility.createAccount(new Map<String, Object>{'Name' => 'strAccountName'}, false));
        TestingUtility.insertListWithAssert(accounts);

        contacts.add(TestingUtility.createContact(new Map<String, Object>{'FirstName' => 'TestFirstName', 'LastName' => 'TestLastName', 'AccountId' => accounts[0].Id, 'Email' => 'Test111@example.com', 'Status__c' => 'active'}, false));
        contacts.add(TestingUtility.createContact(new Map<String, Object>{'FirstName' => 'TestFirstName1', 'LastName' => 'TestLastName1', 'AccountId' => accounts[1].Id, 'Email' => 'Test120@example.com', 'Status__c' => 'active'}, false));
        contacts.add(TestingUtility.createContact(new Map<String, Object>{'FirstName' => 'conForWhoId1', 'LastName' => 'conForWhoId1LastName', 'AccountId' => accounts[0].Id, 'Email' => 'whoId1@example.com', 'Status__c' => 'active', 'UUID__c' => '12345678'}, false));
        TestingUtility.insertListWithAssert(contacts);

        journeys.add(new Journey__c(Name = 'Test1 Journey', Status__c = GlobalConstants.JOURNEY_STATUS_KNOWN, Primary_Contact__c = contacts[0].Id, NMD_Next_Contact_Date__c = Date.today(), Outreach_Stage__c = ''));
        journeys.add(new Journey__c(Name = 'TestJourney2', Status__c = GlobalConstants.JOURNEY_STATUS_KNOWN, Primary_Contact__c = contacts[0].Id, NMD_Next_Contact_Date__c = Date.today(), Outreach_Stage__c = ''));
        journeys.add(new Journey__c(Name = 'Test Customer1', Status__c = GlobalConstants.JOURNEY_STATUS_KNOWN, Primary_Contact__c = contacts[0].Id, NMD_Next_Contact_Date__c = Date.today().addDays(-2), Outreach_Stage__c = ''));
        journeys.add(new Journey__c(Name = 'Test2 Journey', Status__c = GlobalConstants.JOURNEY_STATUS_KNOWN, Primary_Contact__c = contacts[0].Id, NMD_Next_Contact_Date__c = Date.today(), Outreach_Stage__c = 'Call 1'));
        journeys.add(new Journey__c(Name = 'Test3 Journey', Status__c = GlobalConstants.JOURNEY_STATUS_KNOWN, Primary_Contact__c = contacts[0].Id, NMD_Next_Contact_Date__c = Date.today(), Outreach_Stage__c = 'Call 5'));
        TestingUtility.insertListWithAssert(journeys);

        tasks.add(new Task(WhatId = journeys[4].Id, Subject = 'FastCall Outbound Call', Status = 'Not Started'));
        tasks.add(new Task(Status = 'Not Started', Priority = 'Normal', Subject = 'Call1', WhatId  = journeys[0].Id));
        tasks.add(new Task(Type = GlobalConstants.TASK_TYPE_CALL, TaskSubtype = 'Task', WhatId = journeys[0].Id, Status = GlobalConstants.JOURNEY_STATUS_DEFERRED, Priority = 'Normal', Subject = 'Subject11', CallDisposition = 'Busy / No answer', ActivityDate = Date.today()-1));
        tasks.add(new Task(Type = GlobalConstants.TASK_TYPE_CALL, TaskSubtype = 'Task', WhatId = journeys[0].Id, Status = GlobalConstants.JOURNEY_STATUS_DEFERRED, Priority = 'Normal', Subject = 'Subject test', CallDisposition = 'Busy / No answer', ActivityDate = Date.today()-1));
        tasks.add(new Task(Type = GlobalConstants.TASK_TYPE_CALL, TaskSubtype = 'Task', WhatId = journeys[1].Id, Status = 'Not Started', Priority = 'Normal', Subject = 'Subject Left VM', CallDisposition = 'Left VM'));
        tasks.add(new Task(WhoId = contacts[2].Id, Status = 'In Progress', Priority = 'Normal', Subject = 'Call11', ActivityDate = Date.Today().addDays(-14)));
        tasks.add(new Task(Type = 'Send Letter/Quote', WhoId = contacts[2].Id, TaskSubtype = 'Email',Status = 'In Progress', Priority = 'Normal', Subject = 'quote',ActivityDate = Date.Today().addDays(-14)));

        TestingUtility.insertListWithAssert(tasks);
        referrals.addAll((List<Referral__c>)TestingUtility.getRecords(new Map<String, Object>{'doInsert' => 'false', 'objName' => 'referral', 'numberOfRecords'=> '1', 'mapFieldValues' => new Map<String,List<Object>>{'Referral_Email__c'=> new List<Object>{'whoId1@example.com'}, 'IsActive__c'=> new List<Object>{true}, 'Referrer__c' => new List<Object>{contacts[0].Id}, 'Expires_On__c' => new List<Object>{Date.today().addDays(10)}}}));
        TestingUtility.insertWithAssert(new Referral__c(Referral_Email__c = 'whoId1@example.com', IsActive__c = true, Referrer__c = contacts[0].Id, Expires_On__c = Date.today().addDays(10)));
    }
    //We are not using this for any of the story developed so far
    /*public static void insertDataForTaskOwnerChange(List<Lead> leads) {
        User testUser = [SELECT Id
                         FROM User
                         WHERE Email = 'testUserEmail1@test.com'
                         LIMIT 1];
        System.runAs(new User(Id=UserInfo.getUserId())) {
            Group group1 = new Group(Name='group name', type='Queue');
            insert group1;

            QueueSObject queue1 = new QueueSObject(QueueId = group1.Id, SobjectType = 'Lead');
            insert queue1;

            QueueSObject queue2 = new QueueSObject(QueueId = group1.Id, SobjectType = 'Journey__c');
            insert queue2;

            GroupMember member = new GroupMember();
            member.UserOrGroupId = testUser.Id;
            member.GroupId = group1.Id;
            insert member;

            System.runAs(testUser) {
                leads[1].OwnerId = queue1.QueueId;
                update leads[1];

                Lead leadRecord = [SELECT Id, OwnerId, LastName
                                   FROM Lead
                                   WHERE Id =:leads[1].Id];
                Journey__c journeyRecord = new Journey__c(Name = 'Test Customer123', Status__c = GlobalConstants.JOURNEY_STATUS_CONVERTED, Primary_Lead__c = leadRecord.Id, NMD_Next_Contact_Date__c = Date.today(), OwnerId = queue1.QueueId);
                TestingUtility.insertWithAssert(journeyRecord);

                Task taskRecord = new Task(WhoId = leadRecord.Id, Type = GlobalConstants.TASK_TYPE_CALL, TaskSubtype = GlobalConstants.TASK_TYPE_CALL, Status = 'Started', Priority = 'Normal', CallDisposition = 'Left VM', Subject = 'other test');
                insert taskRecord;

                taskRecord.Status = GlobalConstants.TASK_STATUS_COMPLETED;
                taskRecord.Subject = GlobalConstants.TASK_TYPE_CALL;
                update taskRecord;
            }
        }
    }*/

    private static void initializeRecordsWithDMLsTaskOwnerChange() {

        List<Lead> leads = new List<Lead>();

        TestingUtility.getRecords(new Map<String, Object>{'doInsert' => 'true','objName' => 'user', 'numberOfRecords'=> '1'});

        leads.addAll((List<Lead>)TestingUtility.getRecords(new Map<String, Object>{'doInsert' => 'false', 'objName' => 'Lead', 'numberOfRecords'=> '1', 'mapFieldValues' => new Map<String,List<Object>>{'FirstName'=> new List<Object>{'Test1'}, 'LastName'=> new List<Object>{'Test1'}, 'Company' => new List<Object>{'Test'}, 'Phone' => new List<Object>{'1236547890'}, 'Email'=> new List<Object>{'ukClient@wework.com'}, 'Generate_Journey__c' => new List<Object>{true}}}));
        leads.addAll((List<Lead>)TestingUtility.getRecords(new Map<String, Object>{'doInsert' => 'false', 'objName' => 'Lead', 'numberOfRecords'=> '1', 'mapFieldValues' => new Map<String,List<Object>>{'FirstName'=> new List<Object>{'Test'}, 'LastName'=> new List<Object>{'Test'}, 'Company' => new List<Object>{'Test'}, 'Phone' => new List<Object>{'9874563210'}, 'Email'=> new List<Object>{'usaClient@wework.com'}, 'Status' => new List<Object>{GlobalConstants.JOURNEY_STATUS_KNOWN}, 'Locations_Interested__c' => new List<Object>{'B1; B2;'}}}));

        TestingUtility.insertListWithAssert(leads);
        //insertDataForTaskOwnerChange(leads);//insert data for changeTaskOwner method in user context.;
    }

    @isTest
    public static void testTaskTriggerHandlerDMLsAgainstContactAndAccounts() {
        initializeRecordsWithDMLsForContactsAndAccounts();

        List<Task> tasks = getTaskRecords();
        Map<String, SObject> dataToUpdate = new Map<String, SObject>();
        verifyUpdateOutreachStageOnJourney();
        verifyTaskType();
        //update values
        updateJourneyCallDisposition(tasks, dataToUpdate);
        updateTaskData(tasks, dataToUpdate);
        updateContactOnTask(tasks, dataToUpdate);

        if(!dataToUpdate.isEmpty()) {
            update dataToUpdate.values();
        }
        testUpdateContactOnTask(dataToUpdate);
        verifyUpdateNextNMDContactDateOnJourney(dataToUpdate);
        verifyUpdateFieldForNVMCallsOnUpdate();
    }

    @isTest
    public static void testTaskTriggerHandlerDMLsAgainstLeads() {
        initializeRecordsWithDMLsForLeads();

        List<Task> tasks = getTaskRecords();
        verifyUpdateLeadEngagementFields(tasks);
        verifyUpdateFieldForNVMCallsOnInsert(tasks);
        verifyUpdateOutreachStageOnJourney();
    }

    @isTest
    public static void testTaskTriggerHandlerWithDMlsAgainstOwnersChange() {
        initializeRecordsWithDMLsTaskOwnerChange();
        //verifyChangeTaskOwner();
    }
    
    public static List<Task> getTaskRecords() {
        return taskSelector.getTasksWithAdditionalFields();
    }
    
    public static void updateJourneyCallDisposition(List<Task> tasks, Map<String, SObject> dataToUpdate) {
        for(Task taskRecord : tasks) {
            if(taskRecord.Subject == 'Call1') {
                taskRecord.CallDisposition = 'Do Not Call';
                dataToUpdate.put('update stage field', taskRecord);
            }
        }
    }
    
    public static void updateTaskData(List<Task> tasks, Map<String, SObject> dataToUpdate) {
        for(Task taskRecord : tasks) {
            if(taskRecord.Subject.equals('Subject11')) {
                taskRecord.Status = 'In Progress';
                //To complete activity Status the Activity date should be less than today that's why I have added today()-1 value
                taskRecord.ActivityDate = Date.today()-1;
                taskRecord.Vonage_Call_Disposition__c = GlobalConstants.TASK_CALL_DISPOSITION_COVID19;
                dataToUpdate.put('update Subject11 task', taskRecord);
            }
            if(taskRecord.Subject.equals('Subject Left VM')) {
                taskRecord.Status = GlobalConstants.TASK_STATUS_COMPLETED;
                dataToUpdate.put('update Subject Left VM task', taskRecord);
            }
        }
    }

    @isTest
    static void shouldUpdateContactOnTaskForInsert() {
        List<Task> tasks = getFakeTasks(true);
        List<Contact> contacts = getFakeContacts(true);
        contacts[0].UUID__c = 'TestUUID1';
        contacts[1].UUID__c = 'TestUUID2';
        tasks[0].Saleslady_Contact_UUID__c = contacts[0].UUID__c;
        tasks[1].Saleslady_Contact_UUID__c = contacts[1].UUID__c;


        Test.startTest();
        TaskTriggerHandler handlerInstance = new TaskTriggerHandler();
        handlerInstance.setTriggerContext('after insert', true);
        handlerInstance.taskSelector = (TaskSelector) MockService.createMock(
                TaskSelector.class,
                new Map<String, Object>{
                        'getTasksWithAdditionalFieldsByIds' => tasks });
        handlerInstance.contactSelector = (ContactSelector) MockService.createMock(
                ContactSelector.class,
                new Map<String, Object>{
                        'getContactsByUUIDs' => contacts });
        List<Task> tasksToUpdate = handlerInstance.getRecordsToUpdateContactOnTask(tasks, null);
        Test.stopTest();

        System.assertEquals(tasksToUpdate[0].Salesforce_Contact__c, contacts[0].Id + ' ' + contacts[0].Name, 'Should update task field from contact values');
        System.assertEquals(tasksToUpdate[1].Salesforce_Contact__c, contacts[1].Id + ' ' + contacts[1].Name, 'Should update task field from contact values');
    }
    
    @isTest
    static void shouldUpdateContactOnTaskForUpdate() {
        List<Task> tasks = getFakeTasks(true);
        List<Contact> contacts = getFakeContacts(true);
        contacts[0].UUID__c = 'TestUUID1';
        contacts[1].UUID__c = 'TestUUID2';
        tasks[0].Saleslady_Contact_UUID__c = contacts[0].UUID__c;
        tasks[1].Saleslady_Contact_UUID__c = contacts[1].UUID__c;
        List<Task> tasksAfterUpdate = tasks.deepClone();
        tasksAfterUpdate[0].Id = tasks[0].Id;
        tasksAfterUpdate[1].Id = tasks[1].Id;
        tasksAfterUpdate[0].Saleslady_Contact_UUID__c = contacts[1].UUID__c;
        tasksAfterUpdate[1].Saleslady_Contact_UUID__c = contacts[0].UUID__c;

        Test.startTest();
        TaskTriggerHandler handlerInstance = new TaskTriggerHandler();
        handlerInstance.setTriggerContext('after insert', false);
        handlerInstance.taskSelector = (TaskSelector) MockService.createMock(
                TaskSelector.class,
                new Map<String, Object>{
                        'getTasksWithAdditionalFieldsByIds' => tasks });
        handlerInstance.contactSelector = (ContactSelector) MockService.createMock(
                ContactSelector.class,
                new Map<String, Object>{
                        'getContactsByUUIDs' => contacts });
        List<Task> tasksToUpdate = handlerInstance.getRecordsToUpdateContactOnTask(tasks, new Map<Id, Task> (tasksAfterUpdate));
        Test.stopTest();

        System.assertEquals(tasksToUpdate[0].Salesforce_Contact__c, contacts[0].Id + ' ' + contacts[0].Name, 'Should update task field from contact values');
        System.assertEquals(tasksToUpdate[1].Salesforce_Contact__c, contacts[1].Id + ' ' + contacts[1].Name, 'Should update task field from contact values');
    }

    public static void updateContactOnTask(List<Task> tasks, Map<String, SObject> dataToUpdate) {
        Contact contactRecord = [SELECT Id, Name, UUID__c
                                 FROM Contact
                                 WHERE UUID__c = '12345678'];
        for(Task taskRecord : tasks) {
            if(taskRecord.Subject == 'Subject Test') {
                taskRecord.Saleslady_Contact_UUID__c = contactRecord.UUID__c;
                dataToUpdate.put('update contact Date', taskRecord);
            }
        }
    }

    static void verifyUpdateLeadEngagementFields(List<Task> tasks) {
        Lead leadRecord = [
                SELECT Id,Name
                FROM Lead
                WHERE Email = 'ukClient@wework.com'
                LIMIT 1
        ];
        for (Task taskRecord : tasks) {
            if (taskRecord.Subject == GlobalConstants.TASK_SUBJECT_ENGAGE_CAMPAIGN) {
                //System.assertEquals(1, leadRecord.Engage_Emails_Sent__c);
               // System.assertEquals(taskRecord.CreatedDate, leadRecord.Last_Engage_Email_Sent__c);
            }
        }
    }

    static void verifyUpdateFieldForNVMCallsOnUpdate() {
        Task taskRecord = [SELECT CallDisposition, Vonage_Call_Disposition__c
                           FROM Task
                           WHERE Subject = 'Subject11'
                           LIMIT 1];
        System.assertEquals(GlobalConstants.TASK_CALL_DISPOSITION_COVID19, taskRecord.CallDisposition, 'CallDisposition should be COVID-19');
        System.assertEquals(taskRecord.Vonage_Call_Disposition__c, taskRecord.CallDisposition, 'Field values should be equal');
    }

    static void verifyUpdateFieldForNVMCallsOnInsert(List<Task> tasks) {
        for(Task taskRecord : tasks) {
            if(taskRecord.Subject == GlobalConstants.TASK_SUBJECT_ENGAGE_CAMPAIGN) {
                System.assertEquals(GlobalConstants.TASK_CALL_DISPOSITION_COVID19, taskRecord.CallDisposition, 'CallDisposition should be COVID-19');
                System.assertEquals(taskRecord.Vonage_Call_Disposition__c, taskRecord.CallDisposition, 'Field values should be equal');
            }
        }
    }

    @isTest
    static void shouldUpdateJourneyNMDNextContactDate() {
        List<Task> tasks = getFakeTasks(true);
        List<Journey__c> journeys = getFakeJourneys(true);
        List<Contact> contacts = getFakeContacts(true);
        tasks[0].Status = 'In Progress';
        tasks[0].ActivityDate = Date.today()-1;
        tasks[0].CallDisposition = 'Busy / No answer';
        tasks[0].WhatId = journeys[0].Id;
        tasks[1].Status = GlobalConstants.TASK_STATUS_COMPLETED;
        tasks[1].WhatId = journeys[0].Id;
        tasks[1].CallDisposition = 'Busy / No answer';
        journeys[0].Primary_Contact__c = contacts[0].Id;

        Test.startTest();
        TaskTriggerHandler handlerInstance = new TaskTriggerHandler();
        handlerInstance.journeySelector = (JourneySelector) MockService.createMock(
                JourneySelector.class,
                new Map<String, Object>{
                        'getJourneysWithAdditionalFieldsByIds' => journeys });
        List<Journey__c> journeysToUpdate = handlerInstance.getJourneyToUpdateNMDNextContactDate(tasks);
        Test.stopTest();


        System.assertEquals(GlobalConstants.TASK_STATUS_COMPLETED, tasks[0].Status, 'Should update tasks status to completed');
        System.assertEquals(GlobalConstants.TASK_STATUS_COMPLETED, tasks[1].Status, 'Should update tasks status to completed');
        System.assertEquals(journeysToUpdate[0].Primary_Contact__c, tasks[0].WhoId, 'Should update primary contact to contact Id');
    }

    @isTest
    static void shouldUpdateTaskFieldsForNVMCallsOnInsert() {
        List<Task> tasks = getFakeTasks(true);
        tasks[0].Vonage_Call_Disposition__c = 'Do Not Call';

        Test.startTest();
        TaskTriggerHandler handlerInstance = new TaskTriggerHandler(tasks, null, null, null);
        handlerInstance.setTriggerContext('before insert', true);
        handlerInstance.updateTaskFieldsForNVMCalls();
        Test.stopTest();

        System.assertEquals('Do Not Call', tasks[0].CallDisposition, 'CallDisposition should be Do Not Call');
        System.assertEquals(tasks[0].Vonage_Call_Disposition__c, tasks[0].CallDisposition, 'Field values should be equal');
        System.assertEquals(null, tasks[1].CallDisposition, 'CallDisposition should be null');
    }

    @isTest
    static void shouldUpdateTaskFieldsForNVMCallsOnUpdate() {
        List<Task> tasks = getFakeTasks(true);
        tasks[0].Vonage_Call_Disposition__c = GlobalConstants.TASK_CALL_DISPOSITION_COVID19;
        tasks[1].Vonage_Call_Disposition__c = GlobalConstants.TASK_CALL_DISPOSITION_COVID19;

        List<Task> tasksBeforeUpdate = tasks.deepClone();
        tasksBeforeUpdate[0].Id = tasks[0].Id;
        tasksBeforeUpdate[1].Id = tasks[1].Id;
        tasksBeforeUpdate[0].Vonage_Call_Disposition__c = 'Do Not Call';
        tasksBeforeUpdate[1].Vonage_Call_Disposition__c = null;

        Test.startTest();
        TaskTriggerHandler handlerInstance = new TaskTriggerHandler(tasks, null, null, new Map<Id, Task> (tasksBeforeUpdate));
        handlerInstance.updateTaskFieldsForNVMCalls();
        Test.stopTest();


        System.assertEquals(GlobalConstants.TASK_CALL_DISPOSITION_COVID19, tasks[0].CallDisposition, 'CallDisposition should be COVID-19');
        System.assertEquals(tasks[0].Vonage_Call_Disposition__c, tasks[0].CallDisposition, 'Field values should be equal');
        System.assertEquals(GlobalConstants.TASK_CALL_DISPOSITION_COVID19, tasks[1].CallDisposition, 'CallDisposition should be COVID-19');
        System.assertEquals(GlobalConstants.TASK_CALL_DISPOSITION_COVID19, tasks[1].Vonage_Call_Disposition__c, 'Vonage_Call_Disposition__c should be COVID-19');

    }

    @isTest
    static void shouldUpdateOutreachStageOnJourneyForUpdate() {
        List<Task> tasks = getFakeTasks(true);
        List<Contact> contacts = getFakeContacts(true);
        contacts[0].UUID__c = 'TestUUID1';
        contacts[1].UUID__c = 'TestUUID2';
        tasks[0].Saleslady_Contact_UUID__c = contacts[0].UUID__c;
        tasks[1].Saleslady_Contact_UUID__c = contacts[1].UUID__c;
        tasks[0].Subject = 'FastCall Outbound Call';
        tasks[0].Subject = '';
        List<Journey__c> journeys = getFakeJourneys(true);
        journeys[0].Primary_Contact__c = contacts[0].Id;
        List<Task> tasksBeforeUpdate = tasks.deepClone();
        tasksBeforeUpdate[0].Id = tasks[0].Id;
        tasksBeforeUpdate[1].Id = tasks[1].Id;
        tasksBeforeUpdate[0].Subject = 'fc_EmptySubject';
        tasksBeforeUpdate[1].Subject = 'fc_EmptySubject';
        tasksBeforeUpdate[0].Saleslady_Contact_UUID__c = contacts[1].UUID__c;
        tasksBeforeUpdate[1].Saleslady_Contact_UUID__c = contacts[0].UUID__c;
        journeys[0].Primary_Contact__c = contacts[0].Id;
        journeys[1].Primary_Contact__c = contacts[1].Id;
        journeys[0].Status__c = GlobalConstants.JOURNEY_STATUS_KNOWN;
        journeys[1].Status__c = GlobalConstants.JOURNEY_STATUS_KNOWN;
        tasks[0].WhatId = journeys[0].Id;
        tasks[1].WhatId = journeys[1].Id;

        Test.startTest();
        TaskTriggerHandler handlerInstance = new TaskTriggerHandler();
        handlerInstance.setTriggerContext('before insert', false);
        handlerInstance.journeySelector = (JourneySelector) MockService.createMock(
                JourneySelector.class,
                new Map<String, Object>{
                        'getJourneysByStatusAndIds' => journeys,
                        'getJourneysByStatusAndContactAndLeadIds' => journeys });
        TaskTriggerHandler.JourneysAndTasksWrapper journeysAndTasks =
                handlerInstance.getJourneysAndTasksForOutreachStageUpdate(tasks, new Map<Id, Task> (tasksBeforeUpdate));
        Test.stopTest();

        System.assertEquals(journeysAndTasks.tasks[0].Type, GlobalConstants.TASK_TYPE_CALL, 'Should tasks Type to Call');
        System.assertEquals(journeysAndTasks.tasks[0].Priority, 'Normal', 'Should tasks Priority to Normal');
        System.assertEquals(journeysAndTasks.tasks[0].WhatId, journeysAndTasks.journeys[0].Id, 'Should tasks WhatId to journey Id');
    }

    @isTest
    static void shouldUpdateUpdateEngagementFieldsOnLead() {
        List<Task> tasks = getFakeTasks(true);
        List<Lead> leads = getFakeLeads(true);
        //leads[1].Engage_Emails_Sent__c = 1;
        tasks[0].WhoId = leads[0].Id;
        tasks[1].WhoId = leads[1].Id;
        tasks[0].Subject = GlobalConstants.TASK_SUBJECT_ENGAGE_CAMPAIGN + ' xyz';
        tasks[1].Subject = GlobalConstants.TASK_SUBJECT_ENGAGE_CAMPAIGN + ' xyz2';

        Test.startTest();
        TaskTriggerHandler handlerInstance = new TaskTriggerHandler();
        handlerInstance.leadSelector = (LeadSelector) MockService.createMock(
                LeadSelector.class,
                new Map<String, Object>{
                        'getLeadsById' => leads });
        List<Lead> leadsAfterUpdate =
                handlerInstance.getRecordsToUpdateEngagementFields(tasks);
        Test.stopTest();

       // System.assertEquals(leadsAfterUpdate[0].Engage_Emails_Sent__c, 1, 'Should increase Engage_Emails_Sent__c');
       // System.assertEquals(leadsAfterUpdate[1].Engage_Emails_Sent__c, 2, 'Should increase Engage_Emails_Sent__c');
    }


    @isTest
    static void shouldNotHandleChangeTaskOwner() {
        List<Task> tasks = getFakeTasks(true);
        List<Lead> leads = getFakeLeads(true);
        List<Journey__c> journeys = getFakeJourneys(true);
        List<GroupMember> groupMembers = getFakeGroupMembers(true);
        List<Group> groups = getFakeGroups(true);

        tasks[0].Status = GlobalConstants.TASK_STATUS_COMPLETED;
        tasks[0].Type= GlobalConstants.TASK_TYPE_CALL;
        tasks[1].Status = GlobalConstants.TASK_STATUS_COMPLETED;
        tasks[1].Type= GlobalConstants.TASK_TYPE_CALL;
        tasks[0].WhoId = leads[0].Id;
        tasks[0].WhatId = journeys[0].Id;
        leads[0].OwnerId = groups[0].Id;
        tasks[1].WhoId = leads[1].Id;
        tasks[1].WhatId = journeys[1].Id;
        leads[1].OwnerId = groups[0].Id;
        journeys[0].OwnerId = groups[0].Id;
        journeys[1].OwnerId = groups[0].Id;

        Test.startTest();
        TaskTriggerHandler handlerInstance = new TaskTriggerHandler();
        handlerInstance.journeySelector = (JourneySelector) MockService.createMock(
                JourneySelector.class,
                new Map<String, Object>{
                        'getJourneysByLeadsIds' => journeys,
                        'getJourneysWithAdditionalFieldsByIds' => journeys });
        handlerInstance.leadSelector = (LeadSelector) MockService.createMock(
                LeadSelector.class,
                new Map<String, Object>{
                        'getLeadsById' => leads });
        handlerInstance.groupMemberSelector = (GroupMemberSelector) MockService.createMock(
                GroupMemberSelector.class,
                new Map<String, Object>{
                        'getGroupMembersByGroupIds' => groupMembers });
        //List<SObject> recordsAfterUpdate =
               // handlerInstance.getRecordsToChangeTaskOwner(tasks);
        Test.stopTest();

        //ST-8139 No way to mock some group records, read-only on fields
        //System.assert(recordsAfterUpdate.isEmpty(), 'Should not get records for update');
    }

    @isTest
    static void shouldNotUpdateActiveReferer() {
        List<Task> tasks = getFakeTasks(true);
        List<Lead> leads = getFakeLeads(true);
        List<Contact> contacts = getFakeContacts(true);
        tasks[0].WhoId = contacts[0].Id;
        tasks[1].WhoId = leads[0].Id;
        contacts[0].Email = 'test@example.com';
        contacts[1].Email = 'test1@example.com';
        leads[0].Email = 'test@example.com';
        leads[1].Email = 'test1@example.com';

        Test.startTest();
        TaskTriggerHandler handlerInstance = new TaskTriggerHandler(tasks, null, null, null);
        handlerInstance.contactSelector = (ContactSelector) MockService.createMock(
                ContactSelector.class,
                new Map<String, Object>{
                        'getContactsByIdAndNotNullEmail' => contacts});
        handlerInstance.leadSelector = (LeadSelector) MockService.createMock(
                LeadSelector.class,
                new Map<String, Object>{
                        'getLeadsByIdAndNotNullEmail' => leads });
        handlerInstance.updateActiveReferrer();
        Test.stopTest();

        //TODO
        //ST-8139 Refactor after getting referrals to use mocks in related classes, small steps first
        //System.assertEquals(tasks[0].Name, null);
    }

    static List<Task> getFakeTasks() {
        Map<String, Object> recordsData = new Map<String, Object>();
        recordsData = new Map<String, Object>();
        recordsData.put('objectName', 'Task');
        recordsData.put('numberOfRecords', 2);

        return MockTestingUtility.getRecords(recordsData);
    }

    static List<GroupMember> getFakeGroupMembers(Boolean isFakeIds) {
        Map<String, Object> recordsData = new Map<String, Object>();
        recordsData = new Map<String, Object>();
        recordsData.put('objectName', 'GroupMember');
        recordsData.put('numberOfRecords', 1);
        return MockTestingUtility.getRecords(recordsData, isFakeIds);
    }

    static List<Group> getFakeGroups(Boolean isFakeIds) {
        Map<String, Object> recordsData = new Map<String, Object>();
        recordsData = new Map<String, Object>();
        recordsData.put('objectName', 'Group');
        recordsData.put('numberOfRecords', 1);
        return MockTestingUtility.getRecords(recordsData, isFakeIds);
    }

    static List<Task> getFakeTasks(Boolean isFakeIds) {
        Map<String, Object> recordsData = new Map<String, Object>();
        recordsData = new Map<String, Object>();
        recordsData.put('objectName', 'Task');
        recordsData.put('numberOfRecords', 2);
        return MockTestingUtility.getRecords(recordsData, isFakeIds);
    }

    static List<Contact> getFakeContacts(Boolean isFakeIds) {
        Map<String, Object> recordsData = new Map<String, Object>();
        recordsData = new Map<String, Object>();
        recordsData.put('objectName', 'Contact');
        recordsData.put('numberOfRecords', 2);
        return MockTestingUtility.getRecords(recordsData, isFakeIds);
    }

    static List<Lead> getFakeLeads(Boolean isFakeIds) {
        Map<String, Object> recordsData = new Map<String, Object>();
        recordsData = new Map<String, Object>();
        recordsData.put('objectName', 'Lead');
        recordsData.put('numberOfRecords', 2);
        return MockTestingUtility.getRecords(recordsData, isFakeIds);
    }

    static List<Journey__c> getFakeJourneys(Boolean isFakeIds) {
        Map<String, Object> recordsData = new Map<String, Object>();
        recordsData = new Map<String, Object>();
        recordsData.put('objectName', 'Journey__c');
        recordsData.put('numberOfRecords', 2);
        return MockTestingUtility.getRecords(recordsData, isFakeIds);
    }

    static void verifyUpdateNextNMDContactDateOnJourney(Map<String, SObject> dataToUpdate) {
        Journey__c journeyRecord = [SELECT Id, Primary_Contact__c
                                    FROM Journey__c
                                    WHERE Name = 'Test Customer1'
                                    LIMIT 1];
        Task taskRecord1 = (Task)dataToUpdate.get('update Subject11 task');
        Task taskRecord2 = (Task)dataToUpdate.get('update Subject Left VM task');
        Set<Id> setTaskId = new Set<Id>();
        setTaskId.add(taskRecord1.Id);
        setTaskId.add(taskRecord2.Id);
        for(Task currentTask: [SELECT Type, Status, CallDisposition, WhoId, WhatId, ActivityDate
                               FROM Task
                               WHERE Id IN: setTaskId]) {
            if(currentTask.Id == taskRecord2.Id){
                System.assertEquals(journeyRecord.Primary_Contact__c, currentTask.WhoId);
            } else if(currentTask.Id == taskRecord1.Id) {
                System.assertEquals(GlobalConstants.TASK_STATUS_COMPLETED, currentTask.Status);
            }
        }
    }

    static void verifyUpdateOutreachStageOnJourney() {
        List<Journey__c> journeys = [SELECT Id, Name, Outreach_Stage__c
                                     FROM Journey__c
                                     WHERE Name IN ('TestJourney22', 'Test11 Journey', 'Test3 Journey')];
        for(Journey__c journeyRecord : journeys) {
            if(journeyRecord.Name == 'TestJourney22' || journeyRecord.Name == 'Test11 Journey') {
               System.assertEquals('Call 1', journeyRecord.Outreach_Stage__c);
            }
            if(journeyRecord.Name == 'Test3 Journey') {
                System.assertEquals('Call 5', journeyRecord.Outreach_Stage__c);
            }
        }
    }

    static void testUpdateContactOnTask( Map<String, SObject> dataToUpdate) {
        Contact contactRecord = [SELECT Id, Name, UUID__c
                                 FROM Contact
                                 WHERE UUID__c = '12345678'];
        Task taskRecord = (Task)dataToUpdate.get('update contact Date');
        taskRecord = [SELECT Id, Saleslady_Contact_UUID__c, Salesforce_Contact__c
                      FROM Task
                      WHERE Id =: taskRecord.Id];
        System.assertEquals(contactRecord.UUID__c, taskRecord.Saleslady_Contact_UUID__c);
        System.assertEquals(contactRecord.Id+' '+contactRecord.Name, taskRecord.Salesforce_Contact__c);
    }

    /*static void verifyChangeTaskOwner() {
        User testUser = [SELECT Id
                         FROM User
                         WHERE Email = 'testUserEmail1@test.com'
                         LIMIT 1];
        Lead updatedLead = [SELECT Id, OwnerId
                            FROM Lead
                            WHERE Phone = '9874563210'];
        System.assertEquals(updatedLead.OwnerId, testUser.Id);        
        Journey__c updatedJourney = [SELECT Id, OwnerId
                                     FROM Journey__c
                                     WHERE Name = 'Test Customer123'
                                     LIMIT 1];
        System.assertEquals(updatedJourney.OwnerId, updatedLead.OwnerId);
    }*/

    static void verifyTaskType(){
        Task taskRec = [SELECT Id, Type, Subject
                        FROM Task
                        WHERE Subject LIKE '%quote%' AND Type != null];
        System.assertEquals(taskRec.Type, 'Send Letter/Quote');
    }
}