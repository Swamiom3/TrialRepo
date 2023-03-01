/************************************************************************************************************************************
Author      :   Salesforce
Description :   This class contain all aura methods related to Iframe Inventory search.
----------------------------------------------------------------------------------------------------------------------------------
VERSION     DATE                AUTHOR                  DETAIL
1           10 Jun 2021         Salesforce            Initial Developement
**************************************************************************************************************************************/
public with sharing class InventorySearchController{
    public static final String PRODUCTCODE_COMMIT = 'Physical Membership';
    public static final String PRODUCTCODE_SETUPFEE = 'Setup Fee';
    public static final String PRODUCTCODE_SRVCRTNR = 'Service Retainer';    
    public static final String PRODUCTCODE_LATEFEE = 'Late Fee';
    public static final String PRODUCTCODE_M2M = 'Month-to-Month';
    public static final String PRODUCTCODE_CONF_ROOM_CREDIT = 'Conference Room Credit';
    public static final String PRODUCTCODE_COLOR_PRINT_CREDIT = 'Color Printing Credit';
    public static final String PRODUCTCODE_B_W_PRINT_CREDIT = 'Black & White Printing Credit';
    public static Map<String,Product2> productsWithProductCodes;
    public static Map<String,SBQQ__ProductOption__c> productOptionsWithProductCodes;    
    public static Map<String,String> productNameWithPricebookEntries;
    public static Map<String,SBQQ__QuoteLine__c> quoteLineWithInventoryUUID;
    public static QuoteSelector quoteSelector = new QuoteSelector();
    public static QuoteLineSelector quoteLineSelector = new QuoteLineSelector();
    public static ProductOptionSelector productOptionSelector = new ProductOptionSelector();
    public static ProductSelector productSelector = new ProductSelector();
    private static InventorySearchControllerHelper helper = new InventorySearchControllerHelper();
    
    @AuraEnabled(cacheable=true)
    public static SBQQ__Quote__c getQuote(String quoteId){
        if(quoteId == null){
            return null;
        }
        SBQQ__Quote__c quote = quoteSelector.getQuoteById(quoteId)[0];
        return quote;
    }
    
    @AuraEnabled
    public static DataBaseResult createQuoteLines(String inventoryWrapString){
        
        List<SBQQ__QuoteLine__c> quoteLines = new List<SBQQ__QuoteLine__c>();
        quoteLineWithInventoryUUID = new Map<String,SBQQ__QuoteLine__c>();
        Map<String,List<SBQQ__QuoteLine__c>> parentQuoteLinesWithChilds = new Map<String,List<SBQQ__QuoteLine__c>>();
        Map<Id,SBQQ__QuoteLine__c> quoteLinesTobeUpdated = new Map<Id,SBQQ__QuoteLine__c>();
        Set<String> inventoryUUIds = new Set<String>();
        List<SBQQ__QuoteLine__c> parentQuoteLines = new List<SBQQ__QuoteLine__c>();
        List<String> productCodes = new List<String>{PRODUCTCODE_COMMIT, PRODUCTCODE_SETUPFEE, PRODUCTCODE_SRVCRTNR, PRODUCTCODE_LATEFEE,
                                PRODUCTCODE_M2M,PRODUCTCODE_CONF_ROOM_CREDIT,PRODUCTCODE_COLOR_PRINT_CREDIT,PRODUCTCODE_B_W_PRINT_CREDIT};
        productsWithProductCodes = new Map<String,Product2>();
        productNameWithPricebookEntries = new Map<String,String>();
        productOptionsWithProductCodes = new Map<String,SBQQ__ProductOption__c>();
        InventorySearchWrapper inventoryWrapper = (InventorySearchWrapper) System.JSON.deserialize(inventoryWrapString, InventorySearchWrapper.class);
        
        if(helper.isInventoryWrapperEmpty(inventoryWrapper)){
            return new DatabaseResult(new List<SObject>());
        }

        SBQQ__Quote__c quote = quoteSelector.getQuoteByIdWithSubscriptionType(inventoryWrapper.quoteId)[0];            
        if(quote.Subscription_Type__c != null){   
            productsWithProductCodes = helper.getProductWithProductCodes(productCodes);              
            productOptionsWithProductCodes = getProductOption(productCodes);
        }        
        helper.updateQuoteBuildingId(quote,inventoryWrapper);
        quoteLineWithInventoryUUID = getQuoteLinesWithInventoryUUID(inventoryWrapper.quoteId);        
        productNameWithPricebookEntries = getProductsWithPriceBookEntries(quote);
        
        processInventoryBuildingWraps(inventoryWrapper, quoteLineWithInventoryUUID, inventoryUUIds, parentQuoteLines, productsWithProductCodes, quote);

        if(parentQuoteLines.isEmpty()){
            SObject sObj = Schema.getGlobalDescribe().get('SBQQ__QuoteLine__c').newSObject() ;
            return new DatabaseResult(true,sObj,'selected inventories already added');
        }
        
        List<Inventory__c> inventoryList = helper.validateInventories(inventoryUUIds);
        helper.createParentQuoteLines(parentQuoteLines);
        
        createChildQuoteLines(quote);
        
        quoteLines = helper.getQuoteLinesByIdOrInventories(inventoryWrapper, quoteLineWithInventoryUUID.keySet());
        
        if(quoteLines.isEmpty()){
            return new DatabaseResult(new List<SObject>());
        }

        parentQuoteLinesWithChilds = helper.getParentAndChildLines(quoteLines);

        if(parentQuoteLinesWithChilds.isEmpty()){
            return new DatabaseResult(new List<SObject>());
        }
                
        quoteLinesTobeUpdated = helper.getQuoteLinesWithInventory(parentQuoteLinesWithChilds, inventoryList, quote.Building_Id__c);        
        if(quoteLinesTobeUpdated.isEmpty()){
            return new DatabaseResult(new List<SObject>());            
        }
        SBQQ.TriggerControl.disable();
        update quoteLinesTobeUpdated.values();
        List<SBQQ__QuoteLine__c> quoteLineList = quoteLineSelector.getQuoteLinesByQuoteId(quote.Id);
        if(quoteLineList.isEmpty()){
            return new DatabaseResult(new List<SObject>());
        }
        CPQQuoteLineNumberService numberService = new CPQQuoteLineNumberService(quoteLineList, new Map<String,Decimal>());
        if(!numberService.quoteLinesWithSBQQNumber.isEmpty()){
            SBQQ.TriggerControl.enable();
            update numberService.quoteLinesWithSBQQNumber;
        }

        return new DatabaseResult(true,quoteLinesTobeUpdated.values(),'Successfully inserted quoteLines');
    }

    public static void processInventoryBuildingWraps(InventorySearchWrapper inventoryWrapper, Map<String,SBQQ__QuoteLine__c> quoteLineWithInventoryUUID, Set<String> inventoryUUIds, List<SBQQ__QuoteLine__c> parentQuoteLines, Map<String,Product2> productsWithProductCodes, SBQQ__Quote__c quote) {
        for(InventoryBuildingWrapper inventoryBuildingWrapItem : inventoryWrapper.inventoryBuildingWrap){
            if(!quoteLineWithInventoryUUID.containskey(inventoryBuildingWrapItem.inventoryId)){        
                inventoryUUIds.add(inventoryBuildingWrapItem.inventoryId);
                parentQuoteLines.add(getQuoteLinesByProductCode(productsWithProductCodes.get(PRODUCTCODE_COMMIT), quote, null, null));
            }
        }
    }

    @TestVisible
    private static Map<String,SBQQ__QuoteLine__c> getQuoteLinesWithInventoryUUID(String quoteId){
        Map<String,SBQQ__QuoteLine__c> quoteLineWithUUID = new Map<String,SBQQ__QuoteLine__c>();
        if(quoteId == null){
            return quoteLineWithUUID;
        }
        List<SBQQ__QuoteLine__c> quoteLineList = quoteLineSelector.getQuoteLinesByQuoteId(quoteId);
        if(quoteLineList.isEmpty()){
            return quoteLineWithUUID;
        }
        for(SBQQ__QuoteLine__c quoteLine : quoteLineList){
            if(quoteLine.SBQQ__ProductFamily__c == CPQConstants.ADDONS_PRODUCTFAMILY || quoteLine.SBQQ__ProductFamily__c == CPQConstants.ALL_ACCESS || quoteLine.Inventory_Id__r.UUID__c == null){
                continue;
            }
            quoteLineWithUUID.put(quoteLine.Inventory_Id__r.UUID__c, quoteLine);                               
        }
        return quoteLineWithUUID;
    }
    
    @TestVisible
    private static SBQQ__QuoteLine__c getQuoteLinesByProductCode(Product2 product, SBQQ__Quote__c quote, Id requireById, Id productOptionId){        
        SBQQ__QuoteLine__c commitmentWorkSpaceQuoteLine = new SBQQ__QuoteLine__c ();
        commitmentWorkSpaceQuoteLine.SBQQ__Quote__c = quote.Id;
        commitmentWorkSpaceQuoteLine.CurrencyIsoCode = quote.CurrencyIsoCode;
        commitmentWorkSpaceQuoteLine.SBQQ__Product__c = product.Id;
        commitmentWorkSpaceQuoteLine.SBQQ__SubscriptionPricing__c = product.SBQQ__SubscriptionPricing__c;
        commitmentWorkSpaceQuoteLine.SBQQ__SubscriptionBase__c = product.SBQQ__SubscriptionBase__c;
        commitmentWorkSpaceQuoteLine.SBQQ__SubscriptionTerm__c = product.SBQQ__SubscriptionTerm__c;
        commitmentWorkSpaceQuoteLine.SBQQ__ProductSubscriptionType__c = product.SBQQ__SubscriptionType__c;
        commitmentWorkSpaceQuoteLine.SBQQ__SubscriptionType__c = product.SBQQ__SubscriptionType__c;
        commitmentWorkSpaceQuoteLine.SBQQ__DefaultSubscriptionTerm__c = product.SBQQ__SubscriptionTerm__c;
        commitmentWorkSpaceQuoteLine.SBQQ__ProrateMultiplier__c = product.SBQQ__SubscriptionTerm__c;                    
        commitmentWorkSpaceQuoteLine.SBQQ__Quantity__c = 1;
        commitmentWorkSpaceQuoteLine.SBQQ__PricebookEntryId__c = productNameWithPricebookEntries.get(product.Id);
        commitmentWorkSpaceQuoteLine.SBQQ__ChargeType__c = product.SBQQ__ChargeType__c ;
        commitmentWorkSpaceQuoteLine.SBQQ__BillingType__c = product.SBQQ__BillingType__c;
        commitmentWorkSpaceQuoteLine.SBQQ__BillingFrequency__c = product.SBQQ__BillingFrequency__c;
        commitmentWorkSpaceQuoteLine.Disable_Proration__c = product.Disable_Proration__c;
        commitmentWorkSpaceQuoteLine.SBQQ__PriceEditable__c = product.SBQQ__PriceEditable__c;        
        if(String.isNotBlank(requireById)){
            commitmentWorkSpaceQuoteLine.SBQQ__RequiredBy__c = requireById;
            commitmentWorkSpaceQuoteLine.SBQQ__ProductOption__c = productOptionId;
        }
        return commitmentWorkSpaceQuoteLine;
    }
    
    @TestVisible    
    private static Map<String,String> getProductsWithPriceBookEntries(SBQQ__Quote__c quote){
        Map<String,String> productsWithPbe = new Map<String,String>();
        if(quote == null || (quote != null && quote.SBQQ__PricebookId__c == null)){
            return productsWithPbe;
        }          
        PriceBookEntrySelector priceBookEntrySelector = new PriceBookEntrySelector();           
        for(PricebookEntry pricebookEntry : priceBookEntrySelector.getPriceBookEntriesbyPriceBookId(quote.SBQQ__PricebookId__c)){
            productsWithPbe.put(pricebookEntry.Product2Id,pricebookEntry.Id);                                               
        }        
        return productsWithPbe;
    }
    
    @TestVisible 
    private static void createChildQuoteLines(SBQQ__Quote__c quote){
        List<SBQQ__QuoteLine__c> childQuoteLines = new List<SBQQ__QuoteLine__c>();
        if(quote == null){
            return;
        }
        for(SBQQ__QuoteLine__c quoteLine : quoteLineSelector.getQuoteLinesByQuoteId(quote.Id)){            
            if(skipProcessingChildLine(quoteLine)){
                continue;
            } 
            
            if(quote.Subscription_Type__c == CPQConstants.SUBSCRIPTION_M2M){ 
                childQuoteLines.add(getQuoteLinesByProductCode(productsWithProductCodes.get(PRODUCTCODE_M2M), 
                                                               quote, quoteLine.Id, productOptionsWithProductCodes.get(quoteLine.SBQQ__Product__c+'-'+PRODUCTCODE_M2M).Id));
            }
            childQuoteLines.add(getQuoteLinesByProductCode(productsWithProductCodes.get(PRODUCTCODE_SETUPFEE), 
                                                           quote, quoteLine.Id, productOptionsWithProductCodes.get(quoteLine.SBQQ__Product__c+'-'+PRODUCTCODE_SETUPFEE).Id));
            if(quote.Service_Retainer_Method__c == 'Service Retainer'){
                childQuoteLines.add(getQuoteLinesByProductCode(productsWithProductCodes.get(PRODUCTCODE_SRVCRTNR), 
                                                           quote, quoteLine.Id, productOptionsWithProductCodes.get(quoteLine.SBQQ__Product__c+'-'+PRODUCTCODE_SRVCRTNR).Id));
            }
            childQuoteLines.add(getQuoteLinesByProductCode(productsWithProductCodes.get(PRODUCTCODE_LATEFEE), 
                                                           quote, quoteLine.Id, productOptionsWithProductCodes.get(quoteLine.SBQQ__Product__c+'-'+PRODUCTCODE_LATEFEE).Id));
            
            childQuoteLines.add(getQuoteLinesByProductCode(productsWithProductCodes.get(PRODUCTCODE_CONF_ROOM_CREDIT), 
                                                           quote, quoteLine.Id, productOptionsWithProductCodes.get(quoteLine.SBQQ__Product__c+'-'+PRODUCTCODE_CONF_ROOM_CREDIT).Id));
            childQuoteLines.add(getQuoteLinesByProductCode(productsWithProductCodes.get(PRODUCTCODE_COLOR_PRINT_CREDIT), 
                                                           quote, quoteLine.Id, productOptionsWithProductCodes.get(quoteLine.SBQQ__Product__c+'-'+PRODUCTCODE_COLOR_PRINT_CREDIT).Id));
            childQuoteLines.add(getQuoteLinesByProductCode(productsWithProductCodes.get(PRODUCTCODE_B_W_PRINT_CREDIT), 
                                                           quote, quoteLine.Id, productOptionsWithProductCodes.get(quoteLine.SBQQ__Product__c+'-'+PRODUCTCODE_B_W_PRINT_CREDIT).Id));
                           
        }

        if(!childQuoteLines.isEmpty()){
            SBQQ.TriggerControl.enable();
            insert childQuoteLines;
        }
    }

    private static Boolean skipProcessingChildLine(SBQQ__QuoteLine__c quoteLine) {
        return (quoteLineWithInventoryUUID.containskey(quoteLine.Inventory_Id__r.UUID__c) && quoteLine.Inventory_Id__r.UUID__c != null) 
        || !quoteLine.SBQQ__ProductName__c.startsWith('Physical') 
        || quoteLine.SBQQ__ProductFamily__c == CPQConstants.ADDONS_PRODUCTFAMILY 
        || quoteLine.SBQQ__ProductFamily__c == CPQConstants.ALL_ACCESS;
    }
    
    @TestVisible
    private static Map<String,SBQQ__ProductOption__c> getProductOption(List<String> productNames){
        Map<String,SBQQ__ProductOption__c> productOptionsWithProductCodes = new Map<String,SBQQ__ProductOption__c>();
        for(SBQQ__ProductOption__c productOption : productOptionSelector.getProductOptionByProductCode(productNames)){
            productOptionsWithProductCodes.put(productOption.SBQQ__ConfiguredSKU__c +'-'+productOption.SBQQ__ProductName__c,productOption);
        }
        return productOptionsWithProductCodes;
    }
    
    public class InventorySearchWrapper{
        public String quoteId;
        public List<InventoryBuildingWrapper> inventoryBuildingWrap;
    }
    
    public class InventoryBuildingWrapper{
        public String inventoryId;
        public Buildwrapper buildingId;
    }
    
    public class Buildwrapper{
        public String value;
    }
    
}