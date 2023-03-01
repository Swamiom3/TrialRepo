/************************************************************************************************************************************
Author      :   Salesforce
Description :   This class provides sufficient test coverage for QueueEmailAlertForTour class
----------------------------------------------------------------------------------------------------------------------------------
VERSION     DATE                AUTHOR                DETAIL
1           16 November 2021   Salesforce            Initial Developement
**************************************************************************************************************************************/
@isTest
public class QueueEmailAlertForTourTest {
    @testSetup
    public static void testSetup() {
        List<Account> newAccount = (List<Account>)TestingUtility.getRecords(new Map<String, Object>{'objName' => 'Account', 'doInsert' => true, 'numberOfRecords' => 1});
        List<User> users = (List<User>)TestingUtility.getRecords(new Map<String, Object>{'objName' => 'User', 'doInsert' => true, 'numberOfRecords' => 2});
        List<Building__c> buildings = (List<Building__c>)TestingUtility.getRecords(new Map<String, Object>{'objName' => 'Building__c', 'numberOfRecords' => 1});
        buildings[0].Leasing_Manager_Id__c = users[0].Id;
        buildings[0].Leasing_Director_Id__c = users[1].Id;
        buildings[0].Email__c = users[0].Email;
        update buildings;
        insert new ServiceAppointment(Status='Scheduled', Building_ID__c = buildings[0].Id, SchedStartTime = System.now().addDays(2), ParentRecordId = newAccount[0].Id);
    }

    @isTest
    private static void verifyQueueEmailAlertForTour() {
        Map<Id, Id> serviceAppointmentIdsToSend = new Map<Id, Id>();
        for (ServiceAppointment sa : [SELECT Id, OwnerId, Status FROM ServiceAppointment LIMIT 1]) {
            serviceAppointmentIdsToSend.put(sa.Id, sa.OwnerId);
        }
        System.assertEquals(0, QueueEmailAlertForTour.countEmailInvocation, 'Email already Sent');
        Test.startTest();
        System.enqueueJob(new QueueEmailAlertForTour(serviceAppointmentIdsToSend, ServiceAppointmentConstants.TEMPLATE_TOUR_BOOKED_NOTIFICATION));
        Test.stopTest();
        System.assertEquals(1, QueueEmailAlertForTour.countEmailInvocation, 'Email not sent');
    }

    @isTest
    private static void verifyQueueEmailAlertForWrongTemplateName() {
        Map<Id, Id> serviceAppointmentIdsToSend = new Map<Id, Id>();
        for (ServiceAppointment sa : [SELECT Id, OwnerId, Status FROM ServiceAppointment LIMIT 1]) {
            serviceAppointmentIdsToSend.put(sa.Id, sa.OwnerId);
        }
        System.assertEquals(0, QueueEmailAlertForTour.countEmailInvocation, 'Email already Sent');
        Test.startTest();
        System.enqueueJob(new QueueEmailAlertForTour(serviceAppointmentIdsToSend, 'Test Email Template for test class'));
        Test.stopTest();
        System.assertEquals(0, QueueEmailAlertForTour.countEmailInvocation, 'Wrong Email Sent');
    }

    @isTest
    private static void verifyQueueEmailAlertForNoTours() {
        Map<Id, Id> serviceAppointmentIdsToSend = new Map<Id, Id>();
        System.assertEquals(0, QueueEmailAlertForTour.countEmailInvocation, 'Email already Sent');
        Test.startTest();
        System.enqueueJob(new QueueEmailAlertForTour(serviceAppointmentIdsToSend, ServiceAppointmentConstants.TEMPLATE_TOUR_BOOKED_NOTIFICATION));
        Test.stopTest();
        System.assertEquals(0, QueueEmailAlertForTour.countEmailInvocation, 'Wrong Email Sent');
    }
}