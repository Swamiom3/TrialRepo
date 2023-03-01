/*************************************************************************************************************************************
    Author      :   Serge Kandukuri
    Description :   This class provides sufficient test coverage for PaymentMethodFetch class
    --------------------------------------------------------------------------------------------------------------------------------------
    VERSION    DATE            AUTHOR             DETAIL
    1          16 Sep, 2021    Serge Kandukuri    Initial Deployment
**************************************************************************************************************************************/
@isTest
public with sharing class PaymentMethodFetchTest {

    @testSetup
    static void makeData(){
        List<Account> accountList = (List<Account>)TestingUtility.getRecords(new Map<String, Object>{'objName' => 'Account', 'numberOfRecords' => 1});
        Account testAcc = accountList.get(0);
        
        testAcc.UUId__c = '454545';
        TestingUtility.updateWithAssert(testAcc);
        
        Contact newContact = new Contact(FirstName = 'FirstName', LastName = 'TestContact', Email = 'testcontact@example.com', AccountId = testAcc.Id);           
        TestingUtility.insertWithAssert(newContact);
        
        newContact.UUId__c = '5cc1c526-f6f4-43f0-8ca0-02fe1df8c350';
        TestingUtility.updateWithAssert(newContact);
        
        blng__PaymentGateway__c pGateway = new blng__PaymentGateway__c();
        pGateway.Name = 'IXOPay';
        pGateway.blng__Active__c = true;
        pGateway.blng__GatewayType__c = 'AuthorizeDotNet';
        Database.insert(pGateway);
        
        Building__c building = new Building__c();
        building.Name = 'testbuild-001';
        building.Building_ID__c = 'test';
        building.Time_Zone__c ='America/Denver';
        building.UUID__c = 'abcdefg';
        Database.insert(building);
        
        Building_Account__c buildingAcc = new Building_Account__c();
        buildingAcc.Billing_Account_Id__c = testAcc.Id;
        buildingAcc.Building_Id__c = building.Id;
        Database.insert(buildingAcc);
        
        blng__Paymentmethod__c paymentMethod = new blng__Paymentmethod__c();
        paymentMethod.blng__PaymentGateway__c = pGateway.Id;
        paymentMethod.blng__Account__c = testAcc.Id;
        paymentMethod.Building_Account_Id__c = buildingAcc.Id;
        paymentMethod.blng__PaymentType__c = 'Credit Card';
        Database.insert(paymentMethod);
    }
    
    @isTest
    static void fetchPaymentMethodsPositive(){
        Map<String,Object> inputs = new Map<String, Object>();
        inputs.put('accountUUId', '454545');
        inputs.put('locationUUId', 'abcdefg');
    
        Test.startTest();
        Flow.Interview.fetchPaymentMethodsByUUIDFlow fetchMethodsflow = new Flow.Interview.fetchPaymentMethodsByUUIDFlow(inputs);
        fetchMethodsflow.start();
        Test.stopTest();

        String message = (String) fetchMethodsflow.getVariableValue('outputmessage');
        System.assertEquals('Payload Verified', message, 'Payment Methods Not Found');
        
        
    }
    
    @isTest
    static void fetchPaymentMethodsNegative(){
        Map<String,Object> inputs = new Map<String, Object>();
        inputs.put('accountUUId', '454545x');
        inputs.put('locationUUId', 'abcdefg');
    
        Test.startTest();
        Flow.Interview.fetchPaymentMethodsByUUIDFlow fetchMethodsflow = new Flow.Interview.fetchPaymentMethodsByUUIDFlow(inputs);
        fetchMethodsflow.start();
        Test.stopTest();

        String message = (String) fetchMethodsflow.getVariableValue('outputmessage');
        System.assertEquals('Account not found.', message, 'Account Found');
        
        
    }
}