/*************************************************************************************************************************************
Author      :   Salesforce
Description :   This class provides sufficient test coverage for BuildingHostManageTimeSlotsTrH class
--------------------------------------------------------------------------------------------------------------------------------------
VERSION         DATE            AUTHOR              DETAIL
1               11/22/2021       Salesforce         Initial Deployment
**************************************************************************************************************************************/
@isTest
public class BuildingHostManageTimeSlotsTrHTest {
    @testSetup
    static void initData() {
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
    static void deactivateBuildingHostWithTimeSlot() {
        List<TimeSlot> timeslotsInitial = [SELECT Id FROM TimeSlot];
        ServiceTerritoryMember buildingHost = [SELECT Id, EffectiveEndDate, Has_Timeslots__c FROM ServiceTerritoryMember LIMIT 1];
        System.assert(buildingHost.Has_Timeslots__c, 'Timeslots doesnot exist for buildingHost');
        Test.startTest();
        buildingHost.EffectiveEndDate = System.now().addDays(1);
        update buildingHost;
        Test.stopTest();
        List<TimeSlot> timeslotsFinal = [SELECT Id FROM TimeSlot];
        System.assert(timeslotsFinal.size() == timeslotsInitial.size() - 1, 'Timeslots are not deleted');
    }
}