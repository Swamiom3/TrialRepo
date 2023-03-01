/*************************************************************************************************************************************
Author      :   Salesforce
Description :   This class provides sufficient test coverage for ResourceAbsenceSelector class
--------------------------------------------------------------------------------------------------------------------------------------
VERSION         DATE            AUTHOR              DETAIL
1               10/29/2021       Salesforce         Initial Deployment
**************************************************************************************************************************************/
@isTest
public class ResourceAbsenceSelectorTest {
    private static ResourceAbsenceSelector resourceAbsenceSelector = new ResourceAbsenceSelector();

    @testsetup
    static void setup() {
        List<User> users = (List<User>)TestingUtility.getRecords(new Map<String, Object>{'objName' => 'User', 'doInsert' => true, 'numberOfRecords' => 1});
        List<Building__c> buildings = (List<Building__c>)TestingUtility.getRecords(new Map<String, Object>{'objName' => 'Building__c', 'numberOfRecords' => 1});
        ServiceResource resource = new ServiceResource(RelatedRecordId = users[0].Id, Name = users[0].LastName, ResourceType = 'T', isActive = true);
        insert resource;
        Non_Operating_Hours__c nonOperatingHour = new Non_Operating_Hours__c(End_Time__c = System.now().addDays(2), Start_Time__c = System.now().addDays(1), Closure_Type__c = 'Holiday', Building_Id__c = buildings[0].Id);
        insert nonOperatingHour;
        insert new ResourceAbsence(End = System.now().addDays(2), Non_Operating_Hours_Id__c = nonOperatingHour.Id, ResourceId = resource.Id, Start = System.now().addDays(1), Type = 'Building Holiday');
    }

    @isTest
    static void getResourceAbsenceByNonOperatingHoursIdsTest() {
        Non_Operating_Hours__c nonOperatingHour = [SELECT Id FROM Non_Operating_Hours__c LIMIT 1];
        ServiceResource resource = [SELECT Id FROM ServiceResource LIMIT 1];
        Test.startTest();
        List<ResourceAbsence> resourceAbsences = resourceAbsenceSelector.getResourceAbsenceByNonOperatingHoursIds(new List<Id> { nonOperatingHour.Id });
        List<ResourceAbsence> resourceAbsencesNegative = resourceAbsenceSelector.getResourceAbsenceByNonOperatingHoursIds(new List<Id> { resource.Id });
        List<ResourceAbsence> resourceAbsencesEmpty = resourceAbsenceSelector.getResourceAbsenceByNonOperatingHoursIds(new List<Id>());
        Test.stopTest();
        System.assert(!resourceAbsences.isEmpty(), 'Resource Absence not retrived successfully');
        System.assert(resourceAbsencesNegative.isEmpty(), 'Resource Absence retrived');
        System.assert(resourceAbsencesEmpty.isEmpty(), 'Resource Absence retrived');
    }

    @isTest
    static void getResourceAbsenceByNonOperatingHoursAndServiceResourceIdsTest() {
        Non_Operating_Hours__c nonOperatingHour = [SELECT Id FROM Non_Operating_Hours__c LIMIT 1];
        ServiceResource resource = [SELECT Id FROM ServiceResource LIMIT 1];
        Test.startTest();
        List<ResourceAbsence> resourceAbsences = resourceAbsenceSelector.getResourceAbsenceByNonOperatingHoursAndServiceResourceIds(new List<Id> { nonOperatingHour.Id }, new List<Id> { resource.Id });
        List<ResourceAbsence> resourceAbsencesNegative = resourceAbsenceSelector.getResourceAbsenceByNonOperatingHoursAndServiceResourceIds(new List<Id> { resource.Id }, new List<Id> { nonOperatingHour.Id });
        List<ResourceAbsence> resourceAbsencesEmpty1 = resourceAbsenceSelector.getResourceAbsenceByNonOperatingHoursAndServiceResourceIds(new List<Id> { nonOperatingHour.Id }, new List<Id>());
        List<ResourceAbsence> resourceAbsencesEmpty2 = resourceAbsenceSelector.getResourceAbsenceByNonOperatingHoursAndServiceResourceIds(new List<Id>(), new List<Id> { resource.Id });
        Test.stopTest();
        System.assert(!resourceAbsences.isEmpty(), 'Resource Absence not retrived successfully');
        System.assert(resourceAbsencesNegative.isEmpty(), 'Resource Absence retrived');
        System.assert(resourceAbsencesEmpty1.isEmpty(), 'Resource Absence retrived');
        System.assert(resourceAbsencesEmpty2.isEmpty(), 'Resource Absence retrived');
    }
}