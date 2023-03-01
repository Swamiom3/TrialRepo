/**
 * @description       : 
 * @author            : Janek Medyk
 * @group             : 
 * @last modified on  : 09-07-2022
 * @last modified by  : Janek Medyk
**/
@isTest
public class CaseAssignmentTrHTest {
    @TestSetup
    static void initData() {
        Test.startTest();
        List<User> users = (List<User>)TestingUtility.getRecords(new Map<String, Object>{'objName' => 'User', 'numberOfRecords' => 2});
        List<Case> cases = (List<Case>)TestingUtility.getRecords(new Map<String, Object>{'objName' => 'Case', 'numberOfRecords' => 1});
        Test.stopTest();
    }
    
    @isTest
    private static void verifyCaseAssignment() {
        Profile systemAdminProfile = [SELECT id from Profile where name = 'WeWork System Administrator'];
        User weworkAdminUser = new User(
            LastName = 'testForCaseAssignUser',
            Alias = '#tu',
            Email = 'testForCaseAssignUser@test.pl',
            Username = 'testForCaseAssignUser@test.pl.service',
            CommunityNickname = '#tu',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = systemAdminProfile.Id
        );
        insert weworkAdminUser;
        List<Case> cases = new List<Case>();
        cases.add(new Case(
            RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get(GlobalConstants.CASE_RT_NAME_REA).getRecordTypeId(),
            Subject = 'Test Assignment',
            OwnerId = weworkAdminUser.Id
        ));
        System.runAs(weworkAdminUser) {
            Test.startTest();
            TestingUtility.insertListWithAssert(cases);
            Test.stopTest();
        }
        List<Case> casesAfter = [SELECT Id, OwnerId, RecordTypeId FROM Case WHERE Subject = 'Test Assignment'];
        System.assertEquals(casesAfter[0].RecordTypeId, cases[0].RecordTypeId);
    }
}