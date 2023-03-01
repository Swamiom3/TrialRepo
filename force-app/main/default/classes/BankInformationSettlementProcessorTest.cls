/*************************************************************************************************************************************
    Author      :   Tayo Chestnut
    Description :   This class provides sufficient test coverage for PaymentTransactionChargeback class
    --------------------------------------------------------------------------------------------------------------------------------------
    VERSION    DATE            AUTHOR             DETAIL
    1          16 Sep, 2021    Tayo Chestnut   Initial Deployment
**************************************************************************************************************************************/
@isTest
public with sharing class BankInformationSettlementProcessorTest {

    @testSetup
    static void makeData(){
        List<Account> accountList = (List<Account>)TestingUtility.getRecords(new Map<String, Object>{'objName' => 'Account', 'numberOfRecords' => 1});
        Account testAcc = accountList.get(0);
        
        testAcc.UUId__c = '454545';
        TestingUtility.updateWithAssert(testAcc);

        List<blng__Refund__c> refundsToInsert=new List<blng__Refund__c>();
        refundsToInsert.add(new blng__Refund__c(blng__Account__c = testAcc.Id,
                                                currencyIsoCode = 'CAD',
                                                blng__RefundType__c = 'ACH',
                                                blng__RefundMode__c = 'External',
                                                blng__Status__c = 'Draft',
                                                blng__RefundDate__c = System.today()));
        Database.insert(refundsToInsert);

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

    }
    
    @isTest
    static void refundProcessorPositive(){
        List<blng__Refund__c> refunds = new List<blng__Refund__c>([SELECT id,Batch_Date__c, Settlement_Data__c,Sequential_Bank_ID__c FROM blng__Refund__c]);
        
        List<BankInformationSettlementProcessor.Request> requests = new List<BankInformationSettlementProcessor.Request>();
        BankInformationSettlementProcessor.Request request = new BankInformationSettlementProcessor.Request();

        List<BankSettlementRecord> bankSettlements = new List<BankSettlementRecord>();
        BankSettlementRecord bankSettlement = new BankSettlementRecord();

        bankSettlement.weWorkAccountNumber = 'wework123';
        bankSettlement.vendor = 'wework';
        bankSettlement.payToBankAccountNumber = '334567891';
        bankSettlements.add(bankSettlement);

        request.bankSettlementRecord = bankSettlements;
        request.refundRecord = refunds;
        request.category = 'Refunds';
        requests.add(request);
    
        Test.startTest();
        BankInformationSettlementProcessor.createBankInformationIntegration(requests);
        Test.stopTest();

        List<blng__Refund__c> refundCheck = new List<blng__Refund__c>([SELECT id,Settlement_Data__c,Sequential_Bank_Counter__c FROM blng__Refund__c where Sequential_Bank_ID__c!=null]);
        System.assertEquals(1, refundCheck.get(0).Sequential_Bank_Counter__c, 'Refund Settlement Data Not Correct');
    }   

    @isTest
    static void refundprocessorNegative(){
        List<blng__Refund__c> refunds = new List<blng__Refund__c>([SELECT id,Batch_Date__c, Settlement_Data__c,Sequential_Bank_Counter__c FROM blng__Refund__c]);
        
        List<BankInformationSettlementProcessor.Request> requests = new List<BankInformationSettlementProcessor.Request>();
        BankInformationSettlementProcessor.Request request = new BankInformationSettlementProcessor.Request();

        List<BankSettlementRecord> bankSettlements = new List<BankSettlementRecord>();
        BankSettlementRecord bankSettlement = new BankSettlementRecord();

        bankSettlement.weWorkAccountNumber = 'wework123';
        bankSettlement.vendor = 'wework';
        bankSettlement.payToBankAccountNumber = '334567891';
        bankSettlements.add(bankSettlement);

        request.bankSettlementRecord = bankSettlements;
        request.category = 'RefundsFail';
        requests.add(request);
    
        Test.startTest();
        BankInformationSettlementProcessor.createBankInformationIntegration(requests);
        Test.stopTest();

        List<blng__Refund__c> refundCheck = new List<blng__Refund__c>([SELECT id,Sequential_Bank_Counter__c,Settlement_Data__c,Sequential_Bank_ID__c FROM blng__Refund__c]);
        System.assertEquals(null, refundCheck.get(0).Sequential_Bank_Counter__c, 'Refund Settlement Correct');
    } 

    @isTest
    static void bankInformationProcessorPositive(){
        List<blng__Paymentmethod__c> paymentMethods = new List<blng__Paymentmethod__c>([SELECT id,Wire_Information__c FROM blng__Paymentmethod__c]);

        List<BankInformationSettlementProcessor.Request> requests = new List<BankInformationSettlementProcessor.Request>();
        BankInformationSettlementProcessor.Request request = new BankInformationSettlementProcessor.Request();

        List<BankAccountWireInformation> bankAccounts = new List<BankAccountWireInformation>();
        BankAccountWireInformation bankAccount = new BankAccountWireInformation();

        bankAccount.accountClosureDate = '2021/12/12';
        bankAccount.accountCurrency = 'USD';
        bankAccount.accountHideInList = 'SSD';
        bankAccount.accountId = '123456789';
        bankAccount.accountIdType = 'Integer';
        bankAccount.accountNumber = '334567891';
        bankAccount.action = 'Debit';
        bankAccount.bankCity = 'Los Angles';
        bankAccount.bankCountry = 'USA';
        bankAccount.bankName = 'FLS';
        bankAccount.bankOtherTypeId = '234567';
        bankAccount.bankPostal = 'GRE';
        bankAccount.beneficiaryCity = 'California';
        bankAccount.beneficiaryCountry = 'USA';
        bankAccount.beneficiaryName1 = 'Jhon';
        bankAccount.creditor = 'Smith';
        bankAccount.debitor = 'Jhon';
        bankAccount.defaultAccount = 'FLS';
            
        bankAccounts.add(bankAccount);

        request.bankWireRecord = bankAccounts;
        request.paymentMethodRecord = paymentMethods;
        request.category = 'PaymentMethods';
        requests.add(request);
    
        Test.startTest();
        BankInformationSettlementProcessor.createBankInformationIntegration(requests);
        Test.stopTest();

        List<blng__Paymentmethod__c> paymentMethodsCheck = new List<blng__Paymentmethod__c>([SELECT id,Wire_Information__c FROM blng__Paymentmethod__c]);
        System.assertEquals(true, paymentMethodsCheck.get(0).Wire_Information__c!=null, 'Refund Bank Information Data Not Correct');
    }  

    @isTest
    static void bankInformationProcessorNegative(){
        List<blng__Paymentmethod__c> paymentMethods = new List<blng__Paymentmethod__c>([SELECT id,Wire_Information__c FROM blng__Paymentmethod__c]);

        List<BankInformationSettlementProcessor.Request> requests = new List<BankInformationSettlementProcessor.Request>();
        BankInformationSettlementProcessor.Request request = new BankInformationSettlementProcessor.Request();

        List<BankAccountWireInformation> bankAccounts = new List<BankAccountWireInformation>();
        BankAccountWireInformation bankAccount = new BankAccountWireInformation();

        bankAccount.accountClosureDate = '2021/12/12';
        bankAccount.accountCurrency = 'USD';
        bankAccount.accountHideInList = 'SSD';
        bankAccount.accountId = '123456789';
        bankAccount.accountIdType = 'Integer';
        bankAccount.accountNumber = '334567891';
        bankAccount.action = 'Debit';
        bankAccount.bankCity = 'Los Angles';
        bankAccount.bankCountry = 'USA';
        bankAccount.bankName = 'FLS';
        bankAccount.bankOtherTypeId = '234567';
        bankAccount.bankPostal = 'GRE';
        bankAccount.beneficiaryCity = 'California';
        bankAccount.beneficiaryCountry = 'USA';
        bankAccount.beneficiaryName1 = 'Jhon';
        bankAccount.creditor = 'Smith';
        bankAccount.debitor = 'Jhon';
        bankAccount.defaultAccount = 'FLS';
            
        bankAccounts.add(bankAccount);

        request.bankWireRecord = bankAccounts;
        request.paymentMethodRecord = paymentMethods;
        request.category = 'PaymentMethodsFail';
        requests.add(request);
    
        Test.startTest();
        BankInformationSettlementProcessor.createBankInformationIntegration(requests);
        Test.stopTest();

        List<blng__Paymentmethod__c> paymentMethodsCheck = new List<blng__Paymentmethod__c>([SELECT id,Wire_Information__c FROM blng__Paymentmethod__c]);
        System.assertEquals(false, paymentMethodsCheck.get(0).Wire_Information__c!=null, 'Bank Information Data Correct');
    }  
}