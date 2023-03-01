/************************************************************************************************************************************
Author      :   Salesforce
Description :   This class have testmethods to cover CPQ_AddonsPricing class
----------------------------------------------------------------------------------------------------------------------------------
VERSION     DATE                AUTHOR                  DETAIL
1           09 AUG 2021         Salesforce            Initial Developement
**************************************************************************************************************************************/
@isTest
public class CPQ_AddonsPricingTest {
    @testSetup 
    static void setup() {
        Product2 product = new Product2(Name = 'Commitment Test2', IsActive = true, ProductCode='COMMIT-TEST', Product_UUID__c='1234');
        insert product;
        
        Building__c building = new Building__c();
        building.Name = 'testbuild-001';
        building.Building_ID__c = '74812090-7dbd-46a4-8a22-d0653e254d2d';
        building.UUID__c = '74812090-7dbd-46a4-8a22-d0653e254d2d';
        building.Time_Zone__c ='America/Denver';
        insert building;
    }
    @isTest
    static void  addOnPricingTestPositive(){
        Test.startTest();
        Product2 product = [SELECT Id, Product_UUID__c FROM Product2 LIMIT 1];
        List<String> productUUIDs = new List<String>{product.Product_UUID__c};
        Building__c building = [SELECT Id, UUID__c FROM Building__c LIMIT 1];
        RestRequest request = new RestRequest(); 
        RestResponse response = new RestResponse();
        request.requestURI = '/services/apexrest/AddonsPricing';
        request.httpMethod = 'Post';
        request.addHeader('Content-Type', 'application/json');
        RestContext.request = request;
        RestContext.response = response;
        Test.setMock(HttpCalloutMock.class, new RestAPIMock(building.UUID__c,'200'));
        String addOnResponse = CPQ_AddonsPricing.getAddonsPricing(productUUIDs,building.Id);
        List<Object> result = (List<Object>)JSON.deserializeUntyped(addOnResponse);
        System.assert(!result.isEmpty(), 'response not recieved from response');
        Test.stopTest();
    }
    
     @isTest
    static void  addOnPricingTestNegative(){
        Test.startTest();
        Product2 product = [SELECT Id, Product_UUID__c FROM Product2 LIMIT 1];
        List<String> productUUIDs = new List<String>{product.Product_UUID__c};
        Building__c building = [SELECT Id, UUID__c FROM Building__c LIMIT 1];
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();
        request.requestURI = '/services/apexrest/AddonsPricing';
        request.httpMethod = 'Post';
        request.addHeader('Content-Type', 'application/json');
        RestContext.request = request;
        RestContext.response = response;
        Test.setMock(HttpCalloutMock.class, new RestAPIMock(building.UUID__c,'201'));
        String addOnResponse = CPQ_AddonsPricing.getAddonsPricing(productUUIDs,building.Id);
        System.assert(addOnResponse == null, 'response recieved from response');
        Test.stopTest();
    }
}