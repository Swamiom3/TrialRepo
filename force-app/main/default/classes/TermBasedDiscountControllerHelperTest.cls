@isTest
private class TermBasedDiscountControllerHelperTest {
    private static CPQTestUtils util = new CPQTestUtils();
    
    @testSetup
    static void testSetup() {
        util.setupCPQTestData();
    }
    
    @isTest
    static void testProcessTermsAndProdNames() {
        SBQQ__QuoteLine__c quoteLine = [SELECT Id,SBQQ__RequiredBy__c,SBQQ__Product__r.ProductCode,Inventory_Id__r.UUID__c,SBQQ__RequiredBy__r.SBQQ__ProductFamily__c,
                                       SBQQ__Quote__r.SBQQ__PricebookId__c,SBQQ__Quote__c,Inventory_Id__r.Name,Commitment_Term__c,SBQQ__Product__c,
                                       SBQQ__StartDate__c,SBQQ__Number__c,Promo_Code_Id__r.Name FROM SBQQ__QuoteLine__c LIMIT 1];
        
        TermCommitmentWrapper commitmentTermData = new TermCommitmentWrapper(new List<String>{'6'}, quoteLine.Commitment_Term__c);
        TermDiscountWrapper termDiscountWrap = new TermDiscountWrapper('PHYS-MBRSHP', quoteLine.Inventory_Id__r.Name, commitmentTermData, quoteLine, false, false);
        
        TermBasedDiscountControllerHelper helper = new TermBasedDiscountControllerHelper();
        
        Test.startTest();
        List<Integer> commitmentTerms = helper.processTermsAndProdNames(new List<TermDiscountWrapper>{termDiscountWrap}, new List<String>(), new Map<Integer, Product2>());
        Test.stopTest();
        
        System.assert(!commitmentTerms.isEmpty(), 'Failed to get committerms');
        System.assert((new Set<Integer>(commitmentTerms)).contains(Integer.valueOf(commitmentTermData.commitmentTerm)+1), 'Failed to verify the commitment Term');
    }
    
    @isTest
    static void testProcessTermDiscountLines() {
        Product2 prod = [SELECT Id, Family FROM Product2 LIMIT 1];
        prod.Family = CPQConstants.ALL_ACCESS;
        update prod;
        
        SBQQ__QuoteLine__c quoteLine = [SELECT Id, SBQQ__Product__r.ProductCode, SBQQ__RequiredBy__c, SBQQ__ProductFamily__c, SBQQ__Quote__r.Subscription_Type__c, 
                                        SBQQSC__UpgradedContractLine__c, SBQQ__ProductName__c, Commitment_Term__c, SBQQ__StartDate__c, Promo_Code_Id__r.Name, 
                                        Inventory_Id__r.Name, QuoteLineSource__c FROM SBQQ__QuoteLine__c LIMIT 1];
        
        TermBasedDiscountControllerHelper helper = new TermBasedDiscountControllerHelper();
        
        Test.startTest();
        List<TermDiscountWrapper> termDiscountWrapperList = helper.processTermDiscountLines(new List<SBQQ__QuoteLine__c>{quoteLine}, new List<String>{'6'});
        Test.stopTest();
        
        System.assert(!termDiscountWrapperList.isEmpty(), 'Failed to create Term Discount wrappers');
        for(TermDiscountWrapper wrapper: termDiscountWrapperList) {
            System.assert(wrapper.quoteLineId == quoteLine.Id, 'Failed to verify Term Discount wrapper data');
        }
    }
    
    @isTest
    static void testProcessTermDiscountCommitLine() {
        SBQQ__QuoteLine__c quoteLine = [SELECT Id, SBQQ__Product__r.ProductCode, SBQQ__RequiredBy__c, SBQQ__ProductFamily__c, SBQQ__Quote__r.Subscription_Type__c, 
                                        SBQQSC__UpgradedContractLine__c, SBQQ__ProductName__c, Commitment_Term__c, SBQQ__StartDate__c, Promo_Code_Id__r.Name, 
                                        Inventory_Id__r.Name, QuoteLineSource__c FROM SBQQ__QuoteLine__c LIMIT 1];
        
        TermBasedDiscountControllerHelper helper = new TermBasedDiscountControllerHelper();
        
        Test.startTest();
        TermDiscountWrapper termDiscountWrapper = helper.processTermDiscountCommitLine(quoteLine, new List<String>{'6'});
        Test.stopTest();
        
        System.assert(termDiscountWrapper != null && termDiscountWrapper.displayItem == CPQConstants.PRODUCTCODE_COMMIT, 'Failed to verify Dispaly Item');
    }
    
    @isTest
    static void testProcessPricingDiscountForMonthSKU() {
        Product2 prod = [SELECT Id, Family FROM Product2 LIMIT 1];
        prod.Family = CPQConstants.ALL_ACCESS;
        update prod;
        
        SBQQ__QuoteLine__c quoteLine = [SELECT Id,SBQQ__RequiredBy__c,SBQQ__Product__r.ProductCode,Inventory_Id__r.UUID__c,SBQQ__RequiredBy__r.SBQQ__ProductFamily__c,
                                       SBQQ__Quote__r.SBQQ__PricebookId__c,SBQQ__Quote__c,Inventory_Id__r.Name,Commitment_Term__c,SBQQ__Product__c,
                                       SBQQ__StartDate__c,SBQQ__Number__c,Promo_Code_Id__r.Name, SBQQ__ProductCode__c FROM SBQQ__QuoteLine__c LIMIT 1];
        SBQQ__QuoteLine__c childLine = quoteLine.clone(false, true, false, false);
        childLine.SBQQ__RequiredBy__c = quoteLine.Id;
        insert childLine;
        
        childLine = [SELECT Id, SBQQ__RequiredBy__c, SBQQ__Product__r.ProductCode, Inventory_Id__r.List_Price__c, SBQQ__RequiredBy__r.SBQQ__EndDate__c, 
                     SBQQ__RequiredBy__r.SBQQ__ProductFamily__c, SBQQ__RequiredBy__r.SBQQ__ProductCode__c, SBQQ__RequiredBy__r.SBQQ__Product__c, 
                     SBQQ__Product__c, SBQQ__StartDate__c, SBQQ__Number__c,Promo_Code_Id__r.Name, SBQQ__ProductCode__c 
                     FROM SBQQ__QuoteLine__c WHERE Id =: childLine.Id];
        
        TermCommitmentWrapper commitmentTermData = new TermCommitmentWrapper(new List<String>{'6'}, '2');
        TermDiscountWrapper termDiscountWrap = new TermDiscountWrapper('PHYS-MBRSHP', quoteLine.Inventory_Id__r.Name, commitmentTermData, quoteLine, false, false);
        
        TermBasedDiscountControllerHelper helper = new TermBasedDiscountControllerHelper();
        PricebookEntry entry = new PricebookEntry(UnitPrice = 20);
        Id reqById = childLine.SBQQ__RequiredBy__r.SBQQ__Product__c;
        TermBasedDiscountController.productNameWithPriceBookEntries = new Map<String,PricebookEntry>{reqById => entry};
        
        Test.startTest();
        SBQQ__QuoteLine__c processedLine = helper.processPricingDiscountForMonthSKU(termDiscountWrap, childLine, 1, new Set<String>{quoteLine.SBQQ__ProductCode__c});
        Test.stopTest();
        
        System.assert(processedLine != null && processedLine.SBQQ__ListPrice__c == entry.UnitPrice, 'Failed to verify the List Price');
    }
}