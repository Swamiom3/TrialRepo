/************************************************************************************************************************************
Author      :   Salesforce
Description :   This class provides sufficient test coverage for ServiceAppointmentSendEmailTrH class
----------------------------------------------------------------------------------------------------------------------------------
VERSION     DATE                AUTHOR                DETAIL
1           16 November 2021   Salesforce            Initial Developement
**************************************************************************************************************************************/
@isTest
public with sharing class ServiceAppointmentSendEmailTrHTest {
    @testSetup
    public static void testSetup() {
        List<Account> newAccount = (List<Account>)TestingUtility.getRecords(new Map<String, Object>{'objName' => 'Account', 'doInsert' => true, 'numberOfRecords' => 1});
        List<User> users = (List<User>)TestingUtility.getRecords(new Map<String, Object>{'objName' => 'User', 'doInsert' => true, 'numberOfRecords' => 1});
        List<Building__c> buildings = (List<Building__c>)TestingUtility.getRecords(new Map<String, Object>{'objName' => 'Building__c', 'numberOfRecords' => 1});
        User standardUser = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User'].Id,
            LastName = 'LastName123',
            Username = 'test@test.com' + System.currentTimeMillis(),
            CompanyName = 'Test_Comp',
            Email = 'test@test.com',
            IsActive = TRUE,
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US'
        );
        insert standardUser;
        insert new ServiceAppointment(Status='Scheduled', Building_ID__c = buildings[0].Id, SchedStartTime = System.now().addDays(2), ParentRecordId = newAccount[0].Id,OwnerId = standardUser.Id);
    }

    @isTest
    private static void verifyQueueEmailAlertForCompletedTour() {
        ServiceAppointment tour = [SELECT Id, Status FROM ServiceAppointment LIMIT 1];
        tour.Status = 'Completed';
        System.assertEquals(0, QueueEmailAlertForTour.countEmailInvocation, 'Email already Sent');
        Test.startTest();
        update tour;
        Test.stopTest();
        System.assertEquals(1, QueueEmailAlertForTour.countEmailInvocation, 'Email not sent');
    }

    @isTest
    private static void verifyQueueEmailAlertForScheduledTour() {
        Building__c building = [SELECT Id FROM Building__c LIMIT 1];
        Account accountRecord = [SELECT Id FROM Account LIMIT 1];
        System.assertEquals(0, QueueEmailAlertForTour.countEmailInvocation, 'Email already Sent');
        Test.startTest();
        insert new ServiceAppointment(Status='Scheduled', Building_ID__c = building.Id, SchedStartTime = System.now().addDays(2), ParentRecordId = accountRecord.Id);
        Test.stopTest();
        System.assertEquals(1, QueueEmailAlertForTour.countEmailInvocation, 'Email not sent');
    }

    @isTest
    private static void verifyQueueEmailAlertForRescheduledTour() {
        ServiceAppointment tour = [SELECT Id, SchedStartTime FROM ServiceAppointment LIMIT 1];
        tour.SchedStartTime = System.now().addDays(4);
        tour.Reschedule_Count__c = 1;
        System.assertEquals(0, QueueEmailAlertForTour.countEmailInvocation, 'Email already Sent');
        Test.startTest();
        update tour;
        Test.stopTest();
        System.assertEquals(1, QueueEmailAlertForTour.countEmailInvocation, 'Email not sent');
    }

    @isTest
    private static void verifyQueueEmailAlertForReassignTour() {
        ServiceAppointment tour = [SELECT Id, SchedStartTime FROM ServiceAppointment LIMIT 1];
        User userRecord = [SELECT Id FROM User WHERE LastName='testUser 1@test.com' AND Email='testUserEmail1@test.com' LIMIT 1];
        tour.OwnerId = userRecord.Id;
        System.assertEquals(0, QueueEmailAlertForTour.countEmailInvocation, 'Email already Sent');
        Test.startTest();
        update tour;
        Test.stopTest();
        System.assertEquals(1, QueueEmailAlertForTour.countEmailInvocation, 'Email not sent');
    }
}