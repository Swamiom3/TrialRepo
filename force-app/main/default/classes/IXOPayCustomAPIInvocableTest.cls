/************************************************************************************************************************************
Author      :   Salesforce
Description :   This class has testmethods to cover IXOPayCustomAPIInvocable class
----------------------------------------------------------------------------------------------------------------------------------
    VERSION      DATE         AUTHOR              DETAIL
    1            02/11/2022   Salesforce          Initial creation
**************************************************************************************************************************************/
@isTest
public with sharing class IXOPayCustomAPIInvocableTest {
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
        businessAccount.RecordTypeId = businessAccountRecTypeId;
        accountsInsert.add(businessAccount);

        Account billingAccount =  new Account();
        billingAccount.Name = 'TestBillAccount';
        billingAccount.Site = 'TestBillAccount';  
        billingAccount.RecordTypeId = billingAccountRecTypeId;      
        accountsInsert.add(billingAccount);

        insert accountsInsert;

        Building_Account__c buildingAccount = new Building_Account__c();
        buildingAccount.Account_Id__c = businessAccount.Id;
        buildingAccount.Billing_Account_Id__c = billingAccount.Id;
        buildingAccount.Building_Id__c = building.Id;
        insert buildingAccount;

        Payment_Link_Manager__c paylinkManager = new Payment_Link_Manager__c();
        paylinkManager.Building_Account_id__c = buildingAccount.Id;
        paylinkManager.Invoice_Due_Amount__c = 500.00;
        insert paylinkManager;
    }

    @isTest
    static void getPaymentLinkMultiplePositive(){              
        Payment_Link_Manager__c paymentLinkManager = [SELECT Id, Building_Account_id__c,Invoice_Due_Amount__c,Building_Currency__c,Account_UUID__c,Location_UUID__c FROM Payment_Link_Manager__c LIMIT 1];        
        List<PaymentLinkManagerWrapper> paymentLinkManagerWrappers = new List<PaymentLinkManagerWrapper>();
        String responseBody = '{"access_token": "Token","expires_in": 86400,"token_type": "Bearer"}';

        PaymentLinkManagerWrapper paymentLinkManagerWrapper =  new PaymentLinkManagerWrapper();
        paymentLinkManagerWrapper.plm = paymentLinkManager;
        paymentLinkManagerWrappers.add(paymentLinkManagerWrapper);

        List<IXOPayCustomAPIInvocable.PLMRequest> paymentLinkRequests = new List<IXOPayCustomAPIInvocable.PLMRequest>();
        IXOPayCustomAPIInvocable.PLMRequest paymentLinkRequest = new IXOPayCustomAPIInvocable.PLMRequest();
        paymentLinkRequest.plms = paymentLinkManagerWrappers;
        paymentLinkRequests.add(paymentLinkRequest);

        PaymentLinkManagerWrapper.Customer paymentLinkManagerCustomer= new PaymentLinkManagerWrapper.Customer(paymentLinkManager);

        MuleAPIUtilityTest.MockHttpResponseHandler mockResponseHandler = new MuleAPIUtilityTest.MockHttpResponseHandler();
        MuleAPIUtilityTest.MockResponse mockResponse = new MuleAPIUtilityTest.MockResponse('POST', responseBody, 200,'application/json');
        mockResponseHandler.addResponse(endPoint, mockResponse);
                
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, mockResponseHandler);
        IXOPayCustomAPIInvocable.issuePaymentLinkMultiple(paymentLinkRequests);

        Test.stopTest();
        System.assertEquals('200', String.valueOf(mockResponse.response.getStatusCode()),'200 expected, received invalid response code');        
        System.assertEquals(responseBody, mockResponse.response.getBody(),'Invalid response body, expected: {"access_token": "Token","expires_in": 86400,"token_type": "Bearer"}');
    }

    @isTest
    static void getPaymentLinkMultipleNegative(){
        Payment_Link_Manager__c paymentLinkManager = [SELECT Id, Building_Account_id__c,Invoice_Due_Amount__c,Building_Currency__c,Account_UUID__c,Location_UUID__c FROM Payment_Link_Manager__c LIMIT 1];        
        List<PaymentLinkManagerWrapper> paymentLinkManagerWrappers = new List<PaymentLinkManagerWrapper>();
        String responseBody = '{"access_token": "Token","expires_in": 86400,"token_type": "Bearer"}';

        PaymentLinkManagerWrapper paymentLinkManagerWrapper =  new PaymentLinkManagerWrapper();
        paymentLinkManagerWrapper.plm = paymentLinkManager;
        paymentLinkManagerWrappers.add(paymentLinkManagerWrapper);

        List<IXOPayCustomAPIInvocable.PLMRequest> paymentLinkRequests = new List<IXOPayCustomAPIInvocable.PLMRequest>();
        IXOPayCustomAPIInvocable.PLMRequest paymentLinkRequest = new IXOPayCustomAPIInvocable.PLMRequest();
        paymentLinkRequest.plms = paymentLinkManagerWrappers;
        paymentLinkRequests.add(paymentLinkRequest);

        PaymentLinkManagerWrapper.Customer paymentLinkManagerCustomer= new PaymentLinkManagerWrapper.Customer(paymentLinkManager);

        MuleAPIUtilityTest.MockHttpResponseHandler mockResponseHandler = new MuleAPIUtilityTest.MockHttpResponseHandler();
        MuleAPIUtilityTest.MockResponse mockResponse = new MuleAPIUtilityTest.MockResponse('POST', responseBody, 401,'application/json');
        mockResponseHandler.addResponse(endPoint, mockResponse);

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, mockResponseHandler);
        IXOPayCustomAPIInvocable.issuePaymentLinkMultiple(paymentLinkRequests);

        Test.stopTest();
        System.assertEquals('401', String.valueOf(mockResponse.response.getStatusCode()),'401 expected, received invalid response code');
        System.assertEquals(responseBody, mockResponse.response.getBody(),'Invalid response body, expected: {"error": "access_denied","error_description": "Unauthorized"}');
    }

    public class IXOPayInvocableMock implements HttpCalloutMock {         
        private String jsonbody;
        private Integer statuscode;

        public IXOPayInvocableMock(String jsonbody, Integer statuscode){            
            this.jsonbody = jsonbody;
            this.statuscode = statuscode;
        }

        public HTTPResponse respond(HTTPRequest request) {        
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'text/json');
            res.setBody(jsonbody);
            res.setStatus('OK');
            res.setStatusCode(statuscode);
            System.assertEquals('POST', request.getMethod());
            
            return res;
        }        
    }
}