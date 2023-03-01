/*************************************************************************************************************************************
Author      :   Salesforce
Description :   This class provides sufficient test coverage for BuildingHostManageAbsencesTrH class
--------------------------------------------------------------------------------------------------------------------------------------
VERSION         DATE            AUTHOR              DETAIL
1               10/29/2021       Salesforce         Initial Deployment
**************************************************************************************************************************************/
@isTest
public class BuildingHostManageAbsencesTrHTest {
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
        Non_Operating_Hours__c nonOperatingHour = new Non_Operating_Hours__c(End_Time__c = System.now().addDays(2), Start_Time__c = System.now().addDays(1), Closure_Type__c = 'Holiday', Building_Id__c = buildings[0].Id);
        insert nonOperatingHour;
    }

    @isTest
    static void insertServiceTerrirtoryMemberWithTimeSlotTest() {
        OperatingHours operatingHour = [SELECT Id FROM OperatingHours LIMIT 1];
        ServiceResource resource = [SELECT Id FROM ServiceResource LIMIT 1];
        ServiceTerritory serviceTerritory = [SELECT Id FROM ServiceTerritory LIMIT 1];
        List<ResourceAbsence> resourceAbsenceRecords = [SELECT Id FROM ResourceAbsence];
        Non_Operating_Hours__c nonOperatingHour = [SELECT Id FROM Non_Operating_Hours__c LIMIT 1];
        System.assert(resourceAbsenceRecords.isEmpty(), 'Resource Absence exist already');
        Test.startTest();
        insert new ServiceTerritoryMember(ServiceTerritoryId = serviceTerritory.Id, ServiceResourceId = resource.Id, Role = 'Reassigned Host', EffectiveStartDate = System.now(), EffectiveEndDate =  null, OperatingHoursId = operatingHour.Id, TerritoryType = 'P');
        Test.stopTest();
        resourceAbsenceRecords = [SELECT Id, Non_Operating_Hours_Id__c, ResourceId, Type FROM ResourceAbsence];
        System.assert(!resourceAbsenceRecords.isEmpty(), 'Resource Absence not Created');
        System.assertEquals(nonOperatingHour.Id, resourceAbsenceRecords[0].Non_Operating_Hours_Id__c, 'Non_Operating_Hours_Id__c not populated properly');
        System.assertEquals(resource.Id, resourceAbsenceRecords[0].ResourceId, 'ResourceId not populated properly');
        System.assertEquals('Building Holiday', resourceAbsenceRecords[0].Type, 'Type not populated properly');
    }

    @isTest
    static void insertServiceTerrirtoryMemberWithoutTimeSlotTest() {
        OperatingHours operatingHour = new OperatingHours(Name = 'EDT: Standard 9AM - 5PM Weekday - 1');
        insert operatingHour;
        ServiceResource resource = [SELECT Id FROM ServiceResource LIMIT 1];
        ServiceTerritory serviceTerritory = [SELECT Id FROM ServiceTerritory LIMIT 1];
        serviceTerritory.OperatingHoursId = operatingHour.Id;
        update serviceTerritory;
        List<ResourceAbsence> resourceAbsenceRecords = [SELECT Id FROM ResourceAbsence];
        System.assert(resourceAbsenceRecords.isEmpty(), 'Resource Absence exist already');
        Test.startTest();
        insert new ServiceTerritoryMember(ServiceTerritoryId = serviceTerritory.Id, ServiceResourceId = resource.Id, Role = 'Reassigned Host', EffectiveStartDate = System.now(), EffectiveEndDate =  null, OperatingHoursId = operatingHour.Id, TerritoryType = 'P');
        Test.stopTest();
        resourceAbsenceRecords = [SELECT Id, Non_Operating_Hours_Id__c, ResourceId, Type FROM ResourceAbsence];
        System.assert(resourceAbsenceRecords.isEmpty(), 'Resource Absence record created');
    }

    @isTest
    static void updateServiceTerrirtoryMemberWithTest() {
        OperatingHours operatingHour = [SELECT Id FROM OperatingHours LIMIT 1];
        ServiceResource resource = [SELECT Id FROM ServiceResource LIMIT 1];
        ServiceTerritory serviceTerritory = [SELECT Id FROM ServiceTerritory LIMIT 1];
        ServiceTerritoryMember territoryMember = new ServiceTerritoryMember(ServiceTerritoryId = serviceTerritory.Id, ServiceResourceId = resource.Id, Role = 'Reassigned Host', EffectiveStartDate = System.now(), EffectiveEndDate =  null, OperatingHoursId = operatingHour.Id, TerritoryType = 'P');
        insert territoryMember;
        List<ResourceAbsence> resourceAbsenceRecords = [SELECT Id FROM ResourceAbsence];
        System.assert(!resourceAbsenceRecords.isEmpty(), 'Resource Absence not exist aready');
        Test.startTest();
        territoryMember.EffectiveEndDate = System.now().addDays(1);
        update territoryMember;
        Test.stopTest();
        resourceAbsenceRecords = [SELECT Id FROM ResourceAbsence];
        System.assert(resourceAbsenceRecords.isEmpty(), 'Resource Absence not deleted');
    }
}