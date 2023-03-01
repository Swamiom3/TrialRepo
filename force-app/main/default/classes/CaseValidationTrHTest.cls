@isTest
public class CaseValidationTrHTest {
    private static final Id caseRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Support - Sales').getRecordTypeId();
    
    @TestSetUp
    static void initData() {
        List<Account> accounts = new List<Account>();
         
        List<Map<String,Object>> userData =  new List<Map<String,Object>>();
        Profile enterpriseSolutionProfile = [SELECT Id FROM Profile WHERE Name = 'WeWork Sales User'];
        userData.add(new Map<String,Object>{'LastName' => 'Testing1', 'Email' => 'standarduser1@example.com'});
        userData.add(new Map<String,Object>{'LastName' => 'Testing2', 'Email' => 'standarduser2@example.com'});
        TestingUtility.insertUserWithAssert(enterpriseSolutionProfile.Id, userData, true);
    }

    @isTest
    private static void validateUserToCloseCasesTest() {
        List<User> usersInserted = new List<User>();
        Profile wwInsideSalesProfile = [SELECT Id FROM Profile WHERE Name = 'WeWork Inside Sales'];
        Profile systemWWSupport = [SELECT Id FROM Profile WHERE Name = 'WeWork System Administrator'];
        User userWWSupprot = UtilUser.createUser(systemWWSupport.ID, true);
        PermissionSetGroup psg = [SELECT Id FROM PermissionSetGroup WHERE DeveloperName = 'WeWork_System_Administrator'];
        Test.calculatePermissionSetGroup(psg.Id);
        insert new PermissionSetAssignment(AssigneeId = userWWSupprot.Id, PermissionSetGroupId = psg.Id);
        
        usersInserted = [SELECT Id, Username, LastName, Email, ProfileId, EmailEncodingKey FROM User WHERE Email = :'standarduser1@example.com' OR Email = :'standarduser2@example.com'];
        Group testGroup = new Group(Name = 'testGroup', Type = 'Queue');
        System.runAs(new User(Id = UserInfo.getUserId())) {
            TestingUtility.insertWithAssert(testGroup);
        }
        System.runAs(new User(Id = UserInfo.getUserId())) {
            QueuesObject testQueue = new QueueSObject(QueueID = testGroup.id, SobjectType = 'Case');
            TestingUtility.insertWithAssert(testQueue);
            GroupMember member = new GroupMember();
            member.UserOrGroupId = usersInserted[0].Id;
            member.GroupId = testGroup.Id;
            TestingUtility.insertWithAssert(member);
        }
        Map<String, Schema.RecordTypeInfo> mapCaseRtNameToInfo = Schema.SObjectType.Case.getRecordTypeInfosByName();
        List<Case> cases = new List<Case>();
        Case caseRecord1 = UtilCase.createCaseReadyToBeClosed(null, null, usersInserted[0].Id, null,
                                                           mapCaseRtNameToInfo.get('Enterprise Finance & Strategy').getRecordTypeId(), null, false);
        cases.add(caseRecord1);
        Case caseRecord2 = UtilCase.createCaseReadyToBeClosed (null, null, testGroup.Id, null,
                                                            mapCaseRtNameToInfo.get('Enterprise Finance & Strategy').getRecordTypeId(), null, false);
        cases.add(caseRecord2);
        System.runAs(usersInserted[0]) {
            TestingUtility.insertListWithAssert(cases);
        }
        cases[0] = prepareCaseToClose(cases[0]);
        cases[1] = prepareCaseToClose(cases[1]);
        //Reset recursive count
        SObjectTriggerHandler.clearLoopCount('CaseValidationTrH');
        
        Test.startTest();
        Boolean expectedExceptionThrown;
        try {
            User insideSalesUser = UtilUser.createUser(wwInsideSalesProfile.Id, true);
            insert new PermissionSetAssignment(AssigneeId = insideSalesUser.Id, PermissionSetGroupId = psg.Id);
            System.runAs(insideSalesUser) {
                Database.update(cases[0]);
           }
        } catch (Exception exc) {
            System.assertNotEquals(null, exc);
            expectedExceptionThrown = exc.getMessage().contains('Your profile does not have permission to take this action') ? true : false;
        }
        System.AssertEquals(true, expectedExceptionThrown);
        SObjectTriggerHandler.clearLoopCount('CaseValidationTrH');
        System.runAs(userWWSupprot) {
            Database.SaveResult  updateResult = Database.update(cases[1], false);
        }
        
        Test.stopTest();
        
        caseRecord2 = [SELECT Status, OwnerId FROM Case WHERE Id = :caseRecord2.Id];

        System.assertEquals('Closed', caseRecord2.Status);
        System.assertEquals(userWWSupprot.Id, caseRecord2.OwnerId);
    }

    private static Case prepareCaseToClose(Case caseRecord) {
        caseRecord.Status = 'Closed';
        caseRecord.Term_Sheet_Signed__c = 'Agreed';
        caseRecord.Deal_RSF__c = 10;
        caseRecord.Deal_USF__c = 10;
        caseRecord.Actual_EBITDA_Margin__c = 10;
        caseRecord.Configuration_Fee_USD__c = 10;
        caseRecord.Configuration_Payment_Terms__c = 'Upfront';
        caseRecord.Actual_EBITDA_Margin_with_broker_fee__c = 10;
        caseRecord.recordTypeId = caseRecordTypeId;
        // VR need to adjusted
        caseRecord.RootCause__c = 'Other';
        return caseRecord;
    }
}