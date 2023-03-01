/*************************************************************************************************************************************
Author      :   Salesforce
Description :   This class provides sufficient test coverage for NonOperatingHoursSelector class
--------------------------------------------------------------------------------------------------------------------------------------
VERSION         DATE            AUTHOR              DETAIL
1               10/29/2021       Salesforce         Initial Deployment
**************************************************************************************************************************************/
@isTest
public class NonOperatingHoursSelectorTest {
    private static NonOperatingHoursSelector nonOperatingHoursSelector = new NonOperatingHoursSelector();

    @testsetup
    static void setup() {
        List<Building__c> buildings = (List<Building__c>)TestingUtility.getRecords(new Map<String, Object>{'objName' => 'Building__c', 'numberOfRecords' => 1});
        OperatingHours operatingHour = new OperatingHours(Name = 'EDT: Standard 9AM - 5PM Weekday');
        insert operatingHour;
        insert new ServiceTerritory (Building_Id__c = buildings[0].Id, Name = buildings[0].Name, OperatingHoursId = operatingHour.Id);
        insert new Non_Operating_Hours__c(End_Time__c = System.now().addDays(2), Start_Time__c = System.now().addDays(1), Closure_Type__c = 'Holiday', Building_Id__c = buildings[0].Id);
    }

    @isTest
    static void getNonOperatingHoursByBuildingIdsTest() {
        Building__c building = [SELECT Id FROM Building__c LIMIT 1];
        ServiceTerritory territory = [SELECT Id FROM ServiceTerritory LIMIT 1];
        Test.startTest();
        List<Non_Operating_Hours__c> nonOperatingHours = nonOperatingHoursSelector.getNonOperatingHoursByBuildingIds(new List<Id> { building.Id }, 'Holiday');
        List<Non_Operating_Hours__c> nonOperatingHoursNegative = nonOperatingHoursSelector.getNonOperatingHoursByBuildingIds(new List<Id> { territory.Id }, 'Holiday');
        List<Non_Operating_Hours__c> nonOperatingHoursEmpty1 = nonOperatingHoursSelector.getNonOperatingHoursByBuildingIds(new List<Id>(), 'Holiday');
        List<Non_Operating_Hours__c> nonOperatingHoursEmpty2 = nonOperatingHoursSelector.getNonOperatingHoursByBuildingIds(new List<Id> { building.Id }, '');
        Test.stopTest();
        System.assert(!nonOperatingHours.isEmpty(), 'Non-Operating Hours not retrieved successfully');
        System.assert(nonOperatingHoursNegative.isEmpty(), 'Non-Operating Hours retrieved');
        System.assert(nonOperatingHoursEmpty1.isEmpty(), 'Non-Operating Hours retrieved');
        System.assert(nonOperatingHoursEmpty2.isEmpty(), 'Non-Operating Hours retrieved');
    }

    @isTest
    static void getNonOperatingHoursByServiceTerritoryIdsTest() {
        Building__c building = [SELECT Id FROM Building__c LIMIT 1];
        ServiceTerritory territory = [SELECT Id FROM ServiceTerritory LIMIT 1];
        Test.startTest();
        List<Non_Operating_Hours__c> nonOperatingHours = nonOperatingHoursSelector.getNonOperatingHoursByServiceTerritoryIds(new List<Id> { territory.Id });
        List<Non_Operating_Hours__c> nonOperatingHoursNegative = nonOperatingHoursSelector.getNonOperatingHoursByServiceTerritoryIds(new List<Id> { building.Id });
        List<Non_Operating_Hours__c> nonOperatingHoursEmpty = nonOperatingHoursSelector.getNonOperatingHoursByServiceTerritoryIds(new List<Id>());
        Test.stopTest();
        System.assert(!nonOperatingHours.isEmpty(), 'Non-Operating Hours not retrieved successfully');
        System.assert(nonOperatingHoursNegative.isEmpty(), 'Non-Operating Hours retrieved');
        System.assert(nonOperatingHoursEmpty.isEmpty(), 'Non-Operating Hours retrieved');
    }

    @isTest
    static void getNonOperatingHoursByBuildingIdsAndPeriodTest() {
        Building__c building = [SELECT Id FROM Building__c LIMIT 1];
        ServiceTerritory territory = [SELECT Id FROM ServiceTerritory LIMIT 1];
        DateTime startTime = System.now().addDays(1).addHours(2);
        DateTime endTime = System.now().addDays(1).addHours(4);
        Test.startTest();
        List<Non_Operating_Hours__c> nonOperatingHours = nonOperatingHoursSelector.getNonOperatingHoursByBuildingIdsAndPeriod(new List<Id> { building.Id }, 'Holiday', startTime, endTime);
        List<Non_Operating_Hours__c> nonOperatingHoursNegative = nonOperatingHoursSelector.getNonOperatingHoursByBuildingIdsAndPeriod(new List<Id> { territory.Id }, 'Holiday', startTime, endTime);
        List<Non_Operating_Hours__c> nonOperatingHoursEmpty1 = nonOperatingHoursSelector.getNonOperatingHoursByBuildingIdsAndPeriod(new List<Id>(), 'Holiday', startTime, endTime);
        List<Non_Operating_Hours__c> nonOperatingHoursEmpty2 = nonOperatingHoursSelector.getNonOperatingHoursByBuildingIdsAndPeriod(new List<Id> { building.Id }, '', startTime, endTime);
        Test.stopTest();
        System.assert(!nonOperatingHours.isEmpty(), 'Non-Operating Hours not retrieved successfully');
        System.assert(nonOperatingHoursNegative.isEmpty(), 'Non-Operating Hours retrieved');
        System.assert(nonOperatingHoursEmpty1.isEmpty(), 'Non-Operating Hours retrieved');
        System.assert(nonOperatingHoursEmpty2.isEmpty(), 'Non-Operating Hours retrieved');
    }
}