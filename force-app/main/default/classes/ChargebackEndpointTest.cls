/*************************************************************************************************************************************
    Author      :   Tayo Chestnut
    Description :   This class provides sufficient test coverage for ChargebackEndpoints flow and wrapper classes
    --------------------------------------------------------------------------------------------------------------------------------------
    VERSION    DATE            AUTHOR             DETAIL
    1          29 Dec, 2021    Tayo Chestnut   Initial Deployment
**************************************************************************************************************************************/
@isTest
public with sharing class ChargebackEndpointTest {
    @testSetup
    static void makeData(){
        
        Account testAccount = new Account();
        testAccount.Name = 'Test_Account';
        testAccount.UUId__c = '454545';
        insert testAccount;

        blng__LegalEntity__c legalEntity = new blng__LegalEntity__c();
        legalEntity.Name = 'Test Legal Entity';
        legalEntity.CurrencyIsoCode = 'CAD';
        insert legalEntity;

        List<Building__c> buildingsToInsert = new List<Building__c>();
        buildingsToInsert.add(UtilBuilding.createBuilding(null, 'test@test.com', null, true));
        buildingsToInsert.get(0).WeCode__c = 'ABC';
        buildingsToInsert.get(0).UUID__c = 'abcdefg';
        buildingsToInsert.get(0).Legal_Entity_Id__c = legalEntity.Id;
        upsert buildingsToInsert;
        
        Building_Account__c buildingAccount = new Building_Account__c();
        buildingAccount.Billing_Account_Id__c = testAccount.Id;
        buildingAccount.Building_Id__c = buildingsToInsert.get(0).Id;
        insert buildingAccount;
        
        List<blng__Invoice__c> invs = new List<blng__Invoice__c>();
        invs.add(new blng__Invoice__c(blng__Account__c = testAccount.Id,
                                      blng__InvoiceStatus__c = 'Draft',
                                      Invoice_Type__c = 'Standard',
                                      Building_Id__c = buildingsToInsert.get(0).Id,
                                      blng__InvoiceDate__c = System.today(),
                                      blng__DueDate__c = System.today().addDays(-5)));
        invs.add(new blng__Invoice__c(blng__Account__c = testAccount.Id,
                                      blng__InvoiceStatus__c = 'Draft',
                                      Invoice_Type__c = 'Standard',
                                      blng__InvoiceDate__c = System.today(),
                                      blng__DueDate__c = System.today().addDays(-2)));
        Database.insert(invs);

        blng__PaymentGateway__c pGateway = new blng__PaymentGateway__c();
        pGateway.Name = 'IXOPay';
        pGateway.blng__Active__c = true;
        pGateway.blng__GatewayType__c = 'AuthorizeDotNet';
        Database.insert(pGateway);

        blng__PaymentTransaction__c paymentTrans = new blng__PaymentTransaction__c();
        paymentTrans.blng__Account__c = testAccount.Id;
        paymentTrans.blng__GatewayDate__c = System.today();
        paymentTrans.blng__PaymentGateway__c = pGateway.Id;
        paymentTrans.blng__CardType__c = 'VISA';
        paymentTrans.blng__Type__c = 'Charge';
        paymentTrans.blng__RequestInvoice__c = invs.get(0).Id;
        paymentTrans.blng__GatewayStatus__c = 'Success';
        paymentTrans.blng__Amount__c = 100;
        insert paymentTrans;

    }

    @isTest
    static void chargebacksPositive(){

        blng__PaymentTransaction__c transactionToTest = [SELECT id FROM blng__PaymentTransaction__c LIMIT 1];

        ChargebackWrapper myChargeback = new ChargebackWrapper();
        myChargeback.amount = 100;
        myChargeback.chargebackDateTime = Date.newInstance(2021, 12, 14); 
        myChargeback.currencyCode = 'CAD';
        myChargeback.originalMerchantTransactionId = transactionToTest.Id;
        myChargeback.originalUUID = 'abcdefg';
        myChargeback.reason = 'Unauthorized payment';
        myChargeback.reversalDateTime = null;
        
        Map<String,Object> inputs = new Map<String, Object>();
        inputs.put('chargebackData', myChargeback);
        inputs.put('merchantTransactionId', transactionToTest.Id);
        inputs.put('purchaseId','20190927-abcde12345abcde12345');
        inputs.put('uuid','abcdefg');
        inputs.put('transactionType','CHARGEBACK');
        inputs.put('amount',100);
        inputs.put('currencyCode','CAD');
        inputs.put('result','OK');

        Test.startTest();
        Flow.Interview.Chargebacks_Endpoint chargebacksEndpointFlow = new Flow.Interview.Chargebacks_Endpoint(inputs);
        chargebacksEndpointFlow.start();
        Test.stopTest();
        
        String message = (String) chargebacksEndpointFlow.getVariableValue('outputmessage');
        System.assertEquals('Payload Verified', message,'Chargeback Failed');
    }

    @isTest
    static void chargebacksInvalidPayload(){

        blng__PaymentTransaction__c transactionToTest = [SELECT id FROM blng__PaymentTransaction__c LIMIT 1];

        ChargebackWrapper myChargeback = new ChargebackWrapper();
        myChargeback.amount = 100;
        myChargeback.chargebackDateTime = Date.newInstance(2021, 12, 14); 
        myChargeback.currencyCode = null;
        myChargeback.originalMerchantTransactionId = transactionToTest.Id;
        myChargeback.originalUUID = 'abcdefg';
        myChargeback.reason = 'Unauthorized payment';
        myChargeback.reversalDateTime = null;
        
        Map<String,Object> inputs = new Map<String, Object>();
        inputs.put('chargebackData', myChargeback);
        inputs.put('merchantTransactionId', transactionToTest.Id);
        inputs.put('purchaseId','20190927-abcde12345abcde12345');
        inputs.put('uuid','abcdefg');
        inputs.put('transactionType','CHARGEBACK');
        inputs.put('amount',100);
        inputs.put('currencyCode','CAD');
        inputs.put('result','OK');

        Test.startTest();
        Flow.Interview.Chargebacks_Endpoint chargebacksEndpointFlow = new Flow.Interview.Chargebacks_Endpoint(inputs);
        chargebacksEndpointFlow.start();
        Test.stopTest();
        
        String message = (String) chargebacksEndpointFlow.getVariableValue('outputmessage');
        System.assertEquals('Invalid Payload', message,'Chargeback Successful');
    }

    @isTest
    static void chargebacksNegative(){

        blng__PaymentTransaction__c transactionToTest = [SELECT id FROM blng__PaymentTransaction__c LIMIT 1];

        ChargebackWrapper myChargeback = new ChargebackWrapper();
        myChargeback.amount = 100;
        myChargeback.chargebackDateTime = Date.newInstance(2021, 12, 14); 
        myChargeback.currencyCode = 'CAD';
        myChargeback.originalMerchantTransactionId = 'aaaaaaaaaaaaaaaaaa';
        myChargeback.originalUUID = 'abcdefg';
        myChargeback.reason = 'Unauthorized payment';
        myChargeback.reversalDateTime = null;
       
        Map<String,Object> inputs = new Map<String, Object>();
        inputs.put('chargebackData', myChargeback);
        inputs.put('merchantTransactionId', 'aaaaaaaaaaaaaaaaaa');
        inputs.put('purchaseId','20190927-abcde12345abcde12345');
        inputs.put('uuid','abcdefg');
        inputs.put('transactionType','CHARGEBACK');
        inputs.put('amount',100);
        inputs.put('currencyCode','CAD');
        inputs.put('result','OK');

        Test.startTest();
        Flow.Interview.Chargebacks_Endpoint chargebacksEndpointFlow = new Flow.Interview.Chargebacks_Endpoint(inputs);
        chargebacksEndpointFlow.start();
        Test.stopTest();
        
        String message = (String) chargebacksEndpointFlow.getVariableValue('outputmessage');
        System.assertEquals('No Matching Transaction Type/Card Type', message,'Chargeback Successful');
    }
}