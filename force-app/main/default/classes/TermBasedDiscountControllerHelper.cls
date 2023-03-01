/*************************************************************************************************************************************
 Author      :   Arun
 Description :   This is an helper class for TermBasedDiscountController
 --------------------------------------------------------------------------------------------------------------------------------------
 VERSION         DATE            AUTHOR              DETAIL
 1               11/18/2021       Arun        Initial Deployment
 **************************************************************************************************************************************/
public inherited sharing class TermBasedDiscountControllerHelper {
    private ProductSelector productSelector = new ProductSelector();
    
    public List<TermDiscountWrapper> processTermDiscountLines(List<SBQQ__QuoteLine__c> quoteLines, List<String> commitTermList) {
        List<TermDiscountWrapper> termDiscountWrapperList = new List<TermDiscountWrapper> ();
        for(SBQQ__QuoteLine__c quoteLine : quoteLines){
            TermDiscountWrapper termDiscountWrapperItem;
            if(quoteLine.SBQQ__Product__r.ProductCode.Contains(CPQConstants.PRODUCTCODE_COMMIT) && quoteLine.Inventory_Id__r != null){
                termDiscountWrapperItem = processTermDiscountCommitLine(quoteLine, commitTermList);
                termDiscountWrapperList.add(termDiscountWrapperItem);
            }
            
            if(quoteLine.SBQQ__RequiredBy__c== null && quoteLine.SBQQ__ProductFamily__c == CPQConstants.ALL_ACCESS){
                Boolean isCommitmentworkSpace = quoteLine.SBQQ__Quote__r.Subscription_Type__c != CPQConstants.SUBSCRIPTION_M2M; 
                String displayItem = quoteLine.SBQQ__Quote__r.Subscription_Type__c != CPQConstants.SUBSCRIPTION_M2M ? CPQConstants.PRODUCTCODE_COMMIT : CPQConstants.PRODUCTCODE_M2M;
                TermCommitmentWrapper commitmentWrap = new TermCommitmentWrapper(commitTermList, quoteLine.Commitment_Term__c);
                if(quoteLine.QuoteLineSource__c != null){
                    termDiscountWrapperItem = new TermDiscountWrapper(displayItem, quoteLine.SBQQ__ProductName__c, commitmentWrap, quoteLine, isCommitmentworkSpace, true);
                }else{
                    termDiscountWrapperItem = new TermDiscountWrapper(displayItem, quoteLine.SBQQ__ProductName__c, commitmentWrap, quoteLine, !isCommitmentworkSpace, false); 
                }
                termDiscountWrapperList.add(termDiscountWrapperItem);
            }
        }
        return termDiscountWrapperList;
    }
    
    @testVisible
    private TermDiscountWrapper processTermDiscountCommitLine(SBQQ__QuoteLine__c quoteLine, List<String> commitTermList) {
        TermDiscountWrapper termDiscountWrapperItem;
        TermCommitmentWrapper commitmentWrap = new TermCommitmentWrapper(commitTermList, quoteLine.Commitment_Term__c);
        TermCommitmentWrapper commitmentNullWrap = new TermCommitmentWrapper(null, null);
        if(quoteLine.SBQQ__Quote__r.Subscription_Type__c != CPQConstants.SUBSCRIPTION_M2M){
            if(quoteLine.QuoteLineSource__c != null){
                termDiscountWrapperItem = new TermDiscountWrapper(CPQConstants.PRODUCTCODE_COMMIT, quoteLine.Inventory_Id__r.Name, commitmentWrap, quoteLine, true, true);
            }else{
                termDiscountWrapperItem = new TermDiscountWrapper(CPQConstants.PRODUCTCODE_COMMIT, quoteLine.Inventory_Id__r.Name, commitmentWrap, quoteLine, false, false); 
            }
        }else{
            if(quoteLine.QuoteLineSource__c != null){
                termDiscountWrapperItem = new TermDiscountWrapper(CPQConstants.PRODUCTCODE_M2M, quoteLine.Inventory_Id__r.Name, commitmentNullWrap, quoteLine, true, true);
            }else{
                termDiscountWrapperItem = new TermDiscountWrapper(CPQConstants.PRODUCTCODE_M2M, quoteLine.Inventory_Id__r.Name, commitmentNullWrap, quoteLine, true, false);  
            }
        }
        return termDiscountWrapperItem;
    }

    public List<Integer> processTermsAndProdNames(List<TermDiscountWrapper> termDiscountWrapperList, List<String> productNames, Map<Integer, Product2> productWithNumbers) {
        List<Integer> commitmentTerms = new List<Integer>();
        Integer maxValue = 0;
        for(TermDiscountWrapper termDiscountWrapperItem : termDiscountWrapperList){
            if(!termDiscountWrapperItem.displayItem.Contains(CPQConstants.PRODUCTCODE_COMMIT) || termDiscountWrapperItem.commitmentTermData.commitmentTerm == null){
                continue;
            }
            
            commitmentTerms.add(termDiscountWrapperItem.StartDate.Day() > 1 ? Integer.valueOf(termDiscountWrapperItem.commitmentTermData.commitmentTerm)+1 : 
                                Integer.valueOf(termDiscountWrapperItem.commitmentTermData.commitmentTerm));
        }
        
        if(commitmentTerms.isEmpty()) {
            return commitmentTerms;
        }
        
        commitmentTerms.sort();
        maxValue = commitmentTerms[commitmentTerms.size()-1];            
        for(Integer i=0; i< maxValue; i++){
            productNames.add('month ' +(i+1));
        }
        for(Product2 product : productSelector.getProductWithSubscriptionsOrderByProductName(productNames)){
            productWithNumbers.put(Integer.valueOf(product.ProductCode), product);
        }
        TermBasedDiscountController.productOptionWithNumbers = TermBasedDiscountController.getProductOptions(maxValue);
        return commitmentTerms;
    }

    public SBQQ__QuoteLine__c processPricingDiscountForMonthSKU(TermDiscountWrapper termDiscountWrapperItem, SBQQ__QuoteLine__c childQuoteLine, Integer sbqqNumber, Set<String> productCodeSet) {
        SBQQ__QuoteLine__c quoteLine = new SBQQ__QuoteLine__c (Id = childQuoteLine.Id);
        if(termDiscountWrapperItem.commitmentTermData.commitmentTerm != termDiscountWrapperItem.quoteLineRecord.Commitment_Term__c){
            quoteLine.Promo_Code_Id__c =null;
            quoteLine.SBQQ__PartnerDiscount__c =null;
        }
        quoteLine.SBQQ__Number__c = sbqqNumber;
        quoteLine.SBQQ__EndDate__c = childQuoteLine.SBQQ__RequiredBy__r.SBQQ__EndDate__c;
        if(TermBasedDiscountController.productNameWithPriceBookEntries.containskey(childQuoteLine.SBQQ__Product__c)){
            quoteLine.SBQQ__PricebookEntryId__c = TermBasedDiscountController.productNameWithPriceBookEntries.get(childQuoteLine.SBQQ__Product__c).Id;
        }
        
        quoteLine.SBQQ__ListPrice__c = childQuoteLine.Inventory_Id__r.List_Price__c != null ? childQuoteLine.Inventory_Id__r.List_Price__c:0;
        if(termDiscountWrapperItem.StartDate.day()>1 && (productCodeSet.contains(childQuoteLine.SBQQ__ProductCode__c) || productCodeSet.contains(childQuoteLine.SBQQ__ProductCode__c))){
            Integer daysinMonth = Date.daysInMonth(termDiscountWrapperItem.StartDate.year(),termDiscountWrapperItem.StartDate.month());
            Integer pricePerDay = Integer.valueOf(quoteLine.SBQQ__ListPrice__c/daysinMonth);
            quoteLine.SBQQ__ListPrice__c =  (daysinMonth-termDiscountWrapperItem.StartDate.day())*pricePerDay;
        }
        
        if(childQuoteLine.SBQQ__RequiredBy__r.SBQQ__ProductFamily__c.startsWith(CPQConstants.ALL_ACCESS)){
            quoteLine.SBQQ__ListPrice__c = TermBasedDiscountController.productNameWithPriceBookEntries.get(childQuoteLine.SBQQ__RequiredBy__r.SBQQ__Product__c).UnitPrice;
        }
        return quoteLine;
    }
}