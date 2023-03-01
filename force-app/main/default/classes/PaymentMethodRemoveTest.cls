/*************************************************************************************************************************************
    Author      :   Serge Kandukuri
    Description :   This class provides sufficient test coverage for PaymentMethodRemove class
    --------------------------------------------------------------------------------------------------------------------------------------
    VERSION    DATE            AUTHOR             DETAIL
    1          16 Sep, 2021    Serge Kandukuri    Initial Deployment
**************************************************************************************************************************************/
@isTest
public with sharing class PaymentMethodRemoveTest {

    @testSetup
    static void makeData(){
        List<Account> accountList = (List<Account>)TestingUtility.getRecords(new Map<String, Object>{'objName' => 'Account', 'numberOfRecords' => 1});
        Account testAcc = accountList.get(0);
        
        testAcc.UUId__c = '454545';
        TestingUtility.updateWithAssert(testAcc);
        
        Contact newContact = new Contact(FirstName ='Billing', LastName = 'TestContact', Email = 'testcontact@example.com', AccountId = testAcc.Id);           
        TestingUtility.insertWithAssert(newContact);
        
        newContact.UUId__c = '5cc1c526-f6f4-43f0-8ca0-02fe1df8c350';
        TestingUtility.updateWithAssert(newContact);
        
        blng__PaymentGateway__c pGateway = new blng__PaymentGateway__c();
        pGateway.Name = 'IXOPay';
        pGateway.blng__Active__c = TRUE;
        pGateway.blng__GatewayType__c = 'AuthorizeDotNet';
        Database.insert(pGateway);
        
        Building__c building = new Building__c();
        building.Name = 'testbuild-001';
        building.Building_ID__c = 'test';
        building.UUID__c = 'test';
        building.Time_Zone__c ='America/Denver';
        Database.insert(building);
        
        Building_Account__c buildingAcc = new Building_Account__c();
        buildingAcc.Billing_Account_Id__c = testAcc.Id;
        buildingAcc.Building_Id__c = building.Id;
        Database.insert(buildingAcc);
        
        blng__Paymentmethod__c payMethod = new blng__Paymentmethod__c();
        payMethod.blng__PaymentGateway__c = pGateway.Id;
        payMethod.blng__Account__c = testAcc.Id;
        payMethod.blng__PaymentType__c = 'Credit Card';
        payMethod.blng__PaymentGatewayToken__c = 'TEST_TOKEN';
        Database.insert(payMethod);
    }
    
    @isTest
    static void removePaymentMethodsPositive(){

        Map<String,Object> inputs = new Map<String, Object>();
        inputs.put('gatewayToken', 'TEST_TOKEN');
    
        Test.startTest();
        Flow.Interview.removePaymentMethodsFlow removeMethodEndpoint = new Flow.Interview.removePaymentMethodsFlow(inputs);
        removeMethodEndpoint.start();
        Test.stopTest();
        
        String message = (String) removeMethodEndpoint.getVariableValue('outputmessage');
        System.assertEquals('Payload Verified', message, 'Payment Method Not Deleted.');
    }
    
    @isTest
    static void removePaymentMethodsNegative(){
        Map<String,Object> inputs = new Map<String, Object>();
        inputs.put('gatewayToken', null);
    
        Test.startTest();
        Flow.Interview.removePaymentMethodsFlow removeMethodEndpoint = new Flow.Interview.removePaymentMethodsFlow(inputs);
        removeMethodEndpoint.start();
        Test.stopTest();
        
        String message = (String) removeMethodEndpoint.getVariableValue('outputmessage');
        System.assertEquals('Please Provide Payment Gateway Token.', message, 'Payment Method Deleted.');
    }
    
    @isTest
    static void removePaymentMethodsNegativeNoMatch(){
        Map<String,Object> inputs = new Map<String, Object>();
        inputs.put('gatewayToken', 'abc');
    
        Test.startTest();
        Flow.Interview.removePaymentMethodsFlow removeMethodEndpoint = new Flow.Interview.removePaymentMethodsFlow(inputs);
        removeMethodEndpoint.start();
        Test.stopTest();
        
        String message = (String) removeMethodEndpoint.getVariableValue('outputmessage');
        System.assertEquals('No Matching Token in Salesforce', message, 'Payment Method Deleted.');
    }
   
}