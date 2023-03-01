@isTest
public with sharing class OpportunityPrimaryQuoteUpdatesTrHTest {
      @testSetup
      static void setup() {
        OperatingHours operatingHour = new OperatingHours(Name = 'EDT: Standard 9AM - 5PM Weekday');
        insert operatingHour;

        blng__LegalEntity__c legalEntity = new blng__LegalEntity__c();
        legalEntity.Name = 'Test Legal Entity 1';
        legalEntity.CurrencyIsoCode = 'CAD';
        insert legalEntity;
        
        Building__c building = new Building__c();
        building.Name ='testbuild-001';
        building.Building_ID__c ='test';
        building.UUID__c ='test';
        building.Legal_Entity_Id__c = legalEntity.Id;
        insert building;  
        
        Account account = new Account(Name='test');
        insert account;
        
        blng__BillingRule__c billingRule = new blng__BillingRule__c();
        billingRule.Name = 'Invoice Test Rule';
        billingRule.blng__InitialBillingTrigger__c = 'Order Product Activation Date';
        billingRule.blng__PartialPeriodTreatment__c = 'Combine';
        billingRule.blng__PeriodTreatmentForBTDO__c = 'Combine';
        billingRule.blng__GenerateInvoices__c = 'Yes';
        insert billingRule;
        
        blng__RevenueRecognitionRule__c revenueRecognitionRule = new blng__RevenueRecognitionRule__c();
        revenueRecognitionRule.Name = 'Revenue Recognition Rule Test';
        revenueRecognitionRule.blng__CreateRevenueSchedule__c = 'No';
        insert revenueRecognitionRule;
        
        blng__TaxRule__c taxRule = new blng__TaxRule__c();
        taxRule.Name = 'Tax Rule Test';
        taxRule.blng__TaxableYesNo__c = 'No';
        insert taxRule;
        
        Product2 product = new Product2();
        product.Name = 'Commitment WorkSpace test';
        product.IsActive = true;
        product.ProductCode='COMMIT-WRKSPC TEST';
        product.SBQQ__ChargeType__c='One-Time';//,SBQQ__BillingType__c='Advance', SBQQ__BillingFrequency__c='Monthly');
        product.blng__BillingRule__c = billingRule.Id;
        product.blng__RevenueRecognitionRule__c = revenueRecognitionRule.Id;
        product.blng__TaxRule__c = taxRule.Id;
        product.Product_UUID__c = 'Product 1';
        insert product;
        
        Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        update standardPricebook;
        
        PricebookEntry pricebookEntry = new PricebookEntry(
            Pricebook2Id = standardPricebook.Id,
            Product2Id = product.Id,
            UnitPrice = 1020,
            IsActive = true
        );
        insert pricebookEntry;
        
        List<Opportunity> oldOpportunities = UtilOpportunity.getNewOpportunity(1,new Account(),true);
        SBQQ__Quote__c quote = new SBQQ__Quote__c();
        quote.Building_Id__c =building.Id;
        quote.Subscription_Type__c ='Commitment Term';
        quote.SBQQ__Opportunity2__c = oldOpportunities[0].Id;
        quote.SBQQ__Account__c =account.Id;
        quote.SBQQ__PriceBook__c = standardPricebook.Id;      
        quote.SBQQ__PricebookId__c  = standardPricebook.Id;     
        quote.SBQQ__ProrationDayOfMonth__c = '1';
        insert quote;
        
        SBQQ__QuoteLine__c quoteLine = new SBQQ__QuoteLine__c();
        quoteLine.SBQQ__Quote__c =quote.Id;
        quoteLine.SBQQ__Product__c =product.Id;
        quoteLine.Building_Id__c =building.Id;
        quoteLine.SBQQ__StartDate__c =system.today();
        quoteLine.Commitment_Term__c ='1';
        quoteLine.SBQQ__Number__c =1;
        quoteLine.SBQQ__Quantity__c =1;        
        quoteLine.SBQQ__PricebookEntryId__c =pricebookEntry.Id;
        quoteLine.SBQQ__ChargeType__c='One-Time';
        insert quoteLine;
        
        quote.SBQQ__PriceBook__c=standardPricebook.Id;
        quote.SBQQ__Primary__c=true;
        quote.In_Policy_Move_Out__c = true;
        update quote;
    }

    @isTest
    private static void testPositiveOpportunityPrimaryQuoteUpdates() {   
        List<Opportunity> oldOpportunities = [SELECT Id, StageName, SBQQ__PrimaryQuote__c FROM Opportunity limit 1]; 
        List<SBQQ__Quote__c> quotes = [SELECT Id, SBQQ__Ordered__c FROM SBQQ__Quote__c limit 1];
        PriceBook2 priceBook = [SELECT Id FROM PriceBook2 limit 1];
        
        List<Opportunity> newOpportunities = new List<Opportunity>();
        Opportunity opportunity = new Opportunity();
        opportunity.Id = oldOpportunities[0].Id;
        opportunity.SBQQ__PrimaryQuote__c = quotes.get(0).Id;
        opportunity.Pricebook2Id = priceBook.Id;
        opportunity.StageName ='Closed Won';
        newOpportunities.add(opportunity);           
                
        OpportunityPrimaryQuoteUpdatesTrH oppUpdPrimaryQuote = new OpportunityPrimaryQuoteUpdatesTrH(newOpportunities, new Map<Id, Opportunity>(oldOpportunities));
        Test.startTest();
        oppUpdPrimaryQuote.getClosedWonOppPrimaryQuotes();
        oppUpdPrimaryQuote.updateOrderOnOpportunityPrimaryQuote();
        List<SBQQ__Quote__c> quote = [SELECT Id, SBQQ__Ordered__c FROM SBQQ__Quote__c WHERE Id =: newOpportunities.get(0).SBQQ__PrimaryQuote__c];
        System.assertEquals(true, quote.get(0).SBQQ__Ordered__c, 'Quote should have Ordered checkbox checked');
        Test.stopTest();
    }
    
    @isTest
    private static void testNegativeOpportunityPrimaryQuoteUpdates() {   
        List<Opportunity> oldOpportunities = [SELECT Id, StageName, SBQQ__PrimaryQuote__c FROM Opportunity limit 1]; 
        List<SBQQ__Quote__c> quotes = [SELECT Id, SBQQ__Ordered__c FROM SBQQ__Quote__c limit 1];
        PriceBook2 priceBook = [SELECT Id FROM PriceBook2 limit 1];  
        
        List<Opportunity>  newOpportunities = new List<Opportunity>();
        Opportunity opportunity = new Opportunity();
        opportunity.Id = oldOpportunities[0].Id;
        opportunity.SBQQ__PrimaryQuote__c =quotes.get(0).Id;
        opportunity.Pricebook2Id = priceBook.Id;
        newOpportunities.add(opportunity); 
                
        OpportunityPrimaryQuoteUpdatesTrH oppUpdPrimaryQuote = new OpportunityPrimaryQuoteUpdatesTrH(newOpportunities, new Map<Id, Opportunity>(oldOpportunities));
        Test.startTest();
        oppUpdPrimaryQuote.getClosedWonOppPrimaryQuotes();
        oppUpdPrimaryQuote.updateOrderOnOpportunityPrimaryQuote();
        List<SBQQ__Quote__c> quote = [SELECT Id, SBQQ__Ordered__c FROM SBQQ__Quote__c WHERE Id =: newOpportunities.get(0).SBQQ__PrimaryQuote__c];
        System.assertEquals(false, quote.get(0).SBQQ__Ordered__c, 'Ordered checkbox on quote will not be updated');
        Test.stopTest();
    }  
}