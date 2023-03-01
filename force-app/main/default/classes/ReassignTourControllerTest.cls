/*************************************************************************************************************************************
 Author      :   Salesforce
 Description :   This is a test class for ReassignTourController

 --------------------------------------------------------------------------------------------------------------------------------------
 VERSION         DATE            AUTHOR              DETAIL
 1               14 Oct 2021     Salesforce       Initial Deployment
 **************************************************************************************************************************************/
@isTest
public class ReassignTourControllerTest {
    @testSetup
    public static void testSetup() {
        List<Account> newAccount = (List<Account>)TestingUtility.getRecords(new Map<String, Object>{'objName' => 'Account', 'doInsert' => true, 'numberOfRecords' => 1});
        List<User> users = (List<User>)TestingUtility.getRecords(new Map<String, Object>{'objName' => 'User', 'doInsert' => true, 'numberOfRecords' => 1});
        List<Building__c> buildings = (List<Building__c>)TestingUtility.getRecords(new Map<String, Object>{'objName' => 'Building__c', 'numberOfRecords' => 1});
        OperatingHours operatingHour = new OperatingHours(Name = 'EDT: Standard 9AM - 5PM Weekday', Building_id__c = buildings[0].Id);
        insert operatingHour;
        insert new ServiceTerritory (Building_Id__c = buildings[0].Id, Name = buildings[0].Name, OperatingHoursId = operatingHour.Id, IsActive = true);
        ServiceAppointment serviceAppointment = new ServiceAppointment(Status='Scheduled', Building_ID__c = buildings[0].Id, SchedStartTime = System.now().addDays(2), ParentRecordId = newAccount[0].Id);
        insert serviceAppointment;
        ServiceResource serviceResource = new ServiceResource(RelatedRecordId = UserInfo.getUserId(), Name = 'test', ResourceType = 'T', IsActive = true);
        insert serviceResource;
        insert new AssignedResource(ServiceResourceId = serviceResource.Id, ServiceAppointmentId = serviceAppointment.Id);
    }

    @isTest
    public static void testReassignServiceResource() {
        User newUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = TRUE LIMIT 1];
        Building__c building = [SELECT Id FROM Building__c LIMIT 1];
        ServiceAppointment serviceAppointmentrecord = [SELECT Id, OwnerId FROM ServiceAppointment LIMIT 1];
        Test.startTest();
        String response;
        response = ReassignTourController.reassignServiceResource(building.Id, serviceAppointmentrecord.Id, newUser.Id);
        Test.stopTest();
        serviceAppointmentrecord = [SELECT Id, OwnerId FROM ServiceAppointment limit 1];
        System.assertEquals(serviceAppointmentrecord.OwnerId, newUser.Id, 'Service Appointment is not reassigned');
        System.assertEquals('success', response, 'Returned message is incorrect');
    }

    @isTest
    public static void testReassignServiceResourceError() {
        User newUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = TRUE limit 1];
        Building__c building = [SELECT Id FROM Building__c limit 1];
        ServiceAppointment serviceAppointmentrecord = [SELECT Id, OwnerId FROM ServiceAppointment limit 1];
        Test.startTest();
        try {
            ReassignTourController.reassignServiceResource(building.Id, newUser.Id, serviceAppointmentrecord.Id);
            System.assert(false, 'Error case not handled properly');
        } catch (Exception e) {}
        Test.stopTest();
        serviceAppointmentrecord = [SELECT Id, OwnerId FROM ServiceAppointment limit 1];
        System.assertNotEquals(serviceAppointmentrecord.OwnerId, newUser.Id, 'Error case not handled properly');
    }
}