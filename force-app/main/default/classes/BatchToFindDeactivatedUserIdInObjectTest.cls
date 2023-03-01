/*************************************************************************************************************************************
    Author      :   Pawel Biszczak
    Description :   This class provides sufficient test coverage for BatchToFindDeactivatedUserIdInObject class
    --------------------------------------------------------------------------------------------------------------------------------------
    VERSION    DATE           AUTHOR            DETAIL
    1          8 Aug, 2021    Pawel Biszczak    Initial Deployment
**************************************************************************************************************************************/
@isTest
public with sharing class BatchToFindDeactivatedUserIdInObjectTest {

    @isTest
    public static void shouldProceedWithRecords(){
        TestingUtility.getRecords(new Map<String, Object>{'objName' => 'Building__c', 'numberOfRecords' => 3});
        User userForBatch = new User();
        userForBatch.Id = UserInfo.getUserId();
        UserTriggerHandler.SendDeactivateUserStatus deactivateUserStatusWrapper = getFakeStatusWrapper();

        Test.startTest();
        BatchToFindDeactivatedUserIdInObject batchInstance =
                new BatchToFindDeactivatedUserIdInObject(0, userForBatch,
                                                         new Map<String,String>(),
                                                         deactivateUserStatusWrapper);
        Database.executeBatch(batchInstance);
        batchInstance.execute(null, new List<User>{ userForBatch });
        batchInstance.finish(null);
        Integer invocations = Limits.getEmailInvocations();
        Test.stopTest();

        System.assertEquals(1, invocations, 'Should send email using synchronous scope');
    }

    @isTest
    public static void shouldRunSearchForRecords(){
        List<User> users = getFakeUsers();
        List<Building__c> buildings = getFakeBuildings();
        buildings[0].Name = 'Fake Building 1';
        buildings[1].Name = 'Fake Building 2';
        buildings[0].OwnerId = users[0].Id;
        buildings[1].OwnerId  = users[1].Id;
        UserTriggerHandler.SendDeactivateUserStatus deactivateUserStatusWrapper = getFakeStatusWrapper();

        Test.startTest();
        BatchToFindDeactivatedUserIdInObject batchInstance =
                new BatchToFindDeactivatedUserIdInObject(0, users[0],
                                                         new Map<String,String>(),
                                                         deactivateUserStatusWrapper);
        batchInstance.execute(null, buildings);
        batchInstance.execute(null, buildings);
        batchInstance.currentIndex = 1;
        batchInstance.execute(null, buildings);
        batchInstance.currentIndex = 0;
        batchInstance.isTextArea = true;
        batchInstance.execute(null, buildings);
        Test.stopTest();

        System.assert(!batchInstance.sObjectsToTextBodyCSVMap.isEmpty(),
                      'Map of csv shouldn\'t be empty after execution');
        System.assert((batchInstance.sObjectsToTextBodyCSVMap.get('Building__c')).contains(buildings[0].Name),
                      'Map Should contain first building name');
        System.assert((batchInstance.sObjectsToTextBodyCSVMap.get('Building__c')).contains(buildings[1].Name),
                      'Map Should contain second building name');
    }

    @isTest
    public static void shouldThrowAnExceptionOnNullList(){
        List<User> users = getFakeUsers();
        List<Building__c> buildings;
        UserTriggerHandler.SendDeactivateUserStatus deactivateUserStatusWrapper = getFakeStatusWrapper();

        Test.startTest();
        try {
            BatchToFindDeactivatedUserIdInObject batchInstance =
                    new BatchToFindDeactivatedUserIdInObject(0, users[0],
                                                             new Map<String, String>(),
                                                             deactivateUserStatusWrapper);
            batchInstance.execute(null, buildings);
        } catch (NullPointerException ex) {
            System.assert(!String.isEmpty(ex.getMessage()), 'Exception should contain message');
        }
        Test.stopTest();
    }

    @isTest
    public static void shouldRunSearchForRecordsForCSVMap(){
        List<User> users = getFakeUsers();
        List<Building__c> buildings = getFakeBuildings();
        buildings[0].Name = 'Fake Building 1';
        buildings[1].Name = 'Fake Building 2';
        buildings[0].OwnerId = users[0].Id;
        buildings[1].OwnerId  = users[1].Id;
        UserTriggerHandler.SendDeactivateUserStatus deactivateUserStatusWrapper = getFakeStatusWrapper();

        Test.startTest();
        BatchToFindDeactivatedUserIdInObject batchInstance =
                new BatchToFindDeactivatedUserIdInObject(0, users[0],
                                                         new Map<String,String>{'Building__c '=> 'Fake Body'},
                                                         deactivateUserStatusWrapper);
        batchInstance.execute(null, buildings);
        batchInstance.execute(null, buildings);
        batchInstance.currentIndex = 1;
        batchInstance.execute(null, buildings);
        batchInstance.currentIndex = 0;
        batchInstance.isTextArea = true;
        batchInstance.execute(null, buildings);
        Test.stopTest();

        System.assert(!batchInstance.sObjectsToTextBodyCSVMap.isEmpty(),
                      'Map of csv shouldn\'t be empty after execution');
        System.assert((batchInstance.sObjectsToTextBodyCSVMap.get('Building__c')).contains(buildings[0].Name),
                      'Map Should contain first building name');
        System.assert((batchInstance.sObjectsToTextBodyCSVMap.get('Building__c')).contains(buildings[1].Name),
                      'Map Should contain second building name');
    }

    private static List<Building__c> getFakeBuildings() {
        Map<String, Object> recordsData = new Map<String, Object>();
        recordsData = new Map<String, Object>();
        recordsData.put('objectName', 'Building__c');
        recordsData.put('numberOfRecords', 2);
        return MockTestingUtility.getRecords(recordsData, true);
    }

    private static List<User> getFakeUsers() {
        Map<String, Object> recordsData = new Map<String, Object>();
        recordsData = new Map<String, Object>();
        recordsData.put('objectName', 'User');
        recordsData.put('numberOfRecords', 2);
        return MockTestingUtility.getRecords(recordsData, true);
    }

    private static UserTriggerHandler.SendDeactivateUserStatus getFakeStatusWrapper(){
        UserTriggerHandler.SendDeactivateUserStatus deactivateUserStatusWrapper =
                                                        new UserTriggerHandler.SendDeactivateUserStatus();
        List<Map<String,List<String>>> searchInObjectsValues = new List<Map<String,List<String>>>();
        Map<String,List<String>> buildingFieldsMap = new Map<String,List<String>>();
        buildingFieldsMap.put('Building__c', new List<String>{'OwnerId'});
        searchInObjectsValues.add(buildingFieldsMap);
        deactivateUserStatusWrapper.searchInObjects = searchInObjectsValues;
        deactivateUserStatusWrapper.subject = 'Hello &userId &userName';
        deactivateUserStatusWrapper.Emails = new Set<String>{'wework@example.com'};
        deactivateUserStatusWrapper.emailBody = 'FakeEmail Body For Deactivated Users';

        return deactivateUserStatusWrapper;
    }

}