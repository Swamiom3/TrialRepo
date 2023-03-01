/************************************************************************************************************************************
Author      :   Salesforce
Description :   This class has testmethods to cover IXOPayCustomLinkAPI class
----------------------------------------------------------------------------------------------------------------------------------
VERSION     DATE                AUTHOR                  DETAIL
1           02/11/2022          Salesforce              Initial creation
**************************************************************************************************************************************/
@isTest
public with sharing class IXOPayCustomLinkAPITest {
    static String endPoint = 'http://example-api.com';

    @testSetup
    static void setup() {        
        Map<String, RecordTypeInfo> recordTypeInfoAccount = Schema.SObjectType.Account.getRecordTypeInfosByName();
        Id billingAccountRecTypeId = recordTypeInfoAccount.get('Billing Account').getRecordTypeId();
        Id businessAccountRecTypeId = recordTypeInfoAccount.get('Business Account').getRecordTypeId();

        Building__c building = new Building__c();
        building.Name = 'testbuild-001';
        building.Building_ID__c = '74812090-7dbd-46a4-8a22-d0653e254d2d';
        building.UUID__c = '74812090-7dbd-46a4-8a22-d0653e254d2d';
        building.Time_Zone__c ='America/Denver';
        building.CurrencyIsoCode = 'USD';
        building.Address__c = '100 Main St';
        building.City__c = 'Denver';
        building.State__c = 'Colorado';
        building.Postal_Code__c = '80014';
        insert building;
       
        List<Account> accountsInsert = new List<Account>();

        Account businessAccount =  new Account();
        businessAccount.Name = 'TestAccount';
        businessAccount.Site = 'TestAccount';
        businessAccount.Account_Type__c = 'Org';
        businessAccount.RecordTypeId = billingAccountRecTypeId;
        accountsInsert.add(businessAccount);

        Account billingAccount =  new Account();
        billingAccount.Name = 'TestBillAccount';
        billingAccount.Site = 'TestBillAccount';  
        billingAccount.RecordTypeId = businessAccountRecTypeId;   
        accountsInsert.add(billingAccount);

        insert accountsInsert;

        Contact objContact1 = new Contact(firstname = 'John',lastname = 'Rambo',email = 'john.con1@example.com', AccountId = billingAccount.Id, Status__c = 'active');
        TestingUtility.insertWithAssert(objContact1);

        billingAccount = [Select Id, Primary_Contact__c from Account where Id = :billingAccount.Id];
        billingAccount.Primary_Contact__c = objContact1.Id;
        billingAccount.Primary_Member__c = objContact1.Id;
        update billingAccount;

        businessAccount = [Select Id, Primary_Contact__c from Account where Id = :businessAccount.Id];
        businessAccount.Primary_Contact__c = objContact1.Id;
        businessAccount.Primary_Member__c = objContact1.Id;
        update businessAccount;

        Building_Account__c buildingAccount = new Building_Account__c();
        buildingAccount.Account_Id__c = businessAccount.Id;
        buildingAccount.Billing_Account_Id__c = billingAccount.Id;
        buildingAccount.Building_Id__c = building.Id;
        insert buildingAccount;

        Payment_Link_Manager__c paylinkManager = new Payment_Link_Manager__c();
        paylinkManager.Building_Account_id__c = buildingAccount.Id;
        insert paylinkManager;
    }
    @isTest
    static void doIXOPaymentAPICalloutPositive(){
        Payment_Link_Manager__c plm = [SELECT Id, Building_Account_id__c,Invoice_Due_Amount__c,Building_Currency__c,Account_UUID__c,Location_UUID__c FROM Payment_Link_Manager__c LIMIT 1];        
        String successResponse = '{"success": true,"uuid": "8259ac450aa4265330ae","purchaseId": "20220210-8259ac450aa4265330ae","returnType": "REDIRECT","redirectUrl": "https://sample.com","paymentMethod": "Creditcard","expiresAt": ""}';        

        MuleAPIUtilityTest.MockHttpResponseHandler mockResponseHandler = new MuleAPIUtilityTest.MockHttpResponseHandler();
        MuleAPIUtilityTest.MockResponse mockResponseSuccess = new MuleAPIUtilityTest.MockResponse('POST', successResponse, 200,'application/json');        
        IXOPayCustomLinkAPI ixoPayAPI = new IXOPayCustomLinkAPI();
        
        mockResponseHandler.addResponse(endPoint, mockResponseSuccess);        
                
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, mockResponseHandler);
        
        Map<String,String> mapJson =  new Map<String,String>{plm.Location_UUID__c => successResponse};
        Map<Id,Map<String,String>> mapJsonId = new Map<Id,Map<String,String>>{plm.Id => mapJson};
        ixoPayAPI.doIXOPaymentAPICallout(mapJsonId, '');

        IXOPayResponse payResponse = new IXOPayResponse();
        payResponse.success = true;
        payResponse.uuid = '8259ac450aa4265330ae';
        payResponse.purchaseId = '20220210-8259ac450aa4265330ae';
        payResponse.redirectUrl = 'https://sample.com';
        payResponse.paymentMethod = 'Creditcard';
        payResponse.returnType = 'REDIRECT';

        Test.stopTest();
        System.assertEquals('200', String.valueOf(mockResponseSuccess.response.getStatusCode()),'200 expected, received valid response code');        
        System.assertEquals(successResponse, mockResponseSuccess.response.getBody(),'Invalid response body, expected: {"success": true,"uuid": "8259ac450aa4265330ae","purchaseId": "20220210-8259ac450aa4265330ae","returnType": "REDIRECT","redirectUrl": "https://sample.com","paymentMethod": "Creditcard","expiresAt": ""}');
    }
    
    @isTest
    static void doIXOPaymentAPICalloutNegative(){
        Payment_Link_Manager__c plm = [SELECT Id, Building_Account_id__c,Invoice_Due_Amount__c,Building_Currency__c,Account_UUID__c,Location_UUID__c FROM Payment_Link_Manager__c LIMIT 1];                
        String failedResponse = '{"success": false,"returnType": "ERROR","errors": [{"errorMessage": "Rate limit reached, please try again later","errorCode": 1009}]}';

        MuleAPIUtilityTest.MockHttpResponseHandler mockResponseHandler = new MuleAPIUtilityTest.MockHttpResponseHandler();
        MuleAPIUtilityTest.MockResponse mockResponseFailed = new MuleAPIUtilityTest.MockResponse('POST', failedResponse, 200,'application/json');                
        IXOPayCustomLinkAPI ixoPayAPI = new IXOPayCustomLinkAPI();
        
        mockResponseHandler.addResponse(endPoint, mockResponseFailed);        
                
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, mockResponseHandler);
        
        Map<String,String> mapJson =  new Map<String,String>{plm.Location_UUID__c => failedResponse};
        Map<Id,Map<String,String>> mapJsonId = new Map<Id,Map<String,String>>{plm.Id => mapJson};
        ixoPayAPI.doIXOPaymentAPICallout(mapJsonId, '');       
         
        IXOPayResponse payResponse = new IXOPayResponse();
        payResponse.success = false;
      
        IXOPayResponse.errors payResponseError = new IXOPayResponse.errors();               
        List<IXOPayResponse.errors> payResponseErrors = new List<IXOPayResponse.errors>();               
        payResponseError.errorMessage = 'Rate limit reached, please try again later'; 
        payResponseError.errorCode = '1009';
        payResponseErrors.add(payResponseError);
        payResponse.errors = payResponseErrors;
        
        Test.stopTest();        
        System.assertEquals('200', String.valueOf(mockResponseFailed.response.getStatusCode()),'200 expected, received valid response code');        
        System.assertEquals(failedResponse, mockResponseFailed.response.getBody(),'Invalid response body, expected: {"success": false,"returnType": "ERROR","errors": [{"errorMessage": "Rate limit reached, please try again later","errorCode": 1009}]}');
    }

    @isTest
    static void doIXOPaymentAPICalloutError(){
        Payment_Link_Manager__c plm = [SELECT Id, Building_Account_id__c,Invoice_Due_Amount__c,Building_Currency__c,Account_UUID__c,Location_UUID__c FROM Payment_Link_Manager__c LIMIT 1];                
        String failedResponse = '{"success": false,"returnType": "ERROR","errors": [{"errorMessage": "Rate limit reached, please try again later","errorCode": 1009}]}';

        MuleAPIUtilityTest.MockHttpResponseHandler mockResponseHandler = new MuleAPIUtilityTest.MockHttpResponseHandler();        
        MuleAPIUtilityTest.MockResponse mockResponseError = new MuleAPIUtilityTest.MockResponse('POST', failedResponse, 400,'application/json');        
        IXOPayCustomLinkAPI ixoPayAPI = new IXOPayCustomLinkAPI();
            
        mockResponseHandler.addResponse(endPoint, mockResponseError);        
                
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, mockResponseHandler);
        
        Map<String,String> mapJson =  new Map<String,String>{plm.Location_UUID__c => failedResponse};
        Map<Id,Map<String,String>> mapJsonId = new Map<Id,Map<String,String>>{plm.Id => mapJson};
        ixoPayAPI.doIXOPaymentAPICallout(mapJsonId, '');            

        Test.stopTest();        
        System.assertEquals('400', String.valueOf(mockResponseError.response.getStatusCode()),'400 expected, received valid response code');        
        System.assertEquals(failedResponse, mockResponseError.response.getBody(),'Invalid response body, expected: {"success": false,"returnType": "ERROR","errors": [{"errorMessage": "Rate limit reached, please try again later","errorCode": 1009}]}');
    }
}