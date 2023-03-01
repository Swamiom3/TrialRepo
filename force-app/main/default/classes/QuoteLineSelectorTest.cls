/*************************************************************************************************************************************
Author      :   Salesforce
Description :   This class provides sufficient test coverage for QUoteSelector class
--------------------------------------------------------------------------------------------------------------------------------------
VERSION         DATE            AUTHOR              DETAIL
1               7/21/2021       Salesforce         Initial Deployment
**************************************************************************************************************************************/
@isTest
private class QuoteLineSelectorTest {
    private static QuoteLineSelector quoteLineSelector = new QuoteLineSelector();
    
    @testSetup 
    static void setup() {
        OperatingHours objOpHour = new OperatingHours(Name = 'EDT: Standard 9AM - 5PM Weekday');
        insert objOpHour;
        Building__c building = new Building__c();
        building.Name = 'testbuild-001';
        building.Building_ID__c = 'test';
        building.UUID__c ='test';
        building.Time_Zone__c ='America/Denver';
        insert building;
        
        SBQQ__Quote__c quote = new SBQQ__Quote__c();
        quote.Building_Id__c = building.Id;
        quote.Subscription_Type__c = 'Commitment Term';
        insert quote;
        
        Product2 product = new Product2(Name = 'Month 1', IsActive = true, ProductCode = 'COMMIT-WRKSPC',Product_UUID__c = UUIDHandler.generateVersion4());
        insert product;
        
        Inventory__c inventory = new Inventory__c();
        inventory.Name = 'testinv';
        inventory.List_Price__c = 100;
        inventory.Type__c = 'Office';
        inventory.UUID__c = '3665lghjh27mnb';
        inventory.Building__c = building.Id;
        insert inventory;
        
        SBQQ__QuoteLine__c quoteLine = new SBQQ__QuoteLine__c();
        quoteLine.SBQQ__Quote__c = quote.Id;
        quoteLine.SBQQ__Product__c = product.Id;
        quoteLine.Building_Id__c = building.Id;
        quoteLine.Inventory_Id__c = inventory.Id;
        quoteLine.SBQQ__StartDate__c = System.today();
        quoteLine.Commitment_Term__c = '1';
        quoteLine.SBQQ__Number__c = 1;
        insert quoteLine;
        
        SBQQ__QuoteLine__c quoteLine2 = new SBQQ__QuoteLine__c();
        quoteLine2.SBQQ__Quote__c = quote.Id;
        quoteLine2.SBQQ__Product__c = product.Id;
        quoteLine2.Building_Id__c = building.Id;
        quoteLine2.Inventory_Id__c = inventory.Id;
        quoteLine2.SBQQ__StartDate__c = System.today();
        quoteLine2.Commitment_Term__c = '6';
        quoteLine2.SBQQ__Number__c = 1;
        quoteLine2.SBQQ__RequiredBy__c = quoteLine.Id;
        insert quoteLine2;
    }
    
    @isTest
    static void getQuoteLinesByQuoteIdTestPositive(){
        Set<String> excludeProductCodes = new Set<String>{'SETUP-FEE', 'SRVC-RTNR'}; 
        Test.startTest();
        SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        Product2 product = [SELECT Id,ProductCode FROM Product2 LIMIT 1];
        Inventory__c inventory = [SELECT Id, UUID__c FROM Inventory__c LIMIT 1];
        List<SBQQ__QuoteLine__c> quoteLinesByQuoteId = quoteLineSelector.getQuoteLinesByQuoteId(quote.Id);
        System.assert(!quoteLinesByQuoteId.isEmpty(),'QuoteLines are not retrived');
        Set<String> inventoryIds = new Set<String>();
        List<SBQQ__QuoteLine__c> quoteLinesWithInventories = quoteLineSelector.getQuoteLinesWithInventories(quote.Id, inventoryIds);
        System.assert(!quoteLinesWithInventories.isEmpty(),'QuoteLines are not retrived');
        Set<String> productCodes = new Set<String>{product.ProductCode};
        List<SBQQ__QuoteLine__c> quoteLinesWithProductCodes = quoteLineSelector.getQuoteLinesByQuoteIdAndProductCode(quote.Id);
        System.assert(!quoteLinesWithProductCodes.isEmpty(),'QuoteLines are not retrived');
        
        List<SBQQ__QuoteLine__c> quoteLineByquoteId = quoteLineSelector.getQuoteLinesByQuoteIdOrderByProductName(quote.Id);
        System.assert(!quoteLineByquoteId.isEmpty(),'QuoteLines are not retrived');
        inventoryIds.add(inventory.UUID__c);
        List<SBQQ__QuoteLine__c> quoteLinesByInventoryUUIDs = quoteLineSelector.getQuoteLinesByInventoryUUIDs(inventoryIds, quote.Id);
        System.assert(!quoteLinesByInventoryUUIDs.isEmpty(),'QuoteLines are not retrived');
        List<SBQQ__QuoteLine__c> quoteLinesByInventoryUUIDsAndQuoteIds = quoteLineSelector.getQuoteLinesByQuoteIdAndInventoryIds(new Set<String>{quote.Id}, excludeProductCodes);
        System.assert(!quoteLinesByInventoryUUIDsAndQuoteIds.isEmpty(), 'QuoteLines are not retrived');
        SBQQ__QuoteLine__c quoteLine =[SELECT Id FROM SBQQ__QuoteLine__c LIMIT 1];
        List<SBQQ__QuoteLine__c> getQuoteLinesById = quoteLineSelector.getQuoteLinesByIds(new Set<String>{quoteLine.Id});
        System.assert(!getQuoteLinesById.isEmpty(), 'QuoteLines are not retrived');
        Test.stopTest();
    }
    
    @isTest
    static void getQuoteLinesByQuoteIdTestNegative(){
        SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        List<SBQQ__QuoteLine__c> quoteLinesByQuoteId = quoteLineSelector.getQuoteLinesByQuoteId(null);
        System.assert(quoteLinesByQuoteId == null,'QuoteLines are retrived');
        Set<String> inventoryIds = new Set<String>();
        List<SBQQ__QuoteLine__c> quoteLinesWithInventories = quoteLineSelector.getQuoteLinesWithInventories(null, inventoryIds);
        System.assert(quoteLinesWithInventories == null,'QuoteLines are retrived');
        Set<String> productCodes = new Set<String>();
        List<SBQQ__QuoteLine__c> quoteLinesWithProductCodes = quoteLineSelector.getQuoteLinesByQuoteIdAndProductCode(null); 
        System.assert(quoteLinesWithProductCodes == null,'QuoteLines are retrived');
        
        List<SBQQ__QuoteLine__c> quoteLineByquoteId = quoteLineSelector.getQuoteLinesByQuoteIdOrderByProductName(null);
        System.assert(quoteLineByquoteId == null,'QuoteLines are retrived');
        
        List<SBQQ__QuoteLine__c> quoteLinesByInventoryUUIDs = quoteLineSelector.getQuoteLinesByInventoryUUIDs(inventoryIds, null);
        System.assert(quoteLinesByInventoryUUIDs == null,'QuoteLines are retrived');
    } 
}