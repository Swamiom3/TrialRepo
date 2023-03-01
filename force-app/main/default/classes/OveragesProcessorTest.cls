/*************************************************************************************************************************************
    Author      :   Tayo Chestnut
    Description :   This class provides sufficient test coverage for OveragesProcessor class
    --------------------------------------------------------------------------------------------------------------------------------------
    VERSION    DATE            AUTHOR             DETAIL
    1          16 Sep, 2021    Tayo Chestnut   Initial Deployment
**************************************************************************************************************************************/
@isTest
public with sharing class OveragesProcessorTest {
    
    
    @testSetup
    static void makeData(){
        Date startDate = Date.newInstance(2021, 12, 1);
        startDate.addDays(1);
        Date endDate = Date.newInstance(2021, 12, 25);
        
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
        
        Pricebook2 priceBook = new Pricebook2();
        priceBook.IsActive = true;
        priceBook.Name = 'Test Price Book';
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

        ConsumptionSchedule consumeSchedule = new ConsumptionSchedule();
        consumeSchedule.BillingTerm = 1;
        consumeSchedule.BillingTermUnit = 'Month';
        consumeSchedule.RatingMethod = 'Tier';
        consumeSchedule.SBQQ__Category__c = 'Rates';
        consumeSchedule.blng__BillingRule__c = billingRule.Id;
        consumeSchedule.blng__RevenueRecognitionRule__c = revRecRule.Id;
        consumeSchedule.blng__TaxRule__c = taxRule.Id;        
        consumeSchedule.Name = 'Test Schedule';
        consumeSchedule.Type = 'Range';
        insert consumeSchedule;

        ConsumptionRate rates = new ConsumptionRate();
        rates.ConsumptionScheduleId = consumeSchedule.Id;
        rates.Price = 25;
        rates.ProcessingOrder = 1;
        rates.LowerBound = 1;
        rates.PricingMethod = 'PerUnit';
        rates.CurrencyIsoCode = 'CAD';
        insert rates;

        consumeSchedule.isActive = true;
        update consumeSchedule;

        Product2 product = new Product2();
        product.Name = 'Test Product';
        product.ProductCode = 'TEST-PRO';
        product.blng__BillingRule__c = billingRule.Id;
        product.blng__RevenueRecognitionRule__c = revRecRule.Id;
        product.blng__TaxRule__c = taxRule.Id;
        product.Product_UUID__c = UUIDHandler.generateVersion4();
        insert product;

        ProductConsumptionSchedule productConsume = new ProductConsumptionSchedule();
        productConsume.ConsumptionScheduleId = consumeSchedule.Id;
        productConsume.ProductId = product.Id;
        insert productConsume;

        Order orderToCreate = new Order();
        orderToCreate.Building_Account_Id__c = buildingAccount.Id;
        orderToCreate.blng__BillingDayOfMonth__c = '1';
        orderToCreate.AccountId = testAccount.Id;
        orderToCreate.Building_Id__c = buildingsToInsert.get(0).Id;
        orderToCreate.Status = 'Draft';
        orderToCreate.EffectiveDate = System.today();
        orderToCreate.Pricebook2Id = priceBook.Id;
        orderToCreate.EffectiveDate = startDate;
        insert orderToCreate;

        PricebookEntry standardPriceEntry = new PricebookEntry();
        standardPriceEntry.Product2Id = product.Id;
        standardPriceEntry.IsActive = true;
        standardPriceEntry.UnitPrice = 20;
        standardPriceEntry.Pricebook2Id = test.getStandardPricebookId();
        insert standardPriceEntry;
        
        PricebookEntry customPriceEntry = new PricebookEntry();
        customPriceEntry.IsActive = true;
        customPriceEntry.UnitPrice = 30;
        customPriceEntry.Product2Id = product.Id;
        customPriceEntry.Pricebook2Id = priceBook.Id;
        insert customPriceEntry;
        
        OrderItem item = new OrderItem();
        item.OrderId = orderToCreate.Id;
        item.Product2Id = product.Id;
        item.SBQQ__ChargeType__c = 'Usage';
        item.PricebookEntryId = customPriceEntry.Id;
        item.UnitPrice = 30;
        item.SBQQ__Activated__c = false;
        item.Quantity = 1;
        item.ServiceDate = startDate;
        item.EndDate = endDate;
        insert item;

        SBQQ__OrderItemConsumptionSchedule__c orderConsumeSchedule = new SBQQ__OrderItemConsumptionSchedule__c();
        orderConsumeSchedule.SBQQ__BillingTerm__c = 1;
        orderConsumeSchedule.SBQQ__BillingTermUnit__c = 'Month';
        orderConsumeSchedule.SBQQ__RatingMethod__c = 'Tier';
        orderConsumeSchedule.SBQQ__Category__c = 'Rates';   
        orderConsumeSchedule.Name = 'Test Schedule';
        orderConsumeSchedule.SBQQ__Type__c = 'Range';
        orderConsumeSchedule.SBQQ__OrderItem__c = item.Id;
        orderConsumeSchedule.SBQQ__ConsumptionSchedule__c = consumeSchedule.Id;
        insert orderConsumeSchedule;
        
        SBQQ__OrderItemConsumptionRate__c orderConsumeRate = new SBQQ__OrderItemConsumptionRate__c();
        orderConsumeRate.CurrencyIsoCode = 'CAD';
        orderConsumeRate.SBQQ__LowerBound__c = 1;
        orderConsumeRate.SBQQ__Price__c = 25;
        orderConsumeRate.SBQQ__ProcessingOrder__c = 1;
        orderConsumeRate.SBQQ__PricingMethod__c = 'PerUnit';
        orderConsumeRate.SBQQ__OrderItemConsumptionSchedule__c = orderConsumeSchedule.Id;
        insert orderConsumeRate;

        blng__UsageSummary__c summaryUsage = new blng__UsageSummary__c();
        summaryUsage.blng__OrderItemConsumptionSchedule__c = orderConsumeSchedule.Id;
        summaryUsage.blng__OrderProduct__c = item.Id;
        summaryUsage.blng__Account__c = testAccount.Id;
        summaryUsage.blng__Order__c = orderToCreate.Id;
        summaryUsage.blng__SummaryStartDate__c = startDate;
        summaryUsage.blng__SummaryEndDate__c = endDate;
        insert summaryUsage;

    }
    
    @isTest
    static void overagePositive(){
        blng__UsageSummary__c summaryRecord = [Select id from blng__UsageSummary__c LIMIT 1];
        List<OverageCredits> myCredits = new List<OverageCredits>();
        OverageCredits myCredit = new OverageCredits();
        myCredit.quantity = 2;
        myCredit.startedOn = Date.newInstance(2021, 12, 14); 
        myCredit.endedOn = Date.newInstance(2021, 12, 24);
        myCredit.currencyCode = 'CAD';
        myCredit.paymentType = null;
        myCredit.price = 20;
        myCredit.id = summaryRecord.Id;
        myCredit.reservableUUID = 'TEST-PRO';
        myCredit.accountUUID = '454545';
        myCredit.locationUUID = 'abcdefg';
        myCredits.add(myCredit);

        Map<String,Object> inputs = new Map<String, Object>();
        
        OverageParameters parameter = new OverageParameters();
        parameter.accountUUID = '454545';
        parameter.locationUUID = 'abcdefg';

        inputs.put('results', myCredits);
        inputs.put('params', parameter);

        Test.startTest();
        Flow.Interview.Overages_Endpoint overagesProcessFlow = new Flow.Interview.Overages_Endpoint(inputs);
        overagesProcessFlow.start();
        Test.stopTest();
        
        String message = (String) overagesProcessFlow.getVariableValue('errormessage');
        System.assertEquals('Payload Verified', message,'Overages Not Processed Successfully');
    }
    
    @isTest
    static void overageNegativeAccountNoMatch(){
        blng__UsageSummary__c summaryRecord = [Select id from blng__UsageSummary__c LIMIT 1];
        List<OverageCredits> myCredits = new List<OverageCredits>();
        OverageCredits myCredit = new OverageCredits();
        myCredit.quantity = 2;
        myCredit.startedOn = Date.newInstance(2021, 12, 14); 
        myCredit.endedOn = Date.newInstance(2021, 12, 24);
        myCredit.currencyCode = 'CAD';
        myCredit.paymentType = null;
        myCredit.price = 20;
        myCredit.id = summaryRecord.Id;
        myCredit.reservableUUID = 'TEST-PRO';
        myCredit.accountUUID = '45454';
        myCredit.locationUUID = 'abcdefg';
        myCredits.add(myCredit);

        Map<String,Object> inputs = new Map<String, Object>();
        
        OverageParameters parameter = new OverageParameters();
        parameter.accountUUID = '45454';
        parameter.locationUUID = 'abcdefg';

        inputs.put('results', myCredits);
        inputs.put('params', parameter);

        Test.startTest();
        Flow.Interview.Overages_Endpoint overagesProcessFlow = new Flow.Interview.Overages_Endpoint(inputs);
        overagesProcessFlow.start();
        Test.stopTest();
        String message = (String) overagesProcessFlow.getVariableValue('errormessage');
        System.assertEquals('Unable to find Account from UUID', message, 'Account Found');
    }
    
    @IsTest
    static void overageNegativeBuildingNoMatch(){
        blng__UsageSummary__c summaryRecord = [Select id from blng__UsageSummary__c LIMIT 1];
        List<OverageCredits> myCredits = new List<OverageCredits>();
        OverageCredits myCredit = new OverageCredits();
        myCredit.quantity = 2;
        myCredit.startedOn = Date.newInstance(2021, 12, 14); 
        myCredit.endedOn = Date.newInstance(2021, 12, 24);
        myCredit.currencyCode = 'CAD';
        myCredit.paymentType = null;
        myCredit.id = summaryRecord.Id;
        myCredit.price = 20;
        myCredit.reservableUUID = 'TEST-PRO';
        myCredit.accountUUID = '454545';
        myCredit.locationUUID = 'abcdef';
        myCredits.add(myCredit);

        Map<String,Object> inputs = new Map<String, Object>();
        
        OverageParameters parameter = new OverageParameters();
        parameter.accountUUID = '454545';
        parameter.locationUUID = 'abcdef';

        inputs.put('results', myCredits);
        inputs.put('params', parameter);

        Test.startTest();
        Flow.Interview.Overages_Endpoint overagesProcessFlow = new Flow.Interview.Overages_Endpoint(inputs);
        overagesProcessFlow.start();
        Test.stopTest();

        String message = (String) overagesProcessFlow.getVariableValue('errormessage');
        System.assertEquals('Unable to Find Building from Location UUID', message, 'Building Found');
    }
}