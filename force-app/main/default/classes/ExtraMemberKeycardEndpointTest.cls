/*************************************************************************************************************************************
    Author      :   Tayo Chestnut
    Description :   This class provides sufficient test coverage for ExtraMemberKeycardEndpointTest flow and wrapper classes
    --------------------------------------------------------------------------------------------------------------------------------------
    VERSION    DATE            AUTHOR             DETAIL
    1          13 Feb, 2022    Tayo Chestnut   Initial Deployment
**************************************************************************************************************************************/
@isTest
public with sharing class ExtraMemberKeycardEndpointTest {
    @testSetup
    static void makeData(){
        
        Account testAccount = new Account();
        testAccount.Name = 'Test_Account_extra';
        testAccount.UUId__c = '454545';
        insert testAccount;

        Account testAccountFail = new Account();
        testAccountFail.Name = 'Test_Account_extra_Fail';
        testAccountFail.UUId__c = '45454577';
        insert testAccountFail;

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
        buildingAccount.Account_Id__c = testAccount.Id;
        buildingAccount.Billing_Account_Id__c = testAccount.Id;
        buildingAccount.Building_Id__c = buildingsToInsert.get(0).Id;
        insert buildingAccount;
        
        ServiceContract serviceContractToTest = new ServiceContract();
        serviceContractToTest.Name = 'TestContract';
        serviceContractToTest.AccountId = testAccount.Id;
        serviceContractToTest.Building_Id__c = buildingsToInsert.get(0).Id;
        serviceContractToTest.StartDate = System.today();
        serviceContractToTest.EndDate = System.today().addDays(5);
        insert serviceContractToTest;

        Product2 keycardProduct = new Product2();
        keycardProduct.Description = 'TestKeycard';
        keycardProduct.ProductCode = 'keycard';
        keycardProduct.Name = 'Keycard';
        keycardProduct.IsActive = true;
        keycardProduct.Product_UUID__c = UUIDHandler.generateVersion4();
        insert keycardProduct;

    }

    @isTest
    static void keycardInvalidPayload(){

        Map<String,Object> inputs = new Map<String, Object>();
        inputs.put('startedon', system.today());
        inputs.put('endedon', system.today().addDays(2));
        inputs.put('reservableuuid','keycard');
        inputs.put('accountuuid','454545');
        inputs.put('locationuuid','abcdefg');
        inputs.put('quantity',1);
        inputs.put('price',100);
        inputs.put('application','');
        inputs.put('resuuid',null);

        Test.startTest();
        Flow.Interview.Extra_Member_Keycard_EndPoint keycardEndpointFlow = new Flow.Interview.Extra_Member_Keycard_EndPoint(inputs);
        keycardEndpointFlow.start();
        Test.stopTest();
        
        String message = (String) keycardEndpointFlow.getVariableValue('outputmessage');
        System.assertEquals('Payload Missing Data', message,'Endpoint Success');
    }

    @isTest
    static void keycardNoAccount(){

        Map<String,Object> inputs = new Map<String, Object>();
        inputs.put('startedon', system.today());
        inputs.put('endedon', system.today().addDays(2));
        inputs.put('reservableuuid','keycard');
        inputs.put('accountuuid','4545456');
        inputs.put('locationuuid','abcdefg');
        inputs.put('quantity',1);
        inputs.put('price',100);
        inputs.put('application','A');
        inputs.put('resuuid','A');

        Test.startTest();
        Flow.Interview.Extra_Member_Keycard_EndPoint keycardEndpointFlow = new Flow.Interview.Extra_Member_Keycard_EndPoint(inputs);
        keycardEndpointFlow.start();
        Test.stopTest();
        
        String message = (String) keycardEndpointFlow.getVariableValue('outputmessage');
        System.assertEquals('No Matching Account', message,'Endpoint Success');
    }

    @isTest
    static void keycardNoBuilding(){

        Map<String,Object> inputs = new Map<String, Object>();
        inputs.put('startedon', system.today());
        inputs.put('endedon', system.today().addDays(2));
        inputs.put('reservableuuid','keycard');
        inputs.put('accountuuid','454545');
        inputs.put('locationuuid','abcdefgi');
        inputs.put('quantity',1);
        inputs.put('price',100);
        inputs.put('application','A');
        inputs.put('resuuid','A');

        Test.startTest();
        Flow.Interview.Extra_Member_Keycard_EndPoint keycardEndpointFlow = new Flow.Interview.Extra_Member_Keycard_EndPoint(inputs);
        keycardEndpointFlow.start();
        Test.stopTest();
        
        String message = (String) keycardEndpointFlow.getVariableValue('outputmessage');
        System.assertEquals('No Building Found', message,'Endpoint Success');
    }

    @isTest
    static void keycardNoBuildingAccount(){

        Map<String,Object> inputs = new Map<String, Object>();
        inputs.put('startedon', system.today());
        inputs.put('endedon', system.today().addDays(2));
        inputs.put('reservableuuid','keycard');
        inputs.put('accountuuid','45454577');
        inputs.put('locationuuid','abcdefg');
        inputs.put('quantity',1);
        inputs.put('price',100);
        inputs.put('application','A');
        inputs.put('resuuid','A');

        Test.startTest();
        Flow.Interview.Extra_Member_Keycard_EndPoint keycardEndpointFlow = new Flow.Interview.Extra_Member_Keycard_EndPoint(inputs);
        keycardEndpointFlow.start();
        Test.stopTest();
        
        String message = (String) keycardEndpointFlow.getVariableValue('outputmessage');
        System.assertEquals('No Building Account Found', message,'Endpoint Success');
    }
   
    @isTest
    static void keycardNoContract(){

        Account accFail = [SELECT id FROM Account WHERE UUID__c = '45454577'];
        ServiceContract scFail = [SELECT id, AccountId FROM ServiceContract LIMIT 1];
        scFail.AccountId = accFail.Id;
        update scFail;
        
        Map<String,Object> inputs = new Map<String, Object>();
        inputs.put('startedon', system.today());
        inputs.put('endedon', system.today().addDays(2));
        inputs.put('reservableuuid','keycard');
        inputs.put('accountuuid','454545');
        inputs.put('locationuuid','abcdefg');
        inputs.put('quantity',1);
        inputs.put('price',100);
        inputs.put('application','A');
        inputs.put('resuuid','A');

        Test.startTest();
        Flow.Interview.Extra_Member_Keycard_EndPoint keycardEndpointFlow = new Flow.Interview.Extra_Member_Keycard_EndPoint(inputs);
        keycardEndpointFlow.start();
        Test.stopTest();
        
        String message = (String) keycardEndpointFlow.getVariableValue('outputmessage');
        System.assertEquals('No Active Service Contract Found', message,'Endpoint Success');
    }

    @isTest
    static void keycardSuccess(){
        
        Map<String,Object> inputs = new Map<String, Object>();
        inputs.put('startedon', system.today());
        inputs.put('endedon', system.today().addDays(2));
        inputs.put('reservableuuid','keycard');
        inputs.put('accountuuid','454545');
        inputs.put('locationuuid','abcdefg');
        inputs.put('quantity',1);
        inputs.put('price',100);
        inputs.put('application','A');
        inputs.put('resuuid','A');

        Test.startTest();
        Flow.Interview.Extra_Member_Keycard_EndPoint keycardEndpointFlow = new Flow.Interview.Extra_Member_Keycard_EndPoint(inputs);
        keycardEndpointFlow.start();
        Test.stopTest();
        
        String message = (String) keycardEndpointFlow.getVariableValue('outputmessage');
        System.assertEquals('Payload Verified', message,'Endpoint Failed');
    }
}