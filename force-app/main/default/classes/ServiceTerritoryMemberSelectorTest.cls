/*************************************************************************************************************************************
Author      :   Salesforce
Description :   This class provides sufficient test coverage for ServiceTerritoryMemberSelector class
--------------------------------------------------------------------------------------------------------------------------------------
VERSION         DATE            AUTHOR              DETAIL
1               10/29/2021       Salesforce         Initial Deployment
**************************************************************************************************************************************/
@isTest
public class ServiceTerritoryMemberSelectorTest {
    private static ServiceTerritoryMemberSelector serviceTerritoryMemberSelector = new ServiceTerritoryMemberSelector();

    @testsetup
    static void setup() {
        List<Building__c> buildings = (List<Building__c>)TestingUtility.getRecords(new Map<String, Object>{'objName' => 'Building__c', 'numberOfRecords' => 1});
        List<User> users = (List<User>)TestingUtility.getRecords(new Map<String, Object>{'objName' => 'User', 'doInsert' => true, 'numberOfRecords' => 1});
        OperatingHours operatingHour = new OperatingHours(Name = 'EDT: Standard 9AM - 5PM Weekday');
        insert operatingHour;
        insert new TimeSlot (OperatingHoursId = operatingHour.Id, DayOfWeek = 'Monday', StartTime = Time.newInstance(9, 0, 0, 0), EndTime = Time.newInstance(17, 0, 0, 0));
        ServiceTerritory territory = new ServiceTerritory (Building_Id__c = buildings[0].Id, Name = buildings[0].Name, OperatingHoursId = operatingHour.Id, isActive = true);
        insert territory;
        ServiceResource resource = new ServiceResource(RelatedRecordId = users[0].Id, Name = users[0].LastName, ResourceType = 'T', isActive = true);
        insert resource;
        insert new ServiceTerritoryMember(ServiceTerritoryId = territory.Id, ServiceResourceId = resource.Id, Role = 'Reassigned Host', EffectiveStartDate = System.now(), EffectiveEndDate =  null, OperatingHoursId = operatingHour.Id, TerritoryType = 'P');
    }

    @isTest
    static void getServiceTerritoryMembersTest() {
        Building__c building = [SELECT Id FROM Building__c LIMIT 1];
        List<Id> userIds = new List<Id>();
        for (User u : [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = TRUE]) {
            userIds.add(u.Id);
        }
        Test.startTest();
        List<ServiceTerritoryMember> serviceTerritoryMembers = serviceTerritoryMemberSelector.getServiceTerritoryMembers(new List<Id> { building.Id }, userIds);
        List<ServiceTerritoryMember> serviceTerritoryMembersNegative = serviceTerritoryMemberSelector.getServiceTerritoryMembers(userIds, new List<Id> { building.Id });
        List<ServiceTerritoryMember> serviceTerritoryMembersEmpty1 = serviceTerritoryMemberSelector.getServiceTerritoryMembers(new List<Id>(), userIds);
        List<ServiceTerritoryMember> serviceTerritoryMembersEmpty2 = serviceTerritoryMemberSelector.getServiceTerritoryMembers(new List<Id> { building.Id }, new List<Id>());
        Test.stopTest();
        System.assert(!serviceTerritoryMembers.isEmpty(), 'Service Territory Members not retrived successfully');
        System.assert(serviceTerritoryMembersNegative.isEmpty(), 'Service Territory Members retrived');
        System.assert(serviceTerritoryMembersEmpty1.isEmpty(), 'Service Territory Members retrived');
        System.assert(serviceTerritoryMembersEmpty2.isEmpty(), 'Service Territory Members retrived');
    }

    @isTest
    static void getServiceTerritoryMembersWithTimeSlotsByBuildingTest() {
        Building__c building = [SELECT Id FROM Building__c LIMIT 1];
        List<Id> userIds = new List<Id>();
        for (User u : [SELECT Id FROM User WHERE Profile.Name = 'Wework System Administrator' AND IsActive = TRUE]) {
            userIds.add(u.Id);
        }
        Test.startTest();
        List<ServiceTerritoryMember> serviceTerritoryMembers = serviceTerritoryMemberSelector.getServiceTerritoryMembersWithTimeSlotsByBuilding(new List<Id> { building.Id });
        List<ServiceTerritoryMember> serviceTerritoryMembersNegative = serviceTerritoryMemberSelector.getServiceTerritoryMembersWithTimeSlotsByBuilding(userIds);
        List<ServiceTerritoryMember> serviceTerritoryMembersEmpty = serviceTerritoryMemberSelector.getServiceTerritoryMembersWithTimeSlotsByBuilding(new List<Id>());
        Test.stopTest();
        System.assert(!serviceTerritoryMembers.isEmpty(), 'Service Territory Members not retrived successfully');
        System.assert(serviceTerritoryMembersNegative.isEmpty(), 'Service Territory Members retrived');
        System.assert(serviceTerritoryMembersEmpty.isEmpty(), 'Service Territory Members retrived');
    }

    @isTest
    static void getActiveBuildingHostsByHostIdsTest() {
        Building__c building = [SELECT Id FROM Building__c LIMIT 1];
        List<Id> resourceIds = new List<Id>();
        for (ServiceResource sr : [SELECT Id FROM ServiceResource WHERE IsActive = TRUE]) {
            resourceIds.add(sr.Id);
        }
        Test.startTest();
        List<ServiceTerritoryMember> serviceTerritoryMembers = serviceTerritoryMemberSelector.getActiveBuildingHostsByHostIds(resourceIds);
        List<ServiceTerritoryMember> serviceTerritoryMembersNegative = serviceTerritoryMemberSelector.getActiveBuildingHostsByHostIds(new List<Id> { building.Id });
        List<ServiceTerritoryMember> serviceTerritoryMembersEmpty = serviceTerritoryMemberSelector.getActiveBuildingHostsByHostIds(new List<Id>());
        Test.stopTest();
        System.assert(!serviceTerritoryMembers.isEmpty(), 'Service Territory Members not retrived successfully');
        System.assert(serviceTerritoryMembersNegative.isEmpty(), 'Service Territory Members retrived');
        System.assert(serviceTerritoryMembersEmpty.isEmpty(), 'Service Territory Members retrived');
    }

    @isTest
    static void getServiceTerritoryMembersForHostsTest() {
        Building__c building = [SELECT Id FROM Building__c LIMIT 1];
        List<Id> resourceIds = new List<Id>();
        for (ServiceResource sr : [SELECT Id FROM ServiceResource WHERE IsActive = TRUE]) {
            resourceIds.add(sr.Id);
        }
        Test.startTest();
        List<ServiceTerritoryMember> serviceTerritoryMembers = serviceTerritoryMemberSelector.getServiceTerritoryMembersForHosts(new List<Id> { building.Id }, resourceIds);
        List<ServiceTerritoryMember> serviceTerritoryMembersNegative = serviceTerritoryMemberSelector.getServiceTerritoryMembersForHosts(resourceIds, new List<Id> { building.Id });
        List<ServiceTerritoryMember> serviceTerritoryMembersEmpty = serviceTerritoryMemberSelector.getServiceTerritoryMembersForHosts(new List<Id>(), new List<Id>());
        Test.stopTest();
        System.assert(!serviceTerritoryMembers.isEmpty(), 'Service Territory Members not retrived successfully');
        System.assert(serviceTerritoryMembersNegative.isEmpty(), 'Service Territory Members retrived');
        System.assert(serviceTerritoryMembersEmpty.isEmpty(), 'Service Territory Members retrived');
    }
}