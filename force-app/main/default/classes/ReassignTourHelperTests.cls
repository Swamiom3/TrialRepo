/*************************************************************************************************************************************
 Author      :   Salesforce
 Description :   This is a test class for ReassignTourHelper

 --------------------------------------------------------------------------------------------------------------------------------------
 VERSION         DATE            AUTHOR              DETAIL
 1               14 Oct 2021     Salesforce       Initial Deployment
 **************************************************************************************************************************************/
@isTest
public with sharing class ReassignTourHelperTests {
    @testSetup
    public static void testSetup() {
        List<Account> newAccount = (List<Account>)TestingUtility.getRecords(new Map<String, Object>{'objName' => 'Account', 'doInsert' => true, 'numberOfRecords' => 1});
        List<User> lstUsers = (List<User>)TestingUtility.getRecords(new Map<String, Object>{'objName' => 'User', 'doInsert' => true, 'numberOfRecords' => 1});
        List<Building__c> lstBuildings = (List<Building__c>)TestingUtility.getRecords(new Map<String, Object>{'objName' => 'Building__c', 'numberOfRecords' => 1});
        insert new ServiceAppointment(Status='Scheduled', Building_ID__c = lstBuildings[0].Id, SchedStartTime = System.now().addDays(2), ParentRecordId = newAccount[0].Id);
        insert new ServiceResource(RelatedRecordId = lstUsers[0].Id, Name = lstUsers[0].LastName, ResourceType = 'T', isActive = false);
    }

    @isTest
    public static void testCreateOrUpdateServiceResources() {
        List<Id> userIds = new List<Id>();
        for (User u : [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = TRUE]) {
            userIds.add(u.Id);
        }
        Test.startTest();
        List<ServiceResource> serviceResources = ReassignTourHelper.createOrUpdateServiceResources(userIds);
        Test.stopTest();
        System.assert(!serviceResources.isEmpty(), 'Service Resource not updated');
    }

    @isTest
    public static void testGetUserWithServiceResource() {
        List<Id> userIds = new List<Id>();
        for (User u : [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = TRUE]) {
            userIds.add(u.Id);
        }
        Test.startTest();
        Map<Id, ServiceResource> serviceResources = ReassignTourHelper.getUserWithServiceResource(userIds);
        Test.stopTest();
        System.assert(serviceResources.size() == 1, 'Service Resource not retreived');
    }

    @isTest
    public static void testAddSalesforceSchedulerLicense() {
        Set<Id> userIds = new Set<Id>();
        for (User u : [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = TRUE]) {
            userIds.add(u.Id);
        }
        Test.startTest();
        ReassignTourHelper.addSalesforceSchedulerLicense(userIds);
        Test.stopTest();
        Id permissionSetId = [SELECT Id
                              FROM PermissionSet
                              WHERE Name = 'Salesforce_Scheduler_Resource'
                              LIMIT 1]?.Id;
        List<PermissionSetAssignment> permissionSetAssignment = [SELECT Id, PermissionSetId, AssigneeId FROM PermissionSetAssignment WHERE AssigneeId IN: userIds AND PermissionSetId =:permissionSetId];
        System.assert(!permissionSetAssignment.isEmpty(), 'Permission set not assigned');
    }

    @isTest
    public static void testCreateServiceTerritoryMembership() {
        Building__c building = [SELECT Id FROM Building__c limit 1];
        ServiceResource resource = [SELECT Id, Name FROM ServiceResource limit 1];
        resource.isActive = true;
        update resource;
        Test.startTest();
        ReassignTourHelper.createServiceTerritoryMembership(resource, building.Id);
        Test.stopTest();
        List<ServiceTerritoryMember> serviceTerritoryMembers = [SELECT Id FROM ServiceTerritoryMember];
        System.assert(serviceTerritoryMembers.size() == 1, 'Service Territory Member not created');
    }
}