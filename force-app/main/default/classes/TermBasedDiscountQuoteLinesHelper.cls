/*************************************************************************************************************************************
 Author      :   Arun
 Description :   This is an helper class for TermBasedDiscountController
 --------------------------------------------------------------------------------------------------------------------------------------
 VERSION         DATE            AUTHOR              DETAIL
 1               11/18/2021       Arun        Initial Deployment
 **************************************************************************************************************************************/
public inherited sharing class TermBasedDiscountQuoteLinesHelper {

    private QuoteLineSelector quoteLineSelector = new QuoteLineSelector();
    
    public void updateQuoteLines(List<TermDiscountWrapper> termDiscountWrapperList){
        if(termDiscountWrapperList.isEmpty()){
            return;
        }
        List<SBQQ__QuoteLine__c> quoteLinesToUpdate = new List<SBQQ__QuoteLine__c>();
        for(TermDiscountWrapper termDiscountWrapperItem : termDiscountWrapperList){
            SBQQ__QuoteLine__c quoteline = new SBQQ__QuoteLine__c (Id = termDiscountWrapperItem.quoteLineId);
            
            if(termDiscountWrapperItem.displayItem.Contains(CPQConstants.PRODUCTCODE_COMMIT)){
                if(termDiscountWrapperItem.commitmentTermData.commitmentTerm != termDiscountWrapperItem.quoteLineRecord.Commitment_Term__c){
                    quoteline.Promo_Code_Id__c = null;
                }
                quoteline.Commitment_Term__c = termDiscountWrapperItem.commitmentTermData.commitmentTerm !=null ? termDiscountWrapperItem.commitmentTermData.commitmentTerm :'0';
                quoteline.SBQQ__StartDate__c = termDiscountWrapperItem.startDate ;
                quoteline.SBQQ__EndDate__c   = termDiscountWrapperItem.startDate.addmonths(Integer.valueOf(termDiscountWrapperItem.commitmentTermData.commitmentTerm)).toStartOfMonth().addDays(-1) ;
                quoteLinesToUpdate.add(quoteline);
            }            
            if(termDiscountWrapperItem.displayItem.Contains(CPQConstants.PRODUCTCODE_M2M)){
                quoteline.SBQQ__StartDate__c = termDiscountWrapperItem.startDate ;
                quoteLinesToUpdate.add(quoteline);
            }
        }
        if(!quoteLinesToUpdate.isEmpty()){
            SBQQ.TriggerControl.disable();
            update quoteLinesToUpdate;
        }
    }

    public void addOrRemoveQuoteLines(List<TermDiscountWrapper> termDiscountWrapperList){
        if(termDiscountWrapperList.isEmpty()){
            return;
        } 
        List<SBQQ__QuoteLine__c> quoteLinesToInsert = new list<SBQQ__QuoteLine__c>();
        Map<String,SBQQ__QuoteLine__c> quoteLinesToDelete = new Map<String,SBQQ__QuoteLine__c>();

        addOrRemoveQuoteLinesHelper(termDiscountWrapperList, quoteLinesToInsert, quoteLinesToDelete);
        
        if(!quoteLinesToInsert.isEmpty()){
            insert quoteLinesToInsert;
        }
        if(!quoteLinesToDelete.isEmpty()){
            delete quoteLinesToDelete.values(); 
        }
    }

    private void addOrRemoveQuoteLinesHelper(List<TermDiscountWrapper> termDiscountWrapperList, List<SBQQ__QuoteLine__c> quoteLinesToInsert, Map<String,SBQQ__QuoteLine__c> quoteLinesToDelete) {
        for(TermDiscountWrapper termDiscountWrapperItem : termDiscountWrapperList) {
            Integer commitmentTerm = getCommitmentTerm(termDiscountWrapperItem);
            Integer existingCommitmentTerm = getExistingCommitmentTerm(termDiscountWrapperItem);
            if(isCommitmentWorkSpace(commitmentTerm, existingCommitmentTerm, termDiscountWrapperItem)){
                continue;
            }
            if(isCommitProduct(commitmentTerm, existingCommitmentTerm, termDiscountWrapperItem)){
                if(termDiscountWrapperItem.startDate.Day() > 1){
                    if(isCommitmentGreater(commitmentTerm, existingCommitmentTerm)){
                        existingCommitmentTerm++;
                    }
                    commitmentTerm++;                    
                }
                quoteLinesToInsert.addAll(createQuoteLines(commitmentTerm, existingCommitmentTerm, termDiscountWrapperItem));
            }
            
            if(commitmentTerm < existingCommitmentTerm || commitmentTerm == existingCommitmentTerm){                
                if(termDiscountWrapperItem.startDate.Day() > 1){
                    commitmentTerm++;
                }
                processQuoteLinesToDelete(termDiscountWrapperItem, quoteLinesToDelete, commitmentTerm);
            }
        }
    }

    private Integer getCommitmentTerm(TermDiscountWrapper termDiscountWrapperItem) {
        return termDiscountWrapperItem.commitmentTermData.commitmentTerm != null ? Integer.ValueOf(termDiscountWrapperItem.commitmentTermData.commitmentTerm):0;
    }

    private Integer getExistingCommitmentTerm(TermDiscountWrapper termDiscountWrapperItem) {
        return Integer.valueof(termDiscountWrapperItem.quoteLineRecord.Commitment_Term__c != null ? termDiscountWrapperItem.quoteLineRecord.Commitment_Term__c:'0');
    }

    private Boolean isCommitmentGreater(Integer commitmentTerm, Integer existingCommitmentTerm) {
        return commitmentTerm > existingCommitmentTerm && existingCommitmentTerm != 0;
    }

    private Boolean isCommitmentWorkSpace(Integer commitmentTerm, Integer existingCommitmentTerm, TermDiscountWrapper termDiscountWrapperItem) {
        return (commitmentTerm == existingCommitmentTerm && termDiscountWrapperItem.startDate == termDiscountWrapperItem.quoteLineRecord.SBQQ__StartDate__c) ||termDiscountWrapperItem.isCommitmentWorkSpace == true;
    }

    private Boolean isCommitProduct(Integer commitmentTerm, Integer existingCommitmentTerm, TermDiscountWrapper termDiscountWrapperItem) {
        return termDiscountWrapperItem.displayItem.Contains(CPQConstants.PRODUCTCODE_COMMIT) && (commitmentTerm > existingCommitmentTerm || commitmentTerm == existingCommitmentTerm);
    }
    
    @testVisible
    private List<SBQQ__QuoteLine__c> createQuoteLines(Integer commitmentTerm, Integer existingCommitmentTerm, TermDiscountWrapper termDiscountWrapperItem) {
        List<SBQQ__QuoteLine__c> quoteLinesToInsert = new list<SBQQ__QuoteLine__c>();
        for(Integer j=existingCommitmentTerm; j<commitmentTerm; j++){
            Integer productNumber = j+1;
            Product2 product = TermBasedDiscountController.productWithNumbers.get(productNumber);
            SBQQ__QuoteLine__c quoteLine = new SBQQ__QuoteLine__c ();
            quoteLine.SBQQ__Quote__c = termDiscountWrapperItem.quoteLineRecord.SBQQ__Quote__c;
            quoteLine.CurrencyIsoCode = termDiscountWrapperItem.quoteLineRecord.SBQQ__Quote__r.CurrencyIsoCode;
            quoteLine.SBQQ__Product__c = product.Id;
            quoteLine.SBQQ__PriceEditable__c = product.SBQQ__PriceEditable__c;
            quoteLine.SBQQ__SubscriptionPricing__c = product.SBQQ__SubscriptionPricing__c;
            quoteLine.SBQQ__SubscriptionBase__c = product.SBQQ__SubscriptionBase__c;
            quoteLine.SBQQ__SubscriptionTerm__c = product.SBQQ__SubscriptionTerm__c;
            quoteLine.SBQQ__ChargeType__c = product.SBQQ__ChargeType__c;
            quoteLine.SBQQ__BillingType__c = product.SBQQ__BillingType__c;
            quoteLine.SBQQ__BillingFrequency__c = product.SBQQ__BillingFrequency__c;
            quoteLine.SBQQ__ProductSubscriptionType__c = product.SBQQ__SubscriptionType__c;
            quoteLine.SBQQ__SubscriptionType__c = product.SBQQ__SubscriptionType__c;
            quoteLine.SBQQ__DefaultSubscriptionTerm__c = product.SBQQ__SubscriptionTerm__c;
            quoteLine.SBQQ__ProrateMultiplier__c = product.SBQQ__SubscriptionTerm__c;
            quoteLine.SBQQ__Product__c = product.Id;
            quoteLine.Disable_Proration__c = product.Disable_Proration__c;
            quoteLine.Secondary_Sales_Item_UUID__c = product.Secondary_Sales_Item_UUID__c;
            quoteLine.SBQQ__ProductOption__c  = TermBasedDiscountController.productOptionWithNumbers.get(String.valueof(termDiscountWrapperItem.quoteLineRecord.SBQQ__Product__c+'-'+productNumber)).Id;
            quoteLine.SBQQ__RequiredBy__c = termDiscountWrapperItem.quoteLineId;
            quoteLine.SBQQ__Source__c = termDiscountWrapperItem.quoteLineId;
            quoteLine.SBQQ__Number__c = termDiscountWrapperItem.quoteLineRecord.SBQQ__Number__c +1;
            quoteLine.Inventory_Id__c = termDiscountWrapperItem.quoteLineRecord.Inventory_Id__c;
            quoteLine.Building_Id__c = termDiscountWrapperItem.quoteLineRecord.Building_Id__c;
            quoteLine.SBQQ__EndDate__c = termDiscountWrapperItem.quoteLineRecord.SBQQ__EndDate__c;
            quoteLine.SBQQ__Quantity__c = 1;            
            quoteLinesToInsert.add(quoteLine);
        }
        return quoteLinesToInsert;
    }

    @testVisible
    private void processQuoteLinesToDelete(TermDiscountWrapper termDiscountWrapperItem, Map<String,SBQQ__QuoteLine__c> quoteLinesToDelete, 
                                           Integer commitmentTerm) {
        for(SBQQ__QuoteLine__c quoteLine : quotelineSelector.getQuoteLinesByQuoteId(termDiscountWrapperItem.quoteLineRecord.SBQQ__Quote__c)){                        
            if(!quoteLine.SBQQ__Product__r.Name.startsWith('Month')){
                continue;
            }                   
            if(quoteLine.SBQQ__RequiredBy__c == termDiscountWrapperItem.quoteLineRecord.Id){
                Integer monthValue = Integer.valueof(quoteLine.SBQQ__ProductCode__c);
                if(monthValue > commitmentTerm){
                    quoteLinesToDelete.put(quoteLine.Id,quoteLine);
                }
            }
        }
    }

    public Map<Id,List<SBQQ__QuoteLine__c>> getParentQuoteLinesWithChilds(String quoteId){
        Map<Id,List<SBQQ__QuoteLine__c>> parentQuoteLinesWithChildQuoteLines = new Map<Id,List<SBQQ__QuoteLine__c>>();
        if(quoteId == null){
            return parentQuoteLinesWithChildQuoteLines;
        }       
        for(SBQQ__QuoteLine__c quoteLine : quoteLineSelector.getQuoteLinesByQuoteIdOrderByProductName(quoteId)){
            if(parentQuoteLinesWithChildQuoteLines.containsKey(quoteLine.SBQQ__RequiredBy__c )){
                List<SBQQ__QuoteLine__c> quoteLines = parentQuoteLinesWithChildQuoteLines.get(quoteLine.SBQQ__RequiredBy__c);
                quoteLines.add(quoteLine);
                parentQuoteLinesWithChildQuoteLines.put(quoteLine.SBQQ__RequiredBy__c, quoteLines);
            }else {
                parentQuoteLinesWithChildQuoteLines.put(quoteLine.SBQQ__RequiredBy__c, new List<SBQQ__QuoteLine__c>{quoteLine});
            }
        }
        return parentQuoteLinesWithChildQuoteLines;
    }
}