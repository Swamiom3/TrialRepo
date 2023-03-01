@isTest
private class TermBasedDiscountQuoteLinesHelperTest {
    private static CPQTestUtils util = new CPQTestUtils();
    
    @testSetup
    static void testSetup() {
        util.setupCPQTestData();
    }
    
    @isTest
    static void testUpdateQuoteLines() {
        SBQQ__QuoteLine__c quoteLine = [SELECT Id,SBQQ__Product__r.ProductCode,Inventory_Id__r.UUID__c,SBQQ__RequiredBy__r.SBQQ__ProductFamily__c,
                                       SBQQ__Quote__r.SBQQ__PricebookId__c,SBQQ__Quote__c,Inventory_Id__r.Name,Commitment_Term__c,
                                       SBQQ__StartDate__c,SBQQ__Number__c,Promo_Code_Id__r.Name FROM SBQQ__QuoteLine__c LIMIT 1];
        
        Date startDate = System.today().addDays(10);
        TermCommitmentWrapper commitmentTermData = new TermCommitmentWrapper(new List<String>(), quoteLine.Commitment_Term__c);
        TermDiscountWrapper termDiscountWrap = new TermDiscountWrapper('PHYS-MBRSHP', quoteLine.Inventory_Id__r.Name, commitmentTermData, quoteLine, false, false);
        termDiscountWrap.startDate = startDate;
        
        TermBasedDiscountQuoteLinesHelper helper = new TermBasedDiscountQuoteLinesHelper();
        
        Test.startTest();
        helper.updateQuoteLines(new List<TermDiscountWrapper>{termDiscountWrap});
        Test.stopTest();

        quoteLine = [SELECT Id, SBQQ__StartDate__c, SBQQ__Number__c FROM SBQQ__QuoteLine__c WHERE Id = :quoteLine.Id];
        System.assert(quoteLine.SBQQ__StartDate__c == startDate, 'Failed to update StartDate on QuoteLine');
    }
    
    @isTest
    static void testAddOrRemoveQuoteLines() {
        Product2 prod = [SELECT Id,SBQQ__SubscriptionPricing__c,SBQQ__SubscriptionBase__c,SBQQ__SubscriptionTerm__c,SBQQ__ChargeType__c,SBQQ__SubscriptionType__c,
                         SBQQ__BillingType__c,SBQQ__BillingFrequency__c,Disable_Proration__c,Name,SBQQ__PriceEditable__c,ProductCode,Secondary_Sales_Item_UUID__c FROM Product2 LIMIT 1];
        SBQQ__QuoteLine__c quoteLine = [SELECT Id,SBQQ__RequiredBy__c,SBQQ__Product__c,SBQQ__Product__r.ProductCode,Inventory_Id__r.UUID__c,
                                       SBQQ__Quote__r.SBQQ__PricebookId__c,SBQQ__Quote__c,Inventory_Id__r.Name,Commitment_Term__c,Inventory_Id__c,Building_Id__c,
                                       SBQQ__StartDate__c,SBQQ__Number__c,Promo_Code_Id__r.Name,CurrencyIsoCode,SBQQ__EndDate__c,SBQQ__Quote__r.CurrencyIsoCode FROM SBQQ__QuoteLine__c LIMIT 1];
        
        TermCommitmentWrapper commitmentTermData = new TermCommitmentWrapper(new List<String>(), '2');
        TermDiscountWrapper termDiscountWrap = new TermDiscountWrapper('PHYS-MBRSHP', quoteLine.Inventory_Id__r.Name, commitmentTermData, quoteLine, false, false);
        termDiscountWrap.startDate = quoteLine.SBQQ__StartDate__c.addDays(1);
        
        TermBasedDiscountQuoteLinesHelper helper = new TermBasedDiscountQuoteLinesHelper();
        
        TermBasedDiscountController.productWithNumbers = new Map<Integer, Product2>{3 => prod, 2 => prod};
            
        SBQQ__ProductOption__c option = new SBQQ__ProductOption__c();
        String key1 = quoteLine.SBQQ__Product__c+'-'+'2';
        String key2 = quoteLine.SBQQ__Product__c+'-'+'3';
        TermBasedDiscountController.productOptionWithNumbers = new Map<String, SBQQ__ProductOption__c>{key1 => option, key2 => option};
        
        Test.startTest();
        helper.addOrRemoveQuoteLines(new List<TermDiscountWrapper>{termDiscountWrap});
        Test.stopTest();

        List<SBQQ__QuoteLine__c> quoteLines = [SELECT Id FROM SBQQ__QuoteLine__c WHERE Id != :quoteLine.Id];
        System.assert(!quoteLines.isEmpty(), 'Failed to create new Quote Lines');
    }
    
    @isTest
    static void testCreateQuoteLines() {
        Product2 prod = [SELECT Id,SBQQ__SubscriptionPricing__c,SBQQ__SubscriptionBase__c,SBQQ__SubscriptionTerm__c,SBQQ__ChargeType__c,SBQQ__SubscriptionType__c,
                         SBQQ__BillingType__c,SBQQ__BillingFrequency__c,Disable_Proration__c,Name,SBQQ__PriceEditable__c,ProductCode,Secondary_Sales_Item_UUID__c FROM Product2 LIMIT 1];
        SBQQ__QuoteLine__c quoteLine = [SELECT Id,SBQQ__RequiredBy__c,SBQQ__Product__c,SBQQ__Product__r.ProductCode,Inventory_Id__r.UUID__c,
                                       SBQQ__Quote__r.SBQQ__PricebookId__c,SBQQ__Quote__c,Inventory_Id__r.Name,Commitment_Term__c,Inventory_Id__c,Building_Id__c,
                                       SBQQ__StartDate__c,SBQQ__Number__c,Promo_Code_Id__r.Name,CurrencyIsoCode,SBQQ__EndDate__c,SBQQ__Quote__r.CurrencyIsoCode FROM SBQQ__QuoteLine__c LIMIT 1];
        
        TermCommitmentWrapper commitmentTermData = new TermCommitmentWrapper(new List<String>(), quoteLine.Commitment_Term__c);
        TermDiscountWrapper termDiscountWrap = new TermDiscountWrapper('PHYS-MBRSHP', quoteLine.Inventory_Id__r.Name, commitmentTermData, quoteLine, false, false);
        
        TermBasedDiscountQuoteLinesHelper helper = new TermBasedDiscountQuoteLinesHelper();
        TermBasedDiscountController.productWithNumbers = new Map<Integer, Product2>{1 => prod};
            
        SBQQ__ProductOption__c option = new SBQQ__ProductOption__c();
        String key = quoteLine.SBQQ__Product__c+'-'+'1';
        TermBasedDiscountController.productOptionWithNumbers = new Map<String, SBQQ__ProductOption__c>{key => option};
            
        Test.startTest();
        List<SBQQ__QuoteLine__c> quoteLines = helper.createQuoteLines(1, 0, termDiscountWrap);
        Test.stopTest();

        System.assert(!quoteLines.isEmpty(), 'Failed to create new Quote Lines');
        for(SBQQ__QuoteLine__c ql: quoteLines) {
            System.assert(ql.Inventory_Id__c == termDiscountWrap.quoteLineRecord.Inventory_Id__c, 'Failed to update Inventory Id on QuoteLine');
            System.assert(ql.Building_Id__c == termDiscountWrap.quoteLineRecord.Building_Id__c, 'Failed to update Building Id on QuoteLine');
        }
    }
    
    @isTest
    static void testGetParentQuoteLinesWithChilds() {
        SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        
        TermBasedDiscountQuoteLinesHelper helper = new TermBasedDiscountQuoteLinesHelper();
        
        Test.startTest();
        Map<Id,List<SBQQ__QuoteLine__c>> quoteLinesMap = helper.getParentQuoteLinesWithChilds(quote.Id);
        Test.stopTest();

        System.assert(quoteLinesMap.isEmpty(), 'Failed to test quote with 0 lines');
    }

    @isTest
    static void testProcessQuoteLinesToDelete() {
        SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        SBQQ__QuoteLine__c quoteLine = [SELECT Id, SBQQ__Quote__c, Commitment_Term__c, SBQQ__ProductCode__c, SBQQ__Product__r.Name, SBQQ__StartDate__c,
                                        Promo_Code_Id__r.Name FROM SBQQ__QuoteLine__c LIMIT 1];
        
        TermCommitmentWrapper commitmentTermData = new TermCommitmentWrapper(new List<String>(), quoteLine.Commitment_Term__c);
        TermDiscountWrapper termDiscountWrap = new TermDiscountWrapper('PHYS-MBRSHP', null, commitmentTermData, quoteLine, false, false);
        termDiscountWrap.promoName = null;
        termDiscountWrap.startDate = null;

        TermBasedDiscountQuoteLinesHelper helper = new TermBasedDiscountQuoteLinesHelper();
        Map<String,SBQQ__QuoteLine__c> quoteLinesToDelete = new Map<String,SBQQ__QuoteLine__c>();
        
        Test.startTest();
        helper.processQuoteLinesToDelete(termDiscountWrap, quoteLinesToDelete, 1);
        Test.stopTest();

        System.assert(quoteLinesToDelete.isEmpty(), 'Failed to test empty quotelines');
    }
}