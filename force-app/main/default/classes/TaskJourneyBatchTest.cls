@isTest
public class TaskJourneyBatchTest {
    private static final String WEWORK_SYSTEM_ADMINISTRATOR = 'WeWork System Administrator';
    @testSetup
    static void initData() {
    
        Account acc = TestingUtility.createAccount('testAcc1', true);
        List<Contact> contacts = (List<Contact>)TestingUtility.getRecords(new map<String,object>{'doInsert' => 'true','objName' => 'Contact','numberOfRecords'=> '2','lstEmails'=>new List<String>{'testContact1@example.com', 'testContact2@example.com'}});
        Map<String, Object> leadValues = new Map<String, Object> {
            'Email' => 'testLead1@example.com',
            'LastName' => 'testLead1',
            'Phone' => '4526181992'
        };
        Lead lead = TestingUtility.createLead(leadValues, true);

        List<Journey__c> journeys = new List<Journey__c>();
        Journey__c journey1 = new Journey__c();
        journey1.Name = 'testJourney1';
        journey1.Status__c = GlobalConstants.JOURNEY_STATUS_ACCEPTED;
        journey1.Primary_Contact__c = contacts.get(1).Id;
        journey1.NMD_Next_Contact_Date__c = System.today();
        journeys.add(journey1);
        
        Journey__c journey2 = new Journey__c();
        journey2.Name = 'testJourney2';
        journey2.Status__c = GlobalConstants.JOURNEY_STATUS_ACCEPTED;
        journey2.Primary_Contact__c = contacts.get(0).Id;
        journey2.NMD_Next_Contact_Date__c = System.today();
        journeys.add(journey2);
        
        Journey__c journey3 = new Journey__c();
        journey3.Name = 'testJourney3';
        journey3.Status__c = GlobalConstants.JOURNEY_STATUS_ACCEPTED;
        journey3.Primary_Lead__c = lead.Id;
        journey3.NMD_Next_Contact_Date__c = System.today();
        journeys.add(journey3);
        
        Journey__c journey4 = new Journey__c();
        journey4.Name = 'testJourney4';
        journey4.Status__c = GlobalConstants.JOURNEY_STATUS_WORKING;
        journey4.Primary_Lead__c = lead.Id;
        journey4.NMD_Next_Contact_Date__c = System.today();
        journeys.add(journey4);
        
        insert journeys;
    }
    
    @isTest
    private static void checkTaskUpdatedWithin60Days() {
        Task tsk = new Task();
        tsk.Type = 'Call';
        tsk.TaskSubtype = 'Task';
        tsk.WhoId = [SELECT Id FROM Lead WHERE LastName = 'testLead1' LIMIT 1].Id;
        tsk.Status = 'Not Started';
        tsk.Priority = 'Normal';
        tsk.Subject = 'Subject1';
        tsk.ActivityDate = System.today();
        insert tsk;
        
        Journey__c jrn = [SELECT Id, Status__c FROM Journey__c WHERE Name = 'testJourney4' LIMIT 1];
        Test.setCreatedDate(tsk.Id, System.now().addDays(-3));
        Test.setCreatedDate(jrn.Id, System.now().addDays(-3));
        
        Test.startTest();
        Database.executeBatch(new TaskJourneyBatch(), 200);
        Test.stopTest();
        
        Journey__c journeyAfter = [SELECT Id, Status__c FROM Journey__c WHERE Name = 'testJourney4' LIMIT 1];
        System.assertEquals(GlobalConstants.JOURNEY_STATUS_WORKING, journeyAfter.Status__c, 'Journey status should not change.');
    }
    
    @isTest
    private static void checkEventUpdatedWithin60Days() {
        Event evt = new Event();
        evt.Type = 'Meeting';
        evt.EventSubtype = 'Event';
        evt.WhoId = [SELECT Id FROM Lead WHERE LastName = 'testLead1' LIMIT 1].Id;
        evt.Subject = 'Subject1';
        evt.ActivityDateTime = System.now();
        evt.DurationInMinutes = 666;
        insert evt;
        
        Journey__c jrn = [SELECT Id, Status__c FROM Journey__c WHERE Name = 'testJourney4' LIMIT 1];
        Test.setCreatedDate(evt.Id, System.now().addDays(-3));
        Test.setCreatedDate(jrn.Id, System.now().addDays(-3));
        
        Test.startTest();
        Database.executeBatch(new TaskJourneyBatch(), 200);
        Test.stopTest();
        
        Journey__c journeyAfter = [SELECT Id, Status__c FROM Journey__c WHERE Name = 'testJourney4' LIMIT 1];
        System.assertEquals(GlobalConstants.JOURNEY_STATUS_WORKING, journeyAfter.Status__c, 'Journey status should not change.');
    }
    
    @isTest
    private static void checkTaskUpdatedOver60DaysAgo() {
        User weworkAdminUser = UtilUser.createUser([SELECT Id FROM Profile WHERE Name = :WEWORK_SYSTEM_ADMINISTRATOR].Id, true);
        PermissionSetGroup psg = [SELECT Id FROM PermissionSetGroup WHERE DeveloperName = 'WeWork_System_Administrator'];
        insert new PermissionSetAssignment(AssigneeId = weworkAdminUser.Id, PermissionSetGroupId = psg.Id);
        System.runAs(weworkAdminUser) {
            Task tsk = new Task();
            tsk.Type = 'Call';
            tsk.TaskSubtype = 'Task';
            tsk.WhoId = [SELECT Id FROM Lead WHERE LastName = 'testLead1' LIMIT 1].Id;
            tsk.Status = 'Not Started';
            tsk.Priority = 'Normal';
            tsk.Subject = 'Subject1';
            tsk.ActivityDate = System.today();
            insert tsk;
            
            Journey__c jrn = [SELECT Id, Status__c FROM Journey__c WHERE Name = 'testJourney4' LIMIT 1];
            Test.setCreatedDate(tsk.Id, System.now().addDays(-99));
            Test.setCreatedDate(jrn.Id, System.now().addDays(-99));
            
            Test.startTest();
            Database.executeBatch(new TaskJourneyBatch(), 200);
            Test.stopTest();
        }
        
        Journey__c journeyAfter = [SELECT Id, Status__c FROM Journey__c WHERE Name = 'testJourney4' LIMIT 1];
        System.assertEquals(GlobalConstants.JOURNEY_STATUS_DEFERRED, journeyAfter.Status__c, 'Journey status should be in Deferred status.');
    }
    
    @isTest
    private static void checkEventUpdatedOver60DaysAgo() {
        User weworkAdminUser = UtilUser.createUser([SELECT Id FROM Profile WHERE Name = :WEWORK_SYSTEM_ADMINISTRATOR].Id, true);
        PermissionSetGroup psg = [SELECT Id FROM PermissionSetGroup WHERE DeveloperName = 'WeWork_System_Administrator'];
        insert new PermissionSetAssignment(AssigneeId = weworkAdminUser.Id, PermissionSetGroupId = psg.Id);
        System.runAs(weworkAdminUser) {
            Event evt = new Event();
            evt.Type = 'Meeting';
            evt.EventSubtype = 'Event';
            evt.WhoId = [SELECT Id FROM Lead WHERE LastName = 'testLead1' LIMIT 1].Id;
            evt.Subject = 'Subject1';
            evt.ActivityDateTime = System.now();
            evt.DurationInMinutes = 666;
            insert evt;
            
            Journey__c jrn = [SELECT Id, Status__c FROM Journey__c WHERE Name = 'testJourney4' LIMIT 1];
            Test.setCreatedDate(evt.Id, System.now().addDays(-99));
            Test.setCreatedDate(jrn.Id, System.now().addDays(-99));
            
            Test.startTest();
            Database.executeBatch(new TaskJourneyBatch(), 200);
            Test.stopTest();
        }
        
        Journey__c journeyAfter = [SELECT Id, Status__c FROM Journey__c WHERE Name = 'testJourney4' LIMIT 1];
        System.assertEquals(GlobalConstants.JOURNEY_STATUS_DEFERRED, journeyAfter.Status__c, 'Journey status should be in Deferred status.');
    }
    
    @isTest
    private static void testScheduler() {
        Test.StartTest();
        TaskJourneyScheduler sch = new TaskJourneyScheduler();
        String schTime = '0 0 0 * * ?';
        System.Schedule('Test scheduler', schTime, sch);
        Test.stopTest();
    }
}