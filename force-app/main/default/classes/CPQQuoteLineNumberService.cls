/*************************************************************************************************************************************
 Author      :   Arun
 Description :   Service class to update the SBQQ__Number__c field on Quote Lines
 --------------------------------------------------------------------------------------------------------------------------------------
 VERSION         DATE            AUTHOR              DETAIL
 1               12/03/2021       Arun        Initial Deployment
 **************************************************************************************************************************************/
public inherited sharing class CPQQuoteLineNumberService {
    public List<SBQQ__QuoteLine__c> quoteLinesWithSBQQNumber;
    
    public CPQQuoteLineNumberService(List<SBQQ__QuoteLine__c> quoteLineList, Map<String, Decimal> inventoryUUIDwithBaseDiscounts) {
        quoteLinesWithSBQQNumber = updateQuoteLinesNumber(quoteLineList, inventoryUUIDwithBaseDiscounts);
    }
    
    @TestVisible
    private List<SBQQ__QuoteLine__c> updateQuoteLinesNumber(List<SBQQ__QuoteLine__c> quoteLineList, Map<String, Decimal> inventoryUUIDwithBaseDiscounts) {
        QLNumberWrapper wrapper = updateSBQQNumber(quoteLineList, inventoryUUIDwithBaseDiscounts);
        for(SBQQ__QuoteLine__c quoteLine : quoteLineList){ 
            if(quoteLine.SBQQ__ProductFamily__c != CPQConstants.ADDONS_PRODUCTFAMILY){
                continue;
            }
            wrapper.qlNumber++;
            quoteLine.SBQQ__Number__c = wrapper.qlNumber;
            wrapper.quoteLinesWithSBQQNumber.put(quoteLine.Id, quoteLine);                       
        }
        return wrapper.quoteLinesWithSBQQNumber.values();
    }
    
    private QLNumberWrapper updateSBQQNumber(List<SBQQ__QuoteLine__c> quoteLines, Map<String, Decimal> inventoryUUIDwithBaseDiscounts){
        QLNumberWrapper wrapper = new QLNumberWrapper();
        wrapper.quoteLinesWithSBQQNumber = new Map<Id, SBQQ__QuoteLine__c>();
        wrapper.qlNumber = 0;

        if(quoteLines.isEmpty()){
            return wrapper;
        }
        
        Map<String,List<SBQQ__QuoteLine__c>> parentQuoteLinesWithChildQuoteLines = new Map<String,List<SBQQ__QuoteLine__c>>();
        for(SBQQ__QuoteLine__c quoteLine : quoteLines){
            if(quoteLine.SBQQ__ProductFamily__c == CPQConstants.ADDONS_PRODUCTFAMILY){
                continue;
            }
            if(quoteLine.SBQQ__RequiredBy__c != null && parentQuoteLinesWithChildQuoteLines.containskey(quoteLine.SBQQ__RequiredBy__c)){
                parentQuoteLinesWithChildQuoteLines.get(quoteLine.SBQQ__RequiredBy__c).add(quoteLine);
            }else{
                parentQuoteLinesWithChildQuoteLines.put(quoteLine.Id,new List<SBQQ__QuoteLine__c>{quoteLine});
            }                
        }
        List<SBQQ__QuoteLine__c> quoteLinesWithSBQQNumber = new List<SBQQ__QuoteLine__c>();
        wrapper.qlNumber = processSBQQNumberParentChildLines(parentQuoteLinesWithChildQuoteLines, quoteLinesWithSBQQNumber, inventoryUUIDwithBaseDiscounts);
        wrapper.quoteLinesWithSBQQNumber = new Map<Id, SBQQ__QuoteLine__c>(quoteLinesWithSBQQNumber);
        return wrapper;
    }
    
    private Integer processSBQQNumberParentChildLines(Map<String,List<SBQQ__QuoteLine__c>> parentQuoteLinesWithChildQuoteLines, List<SBQQ__QuoteLine__c> quoteLinesWithSBQQNumber, 
                                                      Map<String, Decimal> inventoryUUIDwithBaseDiscounts) {
        Integer qlNumber=0;
        for(String parentId : parentQuoteLinesWithChildQuoteLines.keyset()){
            List<SBQQ__QuoteLine__c> quoteLines = parentQuoteLinesWithChildQuoteLines.get(parentId);
            if(parentId == quoteLines[0].Id){
                quoteLines[0].SBQQ__Number__c = qlNumber+1;
                processSBQQNumberParentLine(quoteLines, inventoryUUIDwithBaseDiscounts);
                qlNumber = qlNumber+1;
                quoteLinesWithSBQQNumber.add(quoteLines[0]);
            }
            for(Integer i =1; i< quoteLines.size(); i++){
                if(!quoteLines[i].SBQQ__Product__r.Name.startsWith('Month')){
                    continue;
                }
                qlNumber = qlNumber+1;
                quoteLines[i].SBQQ__Number__c = qlNumber;
                quoteLinesWithSBQQNumber.add(quoteLines[i]);                    
            }
            quoteLinesWithSBQQNumber.sort();
            for(Integer i =1; i< quoteLines.size(); i++){
                if(quoteLines[i].SBQQ__Product__r.Name.startsWith('Month')){
                    continue;
                }
                qlNumber = qlNumber+1;
                quoteLines[i].SBQQ__Number__c = qlNumber;
                quoteLinesWithSBQQNumber.add(quoteLines[i]);                    
            }            
        }
        return qlNumber;
    }
    
    private void processSBQQNumberParentLine(List<SBQQ__QuoteLine__c> quoteLines, Map<String, Decimal> inventoryUUIDwithBaseDiscounts) {
        for(SBQQ__QuoteLine__c line: quoteLines) {
            if(inventoryUUIDwithBaseDiscounts?.get(line.Inventory_Id__r.UUID__c) != null){
                line.Maximum_Discount__c = inventoryUUIDwithBaseDiscounts.get(line.Inventory_Id__r.UUID__c) * 100;                
            }
            if(line.SBQQ__ProductFamily__c == CPQConstants.ALL_ACCESS){
                line.SBQQ__ListPrice__c = 0;
            }
        }
    }

    private class QLNumberWrapper {
        Map<Id, SBQQ__QuoteLine__c> quoteLinesWithSBQQNumber;
        Integer qlNumber;
    }
}