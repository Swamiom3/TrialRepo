@isTest
public with sharing class ObjectTypeFinderTest {
    @testSetup
    static void makeData(){
        List<Account> accountList = (List<Account>)TestingUtility.getRecords(new Map<String, Object>{'objName' => 'Account', 'numberOfRecords' => 1});
        Account testAcc = accountList.get(0);
        
        testAcc.UUId__c = '454545';
        TestingUtility.updateWithAssert(testAcc);

        List<Building__c> buildingsToInsert=new List<Building__c>();
        buildingsToInsert.add(UtilBuilding.createBuilding(null, 'test@test.com', null, true));
        buildingsToInsert.get(0).WeCode__c = 'ABC';
        upsert buildingsToInsert;
        
        // Invoice
        List<blng__Invoice__c> invs = new List<blng__Invoice__c>();
        invs.add(new blng__Invoice__c(blng__Account__c = testAcc.Id,
                                      blng__InvoiceStatus__c = 'Draft',
                                      Invoice_Type__c = 'Standard',
                                      Building_Id__c = buildingsToInsert.get(0).Id,
                                      blng__InvoiceDate__c = system.today(),
                                      Temp_Number__c = 1,
                                      blng__DueDate__c = System.today().addDays(-5)));
        Database.insert(invs);

        blng__PaymentGateway__c pGateway = new blng__PaymentGateway__c();
        pGateway.Name = 'IXOPay';
        pGateway.blng__Active__c = true;
        pGateway.blng__GatewayType__c = 'AuthorizeDotNet';
        Database.insert(pGateway);       

        blng__Paymentmethod__c pMethod = new blng__Paymentmethod__c();
        pMethod.blng__PaymentGateway__c = pGateway.Id;
        pMethod.blng__Account__c = testAcc.Id;
        pMethod.blng__PaymentType__c = 'Credit Card';
        pMethod.blng__PaymentGatewayToken__c = 'TEST_TOKEN';
        Database.insert(pMethod);

        blng__PaymentTransaction__c origTransaction = new blng__PaymentTransaction__c();
        origTransaction.blng__Account__c = testAcc.Id;
        origTransaction.blng__PaymentGateway__c = pGateway.Id;
        origTransaction.blng__PaymentMethod__c = pMethod.Id;
        origTransaction.blng__Amount__c = 100;
        origTransaction.blng__RequestInvoice__c = invs.get(0).Id;
        origTransaction.blng__GatewayStatus__c = 'Success';
        origTransaction.blng__CardType__c = 'Visa';
        origTransaction.blng__CardExpirationMonth__c = '12';
        origTransaction.blng__CardExpirationYear__c = '2025';
        origTransaction.blng__RequestCreditCardNumber__c = '1212';
        origTransaction.blng__Status__c = 'Processed';
        origTransaction.blng__Type__c = 'Charge';
        origTransaction.blng__GatewayDate__c = System.now();

        Database.insert(origTransaction);

        Payment_Link_Manager__c paymentLink = new Payment_Link_Manager__c();
        paymentLink.Invoice_Due_Amount__c = 500;
        insert paymentLink;
    }

    @isTest
    static void getPaymentTransactionPrefix(){
        blng__PaymentTransaction__c payTransaction = [SELECT Id FROM blng__PaymentTransaction__c LIMIT 1];
        List<ObjectTypeFinder.Request> invocableRequests = new List<ObjectTypeFinder.Request>();
        ObjectTypeFinder.Request invocableRequest = new ObjectTypeFinder.Request();
        invocableRequest.sfId = payTransaction.Id;
        invocableRequests.add(invocableRequest);
        
        List<ObjectTypeFinder.ReturnOutput> myOutput = ObjectTypeFinder.findObjectNameByPrefix(invocableRequests);
        System.assertEquals('blng__PaymentTransaction__c', myOutput.get(0).objectName, 'Invalid ObjectName');

    }

    @isTest
    static void getPaymentLinkManagerPrefix(){
        Payment_Link_Manager__c paymentLink = [SELECT Id FROM Payment_Link_Manager__c LIMIT 1];
        List<ObjectTypeFinder.Request> invocableRequests = new List<ObjectTypeFinder.Request>();
        ObjectTypeFinder.Request invocableRequest = new ObjectTypeFinder.Request();
        invocableRequest.sfId = paymentLink.Id;
        invocableRequests.add(invocableRequest);
        
        List<ObjectTypeFinder.ReturnOutput> myOutput = ObjectTypeFinder.findObjectNameByPrefix(invocableRequests);
        System.assertEquals('Payment_Link_Manager__c', myOutput.get(0).objectName, 'Invalid ObjectName');

    }
 
}