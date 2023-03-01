/************************************************************************************************************************************
    Author      :   Mikołaj Juras
    Description :   Test class for TaskProactiveCheckInValidationTrH
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION     DATE                AUTHOR                  DETAIL
    1           23 Feb 2021         Mikołaj Juras           ST-7722 security validation for Practive CheckIn Task
**************************************************************************************************************************************/

@isTest
public class TaskProactiveCheckInValidationTrHTest {

    private static final String TEST_USERNAME = 'testuserjohn123@example.com';
    private static final String TEST_ADMIN_USERNAME = 'testadminjohn123@example.com';
    
    private static final String TASK_TYPE_PROACTIVE_CHECKIN = 'Proactive Check-In';
    private static final String TASK_TYPE_OTHER = 'Other';   

    @testSetup
    static void makeData() {
        User standardUser = UtilUser.createUser([SELECT Id FROM Profile WHERE Name = 'WeWork Inside Sales'].Id, false);
        standardUser.Username = TEST_USERNAME;

        User adminUser = UtilUser.createUser([SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id, false);
        adminUser.Username = TEST_ADMIN_USERNAME;

        insert new List<User>{standardUser, adminUser};

        List<Task> tasksToInsert = new List<Task>();
        //insert 100 tasks, 50 are proactive checkin type
        for(Integer i=0; i <50; i ++) {
            Task task1 = new Task(Subject = TASK_TYPE_OTHER + i,
                                  RecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('General').getRecordTypeId(),
                                  Type = TASK_TYPE_OTHER
            );

            Task task2 = new Task(Subject = TASK_TYPE_PROACTIVE_CHECKIN + i,
            RecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('General').getRecordTypeId(),
            Type = TASK_TYPE_PROACTIVE_CHECKIN
            );
            tasksToInsert.addAll(new List<Task>{task1, task2});
        }

        System.runAs(standardUser) {
            insert tasksToInsert;
        }

        System.assertEquals([SELECT count() FROM Task], 100, 'all task should be inserted');
    }

    @isTest
    public static void testUpdateWhoIdFieldStandardUser() {

        User standardUser = [SELECT Id, Name, ProfileId, Profile.Name FROM User WHERE UserName = :TEST_USERNAME];
    

        List<Task> proActiveCheckInTasksToUpdate = new List<task>();

        System.runAs(standardUser) {
            Account acc = TestingUtility.createAccount('test account name', true);

            Contact con = TestingUtility.createContact(new Map<String, Object>{
                'Email' => 'user@unit-test.com',
                'AccountId' => acc.Id
            }, true);

            for(Task t : [SELECT Id FROM Task WHERE Type = :TASK_TYPE_PROACTIVE_CHECKIN]) {
                t.WhoId = con.Id;
                proActiveCheckInTasksToUpdate.add(t);
            }
               
            Test.startTest();
            update proActiveCheckInTasksToUpdate;
            Test.stopTest();
        }

        System.assertEquals([SELECT count() FROM Task WHERE WhoId != null AND Type = 'Proactive Check-In'], 50, 'all proactive checkin task should have name populated');
    }

    @isTest
    public static void testUpdateOtherFieldStandardUser() {

        User standardUser = [SELECT Id, Name, ProfileId, Profile.Name FROM User WHERE UserName = :TEST_USERNAME];
        
        List<Task> proActiveCheckInToUpdateOtherFields = new List<task>();
        Boolean errorWasThrown = false;

        System.runAs(standardUser) {
            for(Task t : [SELECT Id FROM Task WHERE Type = :TASK_TYPE_PROACTIVE_CHECKIN LIMIT 5]) {
                t.CallDisposition = 'new test';
                proActiveCheckInToUpdateOtherFields.add(t);
            }
        
            Test.startTest();    
            try {
                update proActiveCheckInToUpdateOtherFields;
            } Catch (Exception e) {
                errorWasThrown = true;
            }
            Test.stopTest();
        }

        System.assert(errorWasThrown, 'Error messege shoud be thrown: ' + System.Label.ProactiveCheckInValidationMessege);
        System.assertEquals([SELECT count() FROM Task WHERE CallDisposition = 'new test'], 0, 'no proactive checkin task should have CallDisposition edited');
    }

    @isTest
    public static void testUpdateOtherFieldOtherTypeStandardUser() {

        User standardUser = [SELECT Id, Name, ProfileId, Profile.Name FROM User WHERE UserName = :TEST_USERNAME];
        
        List<Task> proActiveCheckInToUpdateOtherFields = new List<task>();
        Boolean errorWasThrown = false;

        System.runAs(standardUser) {
            for(Task t : [SELECT Id FROM Task WHERE Type = :TASK_TYPE_OTHER]) {
                t.CallDisposition = 'new test';
                proActiveCheckInToUpdateOtherFields.add(t);
            }
        
            Test.startTest();    
            update proActiveCheckInToUpdateOtherFields;
            Test.stopTest();
        }

        System.assertEquals([SELECT count() FROM Task WHERE CallDisposition = 'new test'], 50, 'other task type should have CallDisposition edited');
    }
        

    @isTest
    public static void testInsertUpdateAdmin() {
 
        User adminUser = [SELECT Id, Name, ProfileId, Profile.Name FROM User WHERE UserName = :TEST_ADMIN_USERNAME];
   
        List<Task> proActiveCheckInToUpdateOtherFields = new List<task>();
        System.runAs(adminUser) { 
            for(Task t : [SELECT Id FROM Task WHERE Type = :TASK_TYPE_PROACTIVE_CHECKIN]) {
                t.CallObject = 'test call object';
                proActiveCheckInToUpdateOtherFields.add(t);
            }
               
            Test.startTest();
            update proActiveCheckInToUpdateOtherFields;
            Test.stopTest();
        }

        System.assertEquals([SELECT count() FROM Task WHERE Type = 'Proactive Check-In' AND CallObject = 'test call object'], 50, 'all proactive checkin task should have name populated');
    }
}