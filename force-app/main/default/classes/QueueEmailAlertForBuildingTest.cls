/************************************************************************************************************************************
Author      :   Salesforce
Description :   This class provides sufficient test coverage for QueueEmailAlertForBuilding class
----------------------------------------------------------------------------------------------------------------------------------
VERSION     DATE                AUTHOR                DETAIL
1           16 November 2021   Salesforce            Initial Developement
**************************************************************************************************************************************/
@isTest
public with sharing class QueueEmailAlertForBuildingTest {
    @testSetup
    public static void testSetup() {
        List<Building__c> buildings = (List<Building__c>)TestingUtility.getRecords(new Map<String, Object>{'objName' => 'Building__c', 'numberOfRecords' => 1});
    }

    @isTest
    private static void verifyQueueEmailAlertForBuildings() {
        Map<Id, List<String>> buildingMapForMismatchEmail = new Map<Id, List<String>>();
        Building__c building = [SELECT Id, Name FROM Building__c LIMIT 1];
        buildingMapForMismatchEmail.put(building.Id, new List<String> { building.Name, 'test', 'USD', 'CAD' });
        System.assertEquals(0, QueueEmailAlertForBuilding.countEmailInvocation, 'Email already Sent');
        Test.startTest();
        System.enqueueJob(new QueueEmailAlertForBuilding(buildingMapForMismatchEmail));
        Test.stopTest();
        System.assertEquals(1, QueueEmailAlertForBuilding.countEmailInvocation, 'Email not sent');
    }

    @isTest
    private static void verifyQueueEmailAlertForNoRecords() {
        Map<Id, List<String>> buildingMapForMismatchEmail = new Map<Id, List<String>>();
        System.assertEquals(0, QueueEmailAlertForBuilding.countEmailInvocation, 'Email already Sent');
        Test.startTest();
        System.enqueueJob(new QueueEmailAlertForBuilding(buildingMapForMismatchEmail));
        Test.stopTest();
        System.assertEquals(0, QueueEmailAlertForBuilding.countEmailInvocation, 'Wrong Email Sent');
    }
}