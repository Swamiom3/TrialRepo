@isTest
public class CaseUpdateStatusTrHTest {
    private static final Id REA_REC_TYPE_ID = Schema.SObjectType.Case.getRecordTypeInfosByName().get('REA').getRecordTypeId();
    private static final String GROUP_NAME = 'test group';

    @testSetup 
    static void initData() {
        Group testGroup = new Group(Name = GROUP_NAME, Type = 'Queue');
        insert testGroup;
        System.runAs(new User(Id = UserInfo.getUserId())) {
            QueuesObject testQueue = new QueueSObject(QueueID = testGroup.id, SobjectType = 'Case');
            insert testQueue;
        }
        List<Case> cases = new List<Case>();
        cases.add(new Case(Subject = 'Test Case', RecordTypeId = CaseUpdateStatusTrH.SUPPORT_REC_TYPE_ID));
        cases.add(new Case(Subject = 'Test Case 1', RecordTypeId = CaseUpdateStatusTrH.SUPPORT_REC_TYPE_ID, OwnerId = testGroup.Id));
        cases.add(new Case(Subject = 'Test Case 2', RecordTypeId = REA_REC_TYPE_ID, OwnerId = testGroup.Id));
        insert cases;
    }
    
    @isTest
    private static void verifyUpdateCaseStatus() {
        List<Case> casesInserted = [SELECT Subject, Status, OwnerId FROM Case];
        Group testGroup  = [SELECT Id FROM Group WHERE Name = :GROUP_NAME];
        System.assertNotEquals(CaseUpdateStatusTrH.CASE_STATUS_ACCEPTED, casesInserted[0].Status);
        System.assertNotEquals(CaseUpdateStatusTrH.CASE_STATUS_ACCEPTED, casesInserted[1].Status);
        System.assertNotEquals(CaseUpdateStatusTrH.CASE_STATUS_ACCEPTED, casesInserted[2].Status);
        casesInserted[0].OwnerId = testGroup.Id;
        casesInserted[1].OwnerId = userInfo.getUserId();
        casesInserted[2].OwnerId = userInfo.getUserId();

        Test.startTest();
        update casesInserted;
        Test.stopTest();

        List<Case> casesUpdated = [SELECT Id, Status FROM Case];
        System.assertEquals(CaseUpdateStatusTrH.CASE_STATUS_NEW, casesUpdated[0].Status);
        System.assertEquals(CaseUpdateStatusTrH.CASE_STATUS_ACCEPTED, casesUpdated[1].Status);
        System.assertNotEquals(CaseUpdateStatusTrH.CASE_STATUS_ACCEPTED, casesUpdated[2].Status);
    }
}