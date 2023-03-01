/*************************************************************************************************************************************
Author      :   Salesforce
Description :   This class provides sufficient test coverage for NonOperatingHoursManageAbsencesTrH class
--------------------------------------------------------------------------------------------------------------------------------------
VERSION         DATE            AUTHOR              DETAIL
1               10/29/2021       Salesforce         Initial Deployment
**************************************************************************************************************************************/
@isTest
public class NonOperatingHoursManageAbsencesTrHTest {
    @testSetup
    static void initData() {
        List<Building__c> lstBuildings = (List<Building__c>)TestingUtility.getRecords(new Map<String, Object>{'objName' => 'Building__c', 'numberOfRecords' => 1});
        List<User> lstUsers = (List<User>)TestingUtility.getRecords(new Map<String, Object>{'objName' => 'User', 'doInsert' => true, 'numberOfRecords' => 1});
        OperatingHours operatingHour = new OperatingHours(Name = 'EDT: Standard 9AM - 5PM Weekday');
        insert operatingHour;
        insert new TimeSlot (OperatingHoursId = operatingHour.Id, DayOfWeek = 'Monday', StartTime = Time.newInstance(9, 0, 0, 0), EndTime = Time.newInstance(17, 0, 0, 0));
        ServiceTerritory serviceTerritory = new ServiceTerritory (Building_Id__c = lstBuildings[0].Id, Name = lstBuildings[0].Name, OperatingHoursId = operatingHour.Id, isActive = true);
        insert serviceTerritory;
        ServiceResource resource = new ServiceResource(RelatedRecordId = lstUsers[0].Id, Name = lstUsers[0].LastName, ResourceType = 'T', isActive = true);
        insert resource;
        insert new ServiceTerritoryMember(ServiceTerritoryId = serviceTerritory.Id, ServiceResourceId = resource.Id, Role = 'Reassigned Host', EffectiveStartDate = System.now(), EffectiveEndDate =  null, OperatingHoursId = operatingHour.Id, TerritoryType = 'P');
    }

    @isTest
    static void insertNonOperatingHourTest() {
        Building__c building = [SELECT Id FROM Building__c LIMIT 1];
        List<ResourceAbsence> resourceAbsenceRecords = [SELECT Id FROM ResourceAbsence];
        System.assert(resourceAbsenceRecords.isEmpty(), 'Resource Absence exist already');
        Test.startTest();
        Non_Operating_Hours__c noh = new Non_Operating_Hours__c(End_Time__c = System.now().addDays(2), Start_Time__c = System.now().addDays(1), Closure_Type__c = 'Holiday', Building_Id__c = building.Id);
        insert noh;
        Test.stopTest();
        resourceAbsenceRecords = [SELECT Id, Non_Operating_Hours_Id__c, ResourceId, Type FROM ResourceAbsence];
        ServiceResource resource = [SELECT Id FROM ServiceResource LIMIT 1];
        Non_Operating_Hours__c nonOperatingHour = [SELECT Id FROM Non_Operating_Hours__c LIMIT 1];
        System.assert(!resourceAbsenceRecords.isEmpty(), 'Resource Absence not Created');
        System.assertEquals(nonOperatingHour.Id, resourceAbsenceRecords[0].Non_Operating_Hours_Id__c, 'Non_Operating_Hours_Id__c not populated properly');
        System.assertEquals(resource.Id, resourceAbsenceRecords[0].ResourceId, 'ResourceId not populated properly');
        System.assertEquals('Building Holiday', resourceAbsenceRecords[0].Type, 'Type not populated properly');
    }

    @isTest
    static void deleteNonOperatingHourTest() {
        Building__c building = [SELECT Id FROM Building__c LIMIT 1];
        Non_Operating_Hours__c nonOperatingHour = new Non_Operating_Hours__c(End_Time__c = System.now().addDays(2), Start_Time__c = System.now().addDays(1), Closure_Type__c = 'Holiday', Building_Id__c = building.Id);
        insert nonOperatingHour;
        List<ResourceAbsence> resourceAbsenceRecords = [SELECT Id FROM ResourceAbsence];
        System.assert(!resourceAbsenceRecords.isEmpty(), 'Resource Absence not exist aready');
        Test.startTest();
        delete nonOperatingHour;
        Test.stopTest();
        resourceAbsenceRecords = [SELECT Id FROM ResourceAbsence];
        System.assert(resourceAbsenceRecords.isEmpty(), 'Resource Absence not deleted');
    }
}