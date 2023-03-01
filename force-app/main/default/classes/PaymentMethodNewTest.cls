/*************************************************************************************************************************************
    Author      :   Serge Kandukuri
    Description :   This class provides sufficient test coverage for PaymentMethodNew class
    --------------------------------------------------------------------------------------------------------------------------------------
    VERSION    DATE            AUTHOR             DETAIL
    1          16 Sep, 2021    Serge Kandukuri    Initial Deployment
**************************************************************************************************************************************/
@isTest
public with sharing class PaymentMethodNewTest {

    @testSetup
    static void makeData(){
        List<Account> accountList = (List<Account>)TestingUtility.getRecords(new Map<String, Object>{'objName' => 'Account', 'numberOfRecords' => 1});
        Account testAcc = accountList.get(0);
        
        testAcc.UUId__c = '454545';
        TestingUtility.updateWithAssert(testAcc);
        
        Contact newContact = new Contact(FirstName = 'Billing', LastName = 'TestContact', Email = 'testcontact@example.com', AccountId = testAcc.Id);           
        TestingUtility.insertWithAssert(newContact);
        
        newContact.UUId__c = '5cc1c526-f6f4-43f0-8ca0-02fe1df8c350';
        TestingUtility.updateWithAssert(newContact);
        Building__c building = new Building__c();
        building.UUID__c = 'ABCD';
        building.Name = 'Test Building';
        Database.insert(building);
        
        Building_Account__c buildAccount = new Building_Account__c();
        buildAccount.Building_Id__c = building.Id;
        buildAccount.Account_Id__c = testAcc.Id;
        buildAccount.Billing_Account_Id__c = testAcc.Id;
        buildAccount.Name = 'Test Building Account';
        Database.insert(buildAccount);
        
        blng__PaymentGateway__c objPG = new blng__PaymentGateway__c();
        objPG.Name = 'IXOPay';
        objPG.blng__Active__c = true;
        objPG.blng__GatewayType__c = 'AuthorizeDotNet';
        Database.insert(objPG);
    }
    
    @isTest
    static void createPaymentMethodsPositive(){
        Map<String,Object> inputs = new Map<String,Object>();
        inputs.put('accountUUId', '454545');
        inputs.put('locationUUId', 'ABCD');
        inputs.put('contactUUId', '5cc1c526-f6f4-43f0-8ca0-02fe1df8c350');
        inputs.put('accountName', 'Joels Billing Account');
        inputs.put('paymentType', 'Credit Card');
        inputs.put('paymentGatewayToken', 'ABCDE');
        inputs.put('currencyCode', 'CAD');
        inputs.put('streetAddress', 'Test Address');
        inputs.put('nameOnCard', 'Test Name');
        inputs.put('cardNumber', '4111111111111111');
        inputs.put('cardType', 'VISA');
        inputs.put('expiryMonth', '10');
        inputs.put('expiryYear', '2025');
        inputs.put('CVV', '123');
        
        Test.startTest();
        Flow.Interview.createNewPaymentmethodFlow newMethodEndpoint = new Flow.Interview.createNewPaymentmethodFlow(inputs);
        newMethodEndpoint.start();
        Test.stopTest();
        
        String message = (String) newMethodEndpoint.getVariableValue('outputmessage');
        System.assertEquals('Payload Verified', message, 'Payment Method Not Found');
    }
    
    @isTest
    static void createPaymentMethodsNegative(){
        Map<String,Object> inputs = new Map<String,Object>();
        inputs.put('accountUUId', '1234');
        inputs.put('locationUUId', null);
        inputs.put('contactUUId', '5cc1c526-f6f4-43f0-8ca0-02fe1df8c350');
        inputs.put('accountName', 'Joels Billing Account');
        inputs.put('paymentType', 'Credit Card');
        inputs.put('currencyCode', 'CAD');
        inputs.put('streetAddress', 'Test Address');
        inputs.put('nameOnCard', 'Test Name');
        inputs.put('cardNumber', '4111111111111111');
        inputs.put('cardType', 'VISA');
        inputs.put('expiryMonth', '10');
        inputs.put('expiryYear', '2025');
        inputs.put('CVV', '123');

		Test.startTest();
        Flow.Interview.createNewPaymentmethodFlow newMethodEndpoint = new Flow.Interview.createNewPaymentmethodFlow(inputs);
        newMethodEndpoint.start();
        Test.stopTest();
        
        String message = (String) newMethodEndpoint.getVariableValue('outputmessage');
        System.assertEquals('Payload Missing Data', message, 'Payment Method Found');
    }

    @isTest
    static void createPaymentMethodsnoAccount(){
        Map<String,Object> inputs = new Map<String,Object>();
        inputs.put('accountUUId', '4545456');
        inputs.put('locationUUId', 'ABCD');
        inputs.put('contactUUId', '5cc1c526-f6f4-43f0-8ca0-02fe1df8c350');
        inputs.put('accountName', 'Joels Billing Account');
        inputs.put('paymentType', 'Credit Card');
        inputs.put('paymentGatewayToken', 'ABCDE');
        inputs.put('currencyCode', 'CAD');
        inputs.put('streetAddress', 'Test Address');
        inputs.put('nameOnCard', 'Test Name');
        inputs.put('cardNumber', '4111111111111111');
        inputs.put('cardType', 'VISA');
        inputs.put('expiryMonth', '10');
        inputs.put('expiryYear', '2025');
        inputs.put('CVV', '123');
        
        Test.startTest();
        Flow.Interview.createNewPaymentmethodFlow newMethodEndpoint = new Flow.Interview.createNewPaymentmethodFlow(inputs);
        newMethodEndpoint.start();
        Test.stopTest();
        
        String message = (String) newMethodEndpoint.getVariableValue('outputmessage');
        System.assertEquals('No Matching Account', message, 'Payment Method Found');
    }

    @isTest
    static void createPaymentMethodsnoBuilding(){
        Map<String,Object> inputs = new Map<String,Object>();
        inputs.put('accountUUId', '454545');
        inputs.put('locationUUId', 'ABCDe');
        inputs.put('contactUUId', '5cc1c526-f6f4-43f0-8ca0-02fe1df8c350');
        inputs.put('accountName', 'Joels Billing Account');
        inputs.put('paymentType', 'Credit Card');
        inputs.put('paymentGatewayToken', 'ABCDE');
        inputs.put('currencyCode', 'CAD');
        inputs.put('streetAddress', 'Test Address');
        inputs.put('nameOnCard', 'Test Name');
        inputs.put('cardNumber', '4111111111111111');
        inputs.put('cardType', 'VISA');
        inputs.put('expiryMonth', '10');
        inputs.put('expiryYear', '2025');
        inputs.put('CVV', '123');
        
        Test.startTest();
        Flow.Interview.createNewPaymentmethodFlow newMethodEndpoint = new Flow.Interview.createNewPaymentmethodFlow(inputs);
        newMethodEndpoint.start();
        Test.stopTest();
        
        String message = (String) newMethodEndpoint.getVariableValue('outputmessage');
        System.assertEquals('Building/Location not found.', message, 'Payment Method Found');
    }
}