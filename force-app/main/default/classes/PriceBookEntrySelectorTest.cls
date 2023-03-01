/*************************************************************************************************************************************
Author      :   Salesforce
Description :   This class provides sufficient test coverage for PriceBookEntrySelector class
--------------------------------------------------------------------------------------------------------------------------------------
VERSION         DATE            AUTHOR              DETAIL
1               7/21/2021       Salesforce         Initial Deployment
**************************************************************************************************************************************/
@isTest
private class PriceBookEntrySelectorTest {
    private static PriceBookEntrySelector priceBookEntrySelector = new PriceBookEntrySelector();
    
    @isTest
    static void getPriceBookEntriesbyPriceBookIdAndProductIdTest(){
        Id pricebookId = Test.getStandardPricebookId();
        Product2 product = new Product2( Name = 'Commitment Test2', Product_UUID__c ='product1', IsActive = true, ProductCode='COMMIT-TEST');
        insert product;
        
        PricebookEntry pricebookEntry = new PricebookEntry(
            Pricebook2Id = pricebookId,
            Product2Id = product.Id,
            UnitPrice = 1020,
            IsActive = true
        );
        insert pricebookEntry;        
        List<PricebookEntry> priceBookEntriesBypriceBookId = priceBookEntrySelector.getPriceBookEntriesbyPriceBookId(pricebookId);
        System.assert(priceBookEntriesBypriceBookId != null, 'Pricebook Entries not Retrived successfully');
        List<PricebookEntry> priceBookEntries = priceBookEntrySelector.getPriceBookEntriesbyPriceBookIdAndProductId(pricebookId, product.Id);
        System.assert(priceBookEntries !=null, 'Pricebook Entries are not retrieved');
    }
    
    @isTest
    static void getPriceBookEntriesNegativeTest(){
         List<PricebookEntry> priceBookEntriesBypriceBookId = priceBookEntrySelector.getPriceBookEntriesbyPriceBookId('123');
        System.assert(priceBookEntriesBypriceBookId.isEmpty(), 'Pricebook Entries Retrived successfully');
        List<PricebookEntry> priceBookEntries = priceBookEntrySelector.getPriceBookEntriesbyPriceBookIdAndProductId('123','123');
        System.assert(priceBookEntries.isEmpty(), 'Pricebook Entries are retrieved');
    }
}