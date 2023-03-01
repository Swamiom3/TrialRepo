/**********************************************************************************************************
Author        :  Salesforce
Description   :  This is a test class for SalesforceSchedulerUtility and ServiceAppointmentToJSON apex classes.
-----------------------------------------------------------------------------------------------------------
VERSION        DATE            AUTHOR           DETAIL
1              02-Sep-2021     Salesforce       
**********************************************************************************************************/
@isTest
public with sharing class SalesforceSchedulerUtilityTest {
    @testSetup
    static void setup(){
        OperatingHours testOpHour = new OperatingHours(Name = 'EDT: Standard 9AM - 5PM Weekday');
        insert testOpHour;

        Building__c testBuildng = new Building__c(Name = 'Test Building', No_Longer_in_Use__c=false, Address__c='123 Mission St', City__c='california', Country__c='USA', Postal_Code__c='90168', State__c='california', Time_Zone__c='America/New_York');
        TestingUtility.insertWithAssert(testBuildng, 'Building not inserted');

        List<WorkType> testWorkTypes = new List<WorkType>();
        testWorkTypes.add(new WorkType(Name = 'Test Building - Virtual - CutOff', EstimatedDuration = 30.00, TimeFrameStart = 2, Tour_Format__c = 'Virtual', Next_Day_Touring_Cutoff__c='11:30AM', Building_Id__c=testBuildng.Id));
        testWorkTypes.add(new WorkType(Name = 'Test Building - Virtual - No Cutoff', EstimatedDuration = 30.00, TimeFrameStart = 0, Tour_Format__c = 'Virtual', Building_Id__c = testBuildng.Id));
        insert testWorkTypes;
    }

    @isTest
    private static void getBuildingWorkType_test_positive() {
        Building__c testBuildng = [SELECT Id FROM Building__c WHERE Name = 'Test Building' LIMIT 1];
        SalesforceSchedulerUtility.FlowRequestWrapper flowReqWrapper = new SalesforceSchedulerUtility.FlowRequestWrapper();
        flowReqWrapper.buildingId = testBuildng.Id;
        flowReqWrapper.tourFormat = 'Virtual';
        List<SalesforceSchedulerUtility.FlowResponseWrapper> flowResponseWrapper = SalesforceSchedulerUtility.getBuildingWorkType(new List<SalesforceSchedulerUtility.FlowRequestWrapper> {flowReqWrapper});
        System.assertNOTEquals(null, flowResponseWrapper[0].workTypeId, 'The WorkType Id should not null');
    }

    @isTest
    private static void convertSAtoJSON_test_positive() {
        Building__c testBuildng = [SELECT Id FROM Building__c WHERE Name = 'Test Building' LIMIT 1];
        ServiceAppointmentToJSON.SAInput saInput = new ServiceAppointmentToJSON.SAInput();
        saInput.ParentRecordId = testBuildng.Id;
        saInput.Comments = 'Test';
        saInput.ServiceTerritoryId = testBuildng.Id;
        List<ServiceAppointmentToJSON.SAOutput> saOutput = ServiceAppointmentToJSON.convertSAtoJSON(new List<ServiceAppointmentToJSON.SAInput> {saInput});
        System.assertNOTEquals(null, saOutput[0].serviceAppointmentFields, 'The serviceAppointmentFields is NOT Empty');
    }

    @isTest
    private static void getBuildingWorkType_test_negative() {
        Building__c testBuildng = [SELECT Id FROM Building__c WHERE Name = 'Test Building' LIMIT 1];
        SalesforceSchedulerUtility.FlowRequestWrapper flowReqWrapper = new SalesforceSchedulerUtility.FlowRequestWrapper();
        flowReqWrapper.buildingId = testBuildng.Id;
        flowReqWrapper.tourFormat = 'In-Person';
        List<SalesforceSchedulerUtility.FlowResponseWrapper> flowResponseWrapper = SalesforceSchedulerUtility.getBuildingWorkType(new List<SalesforceSchedulerUtility.FlowRequestWrapper> {flowReqWrapper});
        System.assertEquals(null, flowResponseWrapper[0].workTypeId, 'The WorkType Id should be null');
    }
}