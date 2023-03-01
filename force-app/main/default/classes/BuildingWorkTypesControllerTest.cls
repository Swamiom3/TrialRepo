/**********************************************************************************************************
Author        :  Salesforce
Description   :  This is a test class for BuildingWorkTypesController.
-----------------------------------------------------------------------------------------------------------
VERSION        DATE            AUTHOR           DETAIL
1              21-Aug-2021     Salesforce       
**********************************************************************************************************/
@isTest
private with sharing class BuildingWorkTypesControllerTest {
    @testSetup
    static void setup(){        
        Building__c testBuildng = new Building__c(Name = 'Test Building', No_Longer_in_Use__c=false, Address__c='123 Mission St', City__c='california', Country__c='USA', Postal_Code__c='90168', State__c='california', Time_Zone__c='America/New_York');
        TestingUtility.insertWithAssert(testBuildng, 'Building not inserted');
        WorkTypeGroup testWorkTypeGroup = new WorkTypeGroup(Name = 'In-Person');
        insert testWorkTypeGroup;
        testWorkTypeGroup = new WorkTypeGroup(Name = 'Virtual');
        insert testWorkTypeGroup;
        testWorkTypeGroup = new WorkTypeGroup(Name = 'In-Person with Cutoff');
        insert testWorkTypeGroup;
        testWorkTypeGroup = new WorkTypeGroup(Name = 'Virtual with Cutoff');
        insert testWorkTypeGroup;
        WorkType testWorkType = new WorkType(Name = 'Test Building - In-Person', Tour_Format__c = 'In-Person', EstimatedDuration = 30.00, Building_Id__c = testBuildng.id);
        insert testWorkType;
        testBuildng = new Building__c(Name = 'Test Building Virtual', No_Longer_in_Use__c=false, Address__c='123 Mission St', City__c='california', Country__c='USA', Postal_Code__c='90168', State__c='california', Time_Zone__c='America/New_York');
        TestingUtility.insertWithAssert(testBuildng, 'Building not inserted');
    }

    @isTest
    private static void getBuildingWorkTypes_test_positive() {
        Building__c testBuildng = [SELECT Id FROM Building__c WHERE Name = 'Test Building'];
        WorkType testWorkType = [SELECT Id, Name FROM WorkType WHERE Name = 'Test Building - In-Person' AND Building_Id__c =: testBuildng.id];
        BuildingWorkTypesController.getBuildingWorkTypes (testBuildng.Id);
        System.assertEquals('Test Building - In-Person', testWorkType.Name, 'The WorkType record name should be Test Building - In-Person');
    }

    @isTest
    private static void saveWorkType_test_positive() {
        Building__c testBuildng = [SELECT Id FROM Building__c WHERE Name = 'Test Building Virtual'];
        String workTypeStr = '{"uniqueId":"New","buildingId":"'+testBuildng.Id+'","name":"","tourFormat":"Virtual","estimatedDuration":"30.00","blockTimeAfterAppointment":"0","blockTimeBeforeAppointment":"5","blockSameDayTouring":false,"nextDayTouringCutoff":"","isEditable":false}';
        DatabaseResult response = BuildingWorkTypesController.saveWorkType(workTypeStr);
        WorkType testWorkType = [SELECT Id, Name FROM WorkType WHERE Tour_Format__c = 'Virtual' AND Building_Id__c =: testBuildng.id LIMIT 1];
        System.assertEquals(testWorkType.Id, response.data, 'The WorkType should be created');
        workTypeStr = '{"uniqueId":"'+response.data+'","buildingId":"'+testBuildng.Id+'","name":"","tourFormat":"In-Person","estimatedDuration":"30.00","blockTimeAfterAppointment":"0","blockTimeBeforeAppointment":"5","blockSameDayTouring":true,"nextDayTouringCutoff":"","isEditable":false}';
        DatabaseResult response1 = BuildingWorkTypesController.saveWorkType(workTypeStr);
        System.assertEquals(null, response1.data, 'The WorkType should not be updated');
        workTypeStr = '{"uniqueId":"'+response.data+'","buildingId":"'+testBuildng.Id+'","name":"","tourFormat":"Virtual","estimatedDuration":"30.00","blockTimeAfterAppointment":"0","blockTimeBeforeAppointment":"5","blockSameDayTouring":true,"nextDayTouringCutoff":"1:00PM","isEditable":false}';
        DatabaseResult response2 = BuildingWorkTypesController.saveWorkType(workTypeStr);
        System.assertEquals(testWorkType.Id, response2.data, 'The WorkType should be updated');
        workTypeStr = '{"uniqueId":"'+response.data+'","buildingId":"'+testBuildng.Id+'","name":"","tourFormat":"Virtual","estimatedDuration":"30.00","blockTimeAfterAppointment":"0","blockTimeBeforeAppointment":"5","blockSameDayTouring":false,"nextDayTouringCutoff":"1:00PM","isEditable":false}';
        DatabaseResult response3 = BuildingWorkTypesController.saveWorkType(workTypeStr);
        System.assertEquals(testWorkType.Id, response2.data, 'The WorkType should be updated');
    }

    @isTest
    private static void deleteWorkTypes_test() {
        Building__c testBuildng = [SELECT Id FROM Building__c WHERE Name = 'Test Building'];
        WorkType testWorkType = [SELECT Id FROM WorkType WHERE Name = 'Test Building - In-Person' AND Building_Id__c =:testBuildng.Id LIMIT 1];
        BuildingWorkTypesController.deleteWorkType(testWorkType.Id);
        List<WorkType> testWorkTypes = [SELECT Id FROM WorkType WHERE Name = 'Test Building - In-Person' AND Building_Id__c =:testBuildng.Id LIMIT 1];
        System.assertEquals(0, testWorkTypes.size(), 'The worktype should be deleted');
    }

    @isTest
    private static void getBuildingWorkTypes_test_negative() {
        String workTypeStr = BuildingWorkTypesController.getBuildingWorkTypes ('');
        System.assertEquals('{"workTypesData":[],"buildingData":{"attributes":{"type":"Building__c"}}}', workTypeStr, 'The WorkTypes should be emplty');
    }
}