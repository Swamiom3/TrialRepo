/************************************************************************************************************************************
Author      :   Salesforce
Description :   This class contain all aura methods related to View and Select Term Based Discounts.
----------------------------------------------------------------------------------------------------------------------------------
VERSION     DATE                AUTHOR                  DETAIL
1           08 Jun 2021         Salesforce            Initial Developement
**************************************************************************************************************************************/
Public with sharing class TermBasedDiscountController{
    private static final String SOURCE = 'AddCommitmentTerm';
    public static Map<Integer, Product2> productWithNumbers;
    public static Map<String, SBQQ__ProductOption__c > productOptionWithNumbers;
    public static Map<Id,List<SBQQ__QuoteLine__c>> mainQuoteLineWithSubQuoteLines;
    public static Map<String,PricebookEntry> productNameWithPriceBookEntries;
    public static QuoteLineSelector quoteLineSelector = new QuoteLineSelector();
    public static PriceBookEntrySelector priceBookEntrySelector = new PriceBookEntrySelector();
    public static ProductOptionSelector productOptionSelector =new ProductOptionSelector();
    public static Map<String,Decimal> inventoryUUIDwithBaseDiscounts ;
    public static Map<String,String> quotelineIdwithSelectedTerm = new Map<String,String>();
    private static TermBasedDiscountControllerHelper controllerHelper = new TermBasedDiscountControllerHelper();
    private static TermBasedDiscountQuoteLinesHelper quoteLineHelper = new TermBasedDiscountQuoteLinesHelper();
    
    @AuraEnabled
    public static DatabaseResult getTermDiscountsWrapper(Id quoteId){ 
        if(quoteId == null){
            return new DatabaseResult(new List<SObject>());
        }
        
        Set<String> productCodes = new Set<String>{CPQConstants.PRODUCTCODE_COMMIT, CPQConstants.PRODUCTCODE_M2M};
        List<SBQQ__QuoteLine__c> quoteLines = quoteLineSelector.getQuoteLinesByQuoteIdAndProductCode(quoteId);               
        
        if(quoteLines.isEmpty()){
            return new DatabaseResult(new List<SObject>());
        }
        List<String> commitTermList = new List<String>{'--Select--'};
        
        for(Schema.PicklistEntry pickListValue : SBQQ__QuoteLine__c.Commitment_Term__c.getDescribe().getPicklistValues()){ 
            commitTermList.add(pickListValue.getValue());
        }
        
        List<TermDiscountWrapper> termDiscountWrapperList = controllerHelper.processTermDiscountLines(quoteLines, commitTermList);
        return new DatabaseResult(termDiscountWrapperList);
    }

    @AuraEnabled
    public static DatabaseResult addDiscount(String wrapperString){
        if(wrapperString == null){
            return new DatabaseResult(new List<SObject>());
        }
        
        List<TermDiscountWrapper> termDiscountWrapperList = (List<TermDiscountWrapper>) System.JSON.deserialize(wrapperString, List<TermDiscountWrapper>.class);
        getBaseDiscountFromPromoService(termDiscountWrapperList);
        List<String> productNames = new List<String>();
        productWithNumbers = new Map<Integer, Product2> ();
        productOptionWithNumbers = new Map<String,SBQQ__ProductOption__c>();
        Integer maxValue= 0;
        List<SBQQ__QuoteLine__c> quoteLinesToUpdate = new List<SBQQ__QuoteLine__c>();
        List<Integer> commitmentTerms = controllerHelper.processTermsAndProdNames(termDiscountWrapperList, productNames, productWithNumbers);
        quoteLineHelper.updateQuoteLines(termDiscountWrapperList);
        quoteLineHelper.addOrRemoveQuoteLines(termDiscountWrapperList);
        mainQuoteLineWithSubQuoteLines = quoteLineHelper.getParentQuoteLinesWithChilds(termDiscountWrapperList.get(0).quoteLineRecord.SBQQ__Quote__c);        
        productNameWithPriceBookEntries = getPriceBookEntries(termDiscountWrapperList.get(0).quoteLineRecord.SBQQ__Quote__r.SBQQ__PricebookId__c);
        quoteLinesToUpdate = getQuoteLinesWithPricingDiscounts(termDiscountWrapperList);        
        if(!quoteLinesToUpdate.isEmpty()){
            SBQQ.TriggerControl.disable();
            update quoteLinesToUpdate;
        }
        List<SBQQ__QuoteLine__c> quoteLineList = quoteLineSelector.getQuoteLinesByQuoteId(termDiscountWrapperList.get(0).quoteLineRecord.SBQQ__Quote__c);
        CPQQuoteLineNumberService numberService = new CPQQuoteLineNumberService(quoteLineList, inventoryUUIDwithBaseDiscounts);
        if(!numberService.quoteLinesWithSBQQNumber.isEmpty()){
            SBQQ.TriggerControl.enable();
            update numberService.quoteLinesWithSBQQNumber;
        }        
        return new DatabaseResult(true,quoteLinesToUpdate,'success');        
    }

    @TestVisible
    private static List<SBQQ__QuoteLine__c> getQuoteLinesWithPricingDiscounts(List<TermDiscountWrapper> termDiscountWrapperList){
        List<SBQQ__QuoteLine__c> quoteLinesWithPricingDiscounts =new List<SBQQ__QuoteLine__c>();
        Set<String> productCodeSet = new Set<String>{'1', 'M2M'};
        if(termDiscountWrapperList.isEmpty()){
            return quoteLinesWithPricingDiscounts;
        }
        Integer sbqqNumber = 1;
        SBQQ__QuoteLine__c quoteLine;
        for(TermDiscountWrapper termDiscountWrapperItem : termDiscountWrapperList){
            if(!termDiscountWrapperItem.displayItem.Contains(CPQConstants.PRODUCTCODE_COMMIT) && !termDiscountWrapperItem.displayItem.Contains(CPQConstants.PRODUCTCODE_M2M)){
                continue;
            }            
            quoteLine = new SBQQ__QuoteLine__c (Id = termDiscountWrapperItem.quoteLineId); 
            quoteLine.SBQQ__Number__c = sbqqNumber;
            quoteLinesWithPricingDiscounts.add(quoteLine);
            sbqqNumber++;                
            List<SBQQ__QuoteLine__c> quoteLines = mainQuoteLineWithSubQuoteLines.get(termDiscountWrapperItem.quoteLineId);                    
            for(SBQQ__QuoteLine__c childQuoteLine : quoteLines){
                if(childQuoteLine.SBQQ__Product__r.Name.Startswith('Month')){
                    quoteLinesWithPricingDiscounts.add(controllerHelper.processPricingDiscountForMonthSKU(termDiscountWrapperItem, childQuoteLine, sbqqNumber, productCodeSet));                                
                    sbqqNumber++;
                }else if(childQuoteLine.SBQQ__Product__r.Name == 'Setup Fee'){
                    quoteLine = new SBQQ__QuoteLine__c (Id = childQuoteLine.Id);      
                    quoteLine.SBQQ__Number__c = sbqqNumber;
                    quoteLine.SBQQ__EndDate__c = childQuoteLine.SBQQ__RequiredBy__r.SBQQ__EndDate__c;
                    quoteLinesWithPricingDiscounts.add(quoteLine);
                    sbqqNumber++;
                }else if(childQuoteLine.SBQQ__Product__r.Name == 'Service Retainer'){
                    quoteLine = new SBQQ__QuoteLine__c (Id = childQuoteLine.Id);      
                    quoteLine.SBQQ__Number__c = sbqqNumber;
                    quoteLine.SBQQ__EndDate__c = childQuoteLine.SBQQ__RequiredBy__r.SBQQ__EndDate__c;
                    quoteLinesWithPricingDiscounts.add(quoteLine);
                    sbqqNumber++;
                }
            }            
        }
        return quoteLinesWithPricingDiscounts;
    }

    @TestVisible
    public static Map<String,PricebookEntry> getPriceBookEntries(String priceBookId){
        Map<String,PricebookEntry> priceBookEntries =new Map<String,PricebookEntry>();
        if(priceBookId == null){
            return priceBookEntries;
        }        
        for(PricebookEntry pricebookEntry:priceBookEntrySelector.getPriceBookEntriesbyPriceBookId(priceBookId)){
            priceBookEntries.put(pricebookEntry.Product2Id,pricebookEntry);                                               
        }
        return priceBookEntries;
    }
    
    
    
    @TestVisible  
    private static void getBaseDiscountFromPromoService(List<TermDiscountWrapper> termDiscountWrapperList){
        inventoryUUIDwithBaseDiscounts = new Map<String,Decimal>();        
        if(termDiscountWrapperList.isEmpty()){
            return;
        }        
        for(TermDiscountWrapper termDiscountWrapperItem : termDiscountWrapperList){
            quotelineIdwithSelectedTerm.put(termDiscountWrapperItem.quoteLineId,termDiscountWrapperItem.commitmentTermData.commitmentTerm);
        }
        CPQAddPromos.quoteLineWithTerm = quotelineIdwithSelectedTerm;
        List<CPQAddPromosWrapper.ResponseWithInventory> responseWithInventoryList;
        try {
            responseWithInventoryList = CPQAddPromos.getPromos(termDiscountWrapperList.get(0).quoteLineRecord.SBQQ__Quote__c,SOURCE);
        } catch(Exception e) {
            responseWithInventoryList = new List<CPQAddPromosWrapper.ResponseWithInventory>();
        }
        for(CPQAddPromosWrapper.ResponseWithInventory responsewithInventory : responseWithInventoryList){
            if(responsewithInventory.response == null || responsewithInventory.response.discounts == null){
                return;
            }            
            for(CPQAddPromosWrapper.DiscountsWrapper discountWrapper : responsewithInventory.response.discounts){
                inventoryUUIDwithBaseDiscounts.put(responsewithInventory.uuid,discountWrapper.baseDiscount);
            }            
        }
        
    }

    public static Map<String, SBQQ__ProductOption__c > getProductOptions(Integer maxValue){
        Map<String,SBQQ__ProductOption__c> productOptions= new Map<String,SBQQ__ProductOption__c>();
        if(maxValue== null){
            return productOptions;
        }        
        for(SBQQ__ProductOption__c productOption : TermBasedDiscountController.productOptionSelector.getProductOptionsBySBQQNumber(maxValue)){
            productOptions.put(productOption.SBQQ__ConfiguredSKU__c+'-'+productOption.SBQQ__Number__c , productOption);
        }
        return productOptions;
    }
}