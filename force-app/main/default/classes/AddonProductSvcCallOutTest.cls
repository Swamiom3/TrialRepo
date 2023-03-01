/************************************************************************************************************************************
Author      :   Salesforce
Description :   This class have testmethods to cover AddonProductSvcCallOut class
----------------------------------------------------------------------------------------------------------------------------------
VERSION     DATE                AUTHOR                  DETAIL
1           09 AUG 2021         Salesforce            Initial Developement
**************************************************************************************************************************************/
@isTest
public class AddonProductSvcCallOutTest {
    @testSetup
    static void setup() {
        Building__c building = new Building__c();
        building.Name = 'testbuild-001';
        building.Building_ID__c = '74812090-7dbd-46a4-8a22-d0653e254d2d';
        building.UUID__c = 'test234';
        building.Time_Zone__c ='America/Denver';
        insert building;
    }
    @isTest
    static void addOnProductServiceTestPositive(){
        Test.startTest();
        Building__c building = [SELECT Id, Building_ID__c, UUID__c FROM Building__c LIMIT 1];
        Test.setMock(HttpCalloutMock.class, new RestAPIMock(building.UUID__c,'200'));
        Map<String,ProductServiceOutput> addOns = AddonProductSvcCallOut.getBuildingAddons(building.UUID__c);
        System.assert(!addOns.isEmpty(), 'response not recieved from AddonProductService');
        Test.stopTest();
    }
    @isTest
    static void addOnProductServiceTestNegative(){
        Test.startTest();
        Building__c building = [SELECT Id, Building_ID__c, UUID__c FROM Building__c LIMIT 1];
        Test.setMock(HttpCalloutMock.class, new RestAPIMock(building.UUID__c,'201'));
        Map<String,ProductServiceOutput> addOns = AddonProductSvcCallOut.getBuildingAddons(building.UUID__c);
        System.assert(addOns.isEmpty(), 'response recieved from AddonProductService');
        Test.stopTest();
    }
}