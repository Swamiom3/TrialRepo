/*************************************************************************************************************************************
    Author      :   Tayo Chestnut
    Description :   This class provides sufficient test coverage for InvocableAggregateQueryProcessor class
    --------------------------------------------------------------------------------------------------------------------------------------
    VERSION    DATE            AUTHOR             DETAIL
    1          23 Feb, 2022    Tayo Chestnut   Initial Deployment
**************************************************************************************************************************************/
@isTest
public with sharing class InvocableAggregateQueryProcessorTest {
    @testSetup
    static void makeData(){
        Date startDate = Date.newInstance(2021, 12, 1);
        Date endDate = Date.newInstance(2021, 12, 31);
        
        Account testAccount = new Account();
        testAccount.Name = 'Test_Account';
        testAccount.UUId__c = '454545';
        insert testAccount;

        blng__LegalEntity__c legalEntity = new blng__LegalEntity__c();
        legalEntity.Name = 'Test Legal Entity';
        legalEntity.CurrencyIsoCode = 'CAD';
        insert legalEntity;

        List<Building__c> buildingsToInsert = new List<Building__c>();
        buildingsToInsert.add(UtilBuilding.createBuilding(null, 'test@test.com', null, false));
        buildingsToInsert.get(0).WeCode__c = 'ABC';
        buildingsToInsert.get(0).UUID__c = 'abcdefg';
        buildingsToInsert.get(0).Legal_Entity_Id__c = legalEntity.Id;
        buildingsToInsert.get(0).currencyIsoCode = 'CAD';
        buildingsToInsert.get(0).Country__c = 'Canada';
        insert buildingsToInsert;

        Building_Account__c buildingAccount = new Building_Account__c();
        buildingAccount.Billing_Account_Id__c = testAccount.Id;
        buildingAccount.Building_Id__c = buildingsToInsert.get(0).Id;
        insert buildingAccount;
        
        Pricebook2 priceBook = new Pricebook2();
        priceBook.IsActive = true;
        priceBook.Name = 'Test Price Book';
        priceBook.CurrencyISOCode = 'CAD';
        insert priceBook;
        
        blng__BillingRule__c billingRule = new blng__BillingRule__c();
        billingRule.Name = 'Test Billing Rule';
        billingRule.blng__InitialBillingTrigger__c = 'Order Product Activation Date';
        billingRule.blng__PartialPeriodTreatment__c = 'Separate';
        billingRule.blng__PeriodTreatmentForBTDO__c = 'Exclude Billing Day of Month';
        billingRule.blng__GenerateInvoices__c = 'Yes';
        insert billingRule;

        blng__RevenueRecognitionRule__c revRecRule = new blng__RevenueRecognitionRule__c();
        revRecRule.blng__Active__c = true;
        revRecRule.Name = 'TestRevRec';
        revRecRule.blng__CreateRevenueSchedule__c = 'No';
        insert revRecRule;

        blng__TaxRule__c taxRule = new blng__TaxRule__c();
        taxRule.blng__Active__c = true;
        taxRule.Name = 'Test Tax Rule';
        taxRule.blng__TaxableYesNo__c = 'No';
        insert taxRule;

        Product2 product = new Product2();
        product.Name = 'Physical Membrership';
        product.ProductCode = CPQConstants.PRODUCTCODE_COMMIT;
        product.Family = 'Workspace';
        product.blng__BillingRule__c = billingRule.Id;
        product.blng__RevenueRecognitionRule__c = revRecRule.Id;
        product.blng__TaxRule__c = taxRule.Id;
        product.Product_UUID__c = UUIDHandler.generateVersion4();
        insert product;

        Product2 productConferenceRoom = new Product2();
        productConferenceRoom.Name = 'Conference Room Credit';
        productConferenceRoom.ProductCode = CPQConstants.PRODUCTCODE_COMMIT;
        productConferenceRoom.blng__BillingRule__c = billingRule.Id;
        productConferenceRoom.blng__RevenueRecognitionRule__c = revRecRule.Id;
        productConferenceRoom.blng__TaxRule__c = taxRule.Id;
        productConferenceRoom.Product_UUID__c = UUIDHandler.generateVersion4();
        insert productConferenceRoom;

        Order orderToCreate = new Order();
        orderToCreate.Building_Account_Id__c = buildingAccount.Id;
        orderToCreate.blng__BillingDayOfMonth__c = '1';
        orderToCreate.AccountId = testAccount.Id;
        orderToCreate.Building_Id__c = buildingsToInsert.get(0).Id;
        orderToCreate.Status = 'Draft';
        orderToCreate.Pricebook2Id = priceBook.Id;
        orderToCreate.EffectiveDate = startDate;
        orderToCreate.CurrencyISOCode = 'CAD';

        insert orderToCreate;

        PricebookEntry standardPriceEntry = new PricebookEntry();
        standardPriceEntry.Product2Id = product.Id;
        standardPriceEntry.IsActive = true;
        standardPriceEntry.UnitPrice = 30;
        standardPriceEntry.Pricebook2Id = test.getStandardPricebookId();
        standardPriceEntry.CurrencyISOCode = 'CAD';
        insert standardPriceEntry;
        
        PricebookEntry customPriceEntry = new PricebookEntry();
        customPriceEntry.IsActive = true;
        customPriceEntry.UnitPrice = 30;
        customPriceEntry.Product2Id = product.Id;
        customPriceEntry.Pricebook2Id = priceBook.Id;
        customPriceEntry.CurrencyISOCode = 'CAD';
        insert customPriceEntry;
        
        PricebookEntry standardPriceEntryCredit = new PricebookEntry();
        standardPriceEntryCredit.Product2Id = productConferenceRoom.Id;
        standardPriceEntryCredit.IsActive = true;
        standardPriceEntryCredit.UnitPrice = 0;
        standardPriceEntryCredit.Pricebook2Id = test.getStandardPricebookId();
        standardPriceEntryCredit.CurrencyISOCode = 'CAD';
        insert standardPriceEntryCredit;
        
        PricebookEntry customPriceEntryCredit = new PricebookEntry();
        customPriceEntryCredit.IsActive = true;
        customPriceEntryCredit.UnitPrice = 0;
        customPriceEntryCredit.Product2Id = productConferenceRoom.Id;
        customPriceEntryCredit.Pricebook2Id = priceBook.Id;
        customPriceEntryCredit.CurrencyISOCode = 'CAD';
        insert customPriceEntryCredit;

        OrderItem item = new OrderItem();
        item.OrderId = orderToCreate.Id;
        item.Building_Account_Id__c = buildingAccount.Id;
        item.Product2Id = product.Id;
        item.SBQQ__ChargeType__c = 'Recurring';
        item.PricebookEntryId = customPriceEntry.Id;
        item.UnitPrice = 30;
        item.blng__BillableUnitPrice__c = 30;
        item.SBQQ__Activated__c = false;
        item.SBQQ__SubscriptionTerm__c = 1;
        item.Quantity = 1;
        item.ServiceDate = startDate;
        item.EndDate = endDate;
        item.SBQQ__BillingFrequency__c = 'Monthly';
        item.SBQQ__BillingType__c = 'Advance';
        item.SBQQ__ProrateMultiplier__c = 1;
        insert item;

        List<blng__Invoice__c> invs = new List<blng__Invoice__c>();
        invs.add(new blng__Invoice__c(blng__Account__c = testAccount.Id,
                                    Building_Account_Id__c = buildingAccount.Id,
                                    blng__InvoiceStatus__c = 'Draft',
                                    Invoice_Type__c = 'Standard',
                                    CurrencyISOCode = 'CAD',
                                    blng__InvoiceDate__c = System.today(),
                                    Building_Id__c = buildingsToInsert.get(0).Id,
                                    blng__Order__c = orderToCreate.Id,
                                    blng__DueDate__c = System.today().addDays(-5)));
        Database.insert(invs);

        blng__InvoiceLine__c invoiceLineToAdd = new blng__InvoiceLine__c();
        invoiceLineToAdd.blng__Invoice__c = invs.get(0).Id;
        invoiceLineToAdd.blng__Product__c = product.Id;
        invoiceLineToAdd.blng__OrderProduct__c = item.Id;
        invoiceLineToAdd.blng__Quantity__c = 1;
        invoiceLineToAdd.blng__Subtotal__c = 30;
        invoiceLineToAdd.blng__TotalAmount__c = 30;
        invoiceLineToAdd.blng__TaxRule__c = taxRule.Id;
        invoiceLineToAdd.blng__BillingRule__c = billingRule.Id;
        invoiceLineToAdd.blng__ChargeType__c = 'Recurring';
        invoiceLineToAdd.CurrencyIsoCode = 'CAD';
        invoiceLineToAdd.blng__StartDate__c = System.today();
        invoiceLineToAdd.Building_Account_Id__c = buildingAccount.Id;
        invoiceLineToAdd.blng__LegalEntityReference__c = legalEntity.Id;

        insert invoiceLineToAdd;

        blng__Payment__c paymentToTest = new blng__Payment__c();
        paymentToTest.blng__Account__c = testAccount.Id;
        paymentToTest.blng__Amount__c = 100;
        paymentToTest.blng__PaymentDate__c = System.today();
        paymentToTest.blng__Status__c = 'Posted';
        paymentToTest.blng__Invoice__c = invs.get(0).Id;
        paymentToTest.CurrencyISOCode = 'CAD';
        insert paymentToTest;

        SBQQ__Quote__c quote = new SBQQ__Quote__c(
            Building_Id__c = buildingsToInsert.get(0).Id,
            Billing_Account__c = testAccount.Id,
            SBQQ__PricebookId__c = test.getStandardPricebookId(),
            SBQQ__Account__c = testAccount.Id,
            CurrencyIsoCode = 'CAD'
        );
        insert quote;
        
        SBQQ__QuoteLine__c quoteLine1 = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = quote.Id,
            SBQQ__Product__c = productConferenceRoom.Id,
            Building_Id__c = buildingsToInsert.get(0).Id,
            SBQQ__StartDate__c = System.today(),
            Commitment_Term__c = '1',
            SBQQ__Number__c = 1
        );
        insert quoteLine1;

        ServiceContract serviceContract = new ServiceContract(
            Name = 'Test Service Contract',
            AccountId = testAccount.Id,
            SBQQSC__Quote__c = quote.Id,
            StartDate = System.Now().date(),
            EndDate = System.Now().date() + 10,
            Pricebook2Id = test.getStandardPricebookId(),
            SBQQSC__PreserveBundleStructureUponRenewals__c = true,
            CurrencyIsoCode = 'CAD'
        );
        insert serviceContract;
        
        ContractLineItem contractLineItem = new ContractLineItem(
            UnitPrice = 0,
            Quantity = 1,
            SBQQSC__Account__c = testAccount.Id,
            Allotment__c = 100,
            StartDate = System.Now().date(),
            EndDate = System.Now().date() + 10,
            ServiceContractId = serviceContract.Id,
            SBQQSC__QuoteLine__c = quoteLine1.Id,
            PricebookEntryId = standardPriceEntryCredit.Id,
            SBQQSC__Product__c = productConferenceRoom.Id
        );
        insert contractLineItem;
    }

    @isTest
    static void monthlyRunRateTestPositive(){
        Building_Account__c buildingAccount = [SELECT Id FROM Building_Account__c LIMIT 1];
        List<InvocableAggregateQueryProcessor.Request> invocableRequests = new List<InvocableAggregateQueryProcessor.Request>();
        InvocableAggregateQueryProcessor.Request invocableRequest = new InvocableAggregateQueryProcessor.Request();
        invocableRequest.buildingAccountId = buildingAccount.Id;
        invocableRequest.soqlCategory = 'Monthly Run Rate';
        invocableRequests.add(invocableRequest);

        Decimal finalRunRate = 30;

        List<InvocableAggregateQueryProcessor.Output> myOutput = InvocableAggregateQueryProcessor.executeRevenueCloudQuery(invocableRequests);
        System.assertEquals(finalRunRate.setScale(2), myOutput.get(0).runRate, 'Invalid Run Rate');

    }

    @isTest
    static void onAccountTestPositive(){
        Building_Account__c buildingAccount = [SELECT Id FROM Building_Account__c LIMIT 1];
        List<InvocableAggregateQueryProcessor.Request> invocableRequests = new List<InvocableAggregateQueryProcessor.Request>();
        InvocableAggregateQueryProcessor.Request invocableRequest = new InvocableAggregateQueryProcessor.Request();
        invocableRequest.buildingAccountId = buildingAccount.Id;
        invocableRequest.soqlCategory = 'On Account';
        invocableRequests.add(invocableRequest);
        
        Decimal finalBalance = 100;
        List<InvocableAggregateQueryProcessor.Output> myOutput = InvocableAggregateQueryProcessor.executeRevenueCloudQuery(invocableRequests);
        System.assertEquals(finalBalance.setScale(2), myOutput.get(0).onAccountBalance, 'Invalid On Account Amount');

    }

    @isTest
    static void onCreditAllotmentPositive(){
        Account billingAccount = [SELECT Id FROM Account LIMIT 1];
        List<InvocableAggregateQueryProcessor.Request> invocableRequests = new List<InvocableAggregateQueryProcessor.Request>();
        InvocableAggregateQueryProcessor.Request invocableRequest = new InvocableAggregateQueryProcessor.Request();
        invocableRequest.billingAccountId = billingAccount.Id;
        invocableRequest.soqlCategory = 'Credit Allotments';
        invocableRequests.add(invocableRequest);
        
        
        List<InvocableAggregateQueryProcessor.Output> myOutput = InvocableAggregateQueryProcessor.executeRevenueCloudQuery(invocableRequests);
        System.assertEquals(100, myOutput.get(0).conferenceRoomAllotment, 'Invalid CreditAmount');

    }

    @isTest
    static void onInvoiceBalancesTestPositive(){
        Building_Account__c buildingAccount = [SELECT Id FROM Building_Account__c LIMIT 1];
        blng__Invoice__c invoiceToPost = [SELECT Id,blng__InvoiceStatus__c FROM blng__Invoice__c LIMIT 1];
        invoiceToPost.blng__InvoiceStatus__c = InvoiceConstants.POSTED;
        update invoiceToPost;

        List<InvocableAggregateQueryProcessor.Request> invocableRequests = new List<InvocableAggregateQueryProcessor.Request>();
        InvocableAggregateQueryProcessor.Request invocableRequest = new InvocableAggregateQueryProcessor.Request();
        invocableRequest.buildingAccountId = buildingAccount.Id;
        invocableRequest.soqlCategory = 'Invoice Balances';
        invocableRequests.add(invocableRequest);
        
        
        Decimal finalBalance = 30;
        List<InvocableAggregateQueryProcessor.Output> myOutput = InvocableAggregateQueryProcessor.executeRevenueCloudQuery(invocableRequests);
        List<InvoiceTotals> testTotals = myOutput.get(0).invoiceTotals;
        System.assertEquals(finalBalance.setScale(2), testTotals.get(0).amount, 'Invalid Invoice Balance');

    }

    @isTest
    static void onNoMatch(){
        Building_Account__c buildingAccount = [SELECT Id FROM Building_Account__c LIMIT 1];
        List<InvocableAggregateQueryProcessor.Request> invocableRequests = new List<InvocableAggregateQueryProcessor.Request>();
        InvocableAggregateQueryProcessor.Request invocableRequest = new InvocableAggregateQueryProcessor.Request();
        invocableRequest.buildingAccountId = buildingAccount.Id;
        invocableRequest.soqlCategory = 'Invoice Balances';
        invocableRequests.add(invocableRequest);
        
        List<InvocableAggregateQueryProcessor.Output> myOutput = InvocableAggregateQueryProcessor.executeRevenueCloudQuery(invocableRequests);
        List<InvoiceTotals> testTotals = myOutput.get(0).invoiceTotals;
        System.assertEquals(0, testTotals.size(), 'Invoices Found');

    }
}