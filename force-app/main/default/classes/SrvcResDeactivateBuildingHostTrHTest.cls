/************************************************************************************************************************************
Author      :   Salesforce
Description :   This class is create/modify the Service Resources based on Building Players.
----------------------------------------------------------------------------------------------------------------------------------
VERSION     DATE                AUTHOR                DETAIL
1           14 September 2021   Salesforce            Initial Developement
**************************************************************************************************************************************/
@isTest
public class SrvcResDeactivateBuildingHostTrHTest {
    @testSetup
    static void initData() {
        List<Building__c> buildings = (List<Building__c>)TestingUtility.getRecords(new Map<String, Object>{'objName' => 'Building__c', 'numberOfRecords' => 1});
        List<User> users = (List<User>)TestingUtility.getRecords(new Map<String, Object>{'objName' => 'User', 'doInsert' => true, 'numberOfRecords' => 1});
        OperatingHours operatingHour = new OperatingHours(Name = 'EDT: Standard 9AM - 5PM Weekday');
        insert operatingHour;
        ServiceTerritory territory = new ServiceTerritory (Building_Id__c = buildings[0].Id, Name = buildings[0].Name, OperatingHoursId = operatingHour.Id, isActive = true);
        insert territory;
        ServiceResource resource = new ServiceResource(RelatedRecordId = users[0].Id, Name = users[0].LastName, ResourceType = 'T', isActive = true);
        insert resource;
        insert new ServiceTerritoryMember(ServiceTerritoryId = territory.Id, ServiceResourceId = resource.Id, Role = 'Reassigned Host', EffectiveStartDate = System.now(), EffectiveEndDate =  null, OperatingHoursId = operatingHour.Id, TerritoryType = 'P');
    }

    @isTest
    static void deactivateServiceResourceTest() {

        ServiceTerritoryMember buildingHost = [SELECT Id, Is_Active__c FROM ServiceTerritoryMember LIMIT 1];
        System.assert(buildingHost.Is_Active__c == true, 'Building host is not active');
        Test.startTest();
        ServiceResource resource = [SELECT Id, IsActive FROM ServiceResource LIMIT 1];
        resource.IsActive = false;
        update resource;
        Test.stopTest();
        buildingHost = [SELECT Id, Is_Active__c FROM ServiceTerritoryMember LIMIT 1];
        System.assert(buildingHost.Is_Active__c == false, 'Building host is not deactivated');
    }
}