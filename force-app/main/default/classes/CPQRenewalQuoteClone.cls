public with sharing class CPQRenewalQuoteClone {
    public static QuoteLineSelector quoteLineSelector = new QuoteLineSelector();
    public static ProductSelector productSelector = new ProductSelector();
    public static QuoteSelector quoteSelector = new QuoteSelector();
    public static ProductOptionSelector productOptionSelector =new ProductOptionSelector();
    private static List<String> productNames = new List<String>();
    private static Map<Integer, Product2> productWithNumbers = new Map<Integer, Product2>();
    private static Map<Decimal,SBQQ__ProductOption__c> productOptionWithNumbers = new Map<Decimal,SBQQ__ProductOption__c>();
    private static List<String> monthlyLinestoRemove = new List<String>();
    private static List<String> ammendQuoteLines = new List<String>();
    private static Set<String> ammendQuoteIds = new Set<String>();
    private static Set<String> selectedBundleLines = new Set<String>();
    private static String renewalQuoteId;
    private static Map<String,PricebookEntry> productNameWithPriceBookEntries = new Map<String,PricebookEntry>();
    private static List<SBQQ__QuoteLine__c> cloneList = new List<SBQQ__QuoteLine__c>();
    private static List<SBQQ__QuoteLine__c> newMonthlyLines = new List<SBQQ__QuoteLine__c>();
    private static CPQRenewalQuoteCloneHelper helper = new CPQRenewalQuoteCloneHelper();
    private static Set<String> excludeProductCodes = new Set<String>{'SETUP-FEE', 'SRVC-RTNR'};
    private static Integer numberOfMonths = 0;
    private static Date newMoveInDate;
    private static Date newEndDate;

    @InvocableMethod(label='Clone Quote Lines' description='Clone Quote Lines')
    public static List<CloneQuoteResponse> cloneQuoteWithQuoteLines(List<RenewalQuoteCloneWrapper> renewalQuoteWrapperList){        
        if(renewalQuoteWrapperList.isEmpty()){
            return null;
        }
        List<CloneQuoteResponse> cloneQuoteResponses = new List<CloneQuoteResponse>();   
        CloneQuoteResponse cloneQuoteResponse = new CloneQuoteResponse();
        String action;
        String pricebookId;
        Date actionDate;
        for(RenewalQuoteCloneWrapper renewalQuoteWrapItem : renewalQuoteWrapperList){
            ammendQuoteIds.addAll(renewalQuoteWrapItem.ammendQuoteIds);
            renewalQuoteId = renewalQuoteWrapItem.renewalQuoteId;
            action = renewalQuoteWrapItem.action;
            actionDate = renewalQuoteWrapItem.actionDate;
            selectedBundleLines.addAll(renewalQuoteWrapItem.selectedBundleLines);
        }   
        if(renewalQuoteId != null){
           pricebookId =  QuoteSelector.getQuoteByIdWithSubscriptionType(renewalQuoteId)[0].SBQQ__PricebookId__c;
        }
        if(pricebookId != null){
            productNameWithPriceBookEntries = TermBasedDiscountController.getPriceBookEntries(pricebookId);
        }
        
        compileProductWithProductOptions();
        cloneQuoteLines(ammendQuoteIds,action,actionDate);
        if(!cloneList.isEmpty()){
            insert cloneList;
        }
        
        if(!cloneList.isEmpty()){
            Map<String, String> parentLines = new Map<String, String>();
            Set<Id> clonedQuoteLineIds = (new Map<Id,SBQQ__QuoteLine__c>(cloneList)).keySet();  
            Set<String> quoteLineIds = (Set<String>)JSON.deserialize(JSON.serialize(clonedQuoteLineIds), Set<String>.class);          
            List<SBQQ__QuoteLine__c> clonedLines = quoteLineSelector.getQuoteLinesByIds(quoteLineIds);
            parentLines = helper.getParentLines(clonedLines);
            helper.updateRequiredByOnChildLines(clonedLines, parentLines);
        }
        cloneQuoteResponse.amendQuoteLines = ammendQuoteLines;
        cloneQuoteResponses.add(cloneQuoteResponse);        
        return cloneQuoteResponses;
    }

    private static void compileProductWithProductOptions(){
        for(Integer i=0; i< 60; i++){
            productNames.add('month ' +(i+1));
        }
        for(Product2 product : productSelector.getProductWithSubscriptionsOrderByProductName(productNames)){
            productWithNumbers.put(Integer.valueOf(product.ProductCode), product);
        }
        for(SBQQ__ProductOption__c productOption : productOptionSelector.getProductOptionsBySBQQNumber(60)){
            productOptionWithNumbers.put(productOption.SBQQ__Number__c , productOption);
        }
    }
    
    private static void cloneQuoteLines(Set<String> ammendQuoteIds,String action, Date actionDate){
        for(SBQQ__QuoteLine__c quoteLine : quoteLineSelector.getQuoteLinesByQuoteIdAndInventoryIds(ammendQuoteIds, excludeProductCodes)){
            if(helper.checkSelectedBundleLines(selectedBundleLines, quoteLine)){
                continue;
            }
            ammendQuoteLines.add(quoteLine.Id);          
            SBQQ__QuoteLine__c quoteLineClone = quoteLine.clone(false, false, false, false);
            quoteLineClone.SBQQ__Quote__c =  renewalQuoteId;
            if(productNameWithPriceBookEntries.containskey(quoteLine.SBQQ__Product__c)){
                quoteLineClone.SBQQ__PricebookEntryId__c = productNameWithPriceBookEntries.get(quoteLine.SBQQ__Product__c).Id;
            }
            quoteLineClone.SBQQ__StartDate__c = quoteLine.SBQQ__EffectiveStartDate__c;
            quoteLineClone.SBQQ__EndDate__c = quoteLine.SBQQ__EffectiveEndDate__c;
            cloneQuoteLinesStartDateAndEndDate(action,quoteLineClone,quoteLine,actionDate);
            quoteLineClone.SBQQ__Number__c = null;
            quoteLineClone.SBQQ__RequiredBy__c = null;
            quoteLineClone.QuoteLineSource__c = CPQConstants.AMENDMENT_CLONE;
            quoteLineClone.SBQQSC__UpgradedContractLine__c = null;
            if(!newMonthlyLines.isEmpty() && quoteLineClone.SBQQ__ProductName__c == CPQConstants.PRODUCTCODE_CONF_ROOM_CREDIT){
                cloneList.addALL(newMonthlyLines);
                newMonthlyLines.clear();
            }        
            cloneList.add(quoteLineClone);
        }
    }

    private static void cloneQuoteLinesStartDateAndEndDate(String action,SBQQ__QuoteLine__c quoteLineClone,SBQQ__QuoteLine__c quoteLine,Date actionDate){
        if(helper.isPhysicalAccessMoveInDate(quoteLine, action)){
            numberOfMonths=0;
            newMoveInDate = quoteLine.New_Move_in_Date__c;
            quoteLineClone.SBQQ__StartDate__c = quoteLine.New_Move_in_Date__c;
            Integer monthsbetweenStartandNewMoveInDate = quoteLine.SBQQ__EffectiveStartDate__c.monthsBetween(quoteLine.New_Move_in_Date__c);
            newEndDate = quoteLineClone.SBQQ__EndDate__c = quoteLine.SBQQ__EffectiveEndDate__c.addMonths(monthsbetweenStartandNewMoveInDate+1).toStartofMonth().addDays(-1);
            quoteLineClone.Segment_End_Date__c = quoteLine.SBQQ__EffectiveEndDate__c.addMonths(monthsbetweenStartandNewMoveInDate+1).toStartofMonth().addDays(-1);
        } else if(helper.isPhysicalAccessAmend(quoteLine, action)) {
            newEndDate = quoteLine.New_End_Date__c;
            quoteLineClone.SBQQ__EndDate__c = quoteLine.New_End_Date__c;
            quoteLineClone.Segment_End_Date__c = quoteLine.New_End_Date__c;
            compileQuoteLineWithAmmedTerm(quoteLine, quoteLine.New_End_Date__c);
        } else if(action!=CPQConstants.CHANGE_MOVEIN_DATE_ACTION && !helper.verifyMonthProdActionDate(quoteLine, quoteLineClone, action, actionDate)){
            return;
        } else if(helper.isMonthProdAmendAction(quoteLine, action)){
            quoteLineClone.SBQQ__EndDate__c = newEndDate;
            quoteLineClone.SBQQ__StartDate__c = quoteLine.SBQQ__EffectiveStartDate__c;
        } else if(helper.isMonthProdMoveInAction(quoteLine, action)){
            quoteLineClone.SBQQ__StartDate__c = newMoveInDate.addMonths(numberOfMonths).toStartOfMonth();
            quoteLineClone.Segment_End_Date__c  = quoteLineClone.SBQQ__StartDate__c.addMonths(1).tostartOfMonth().adddays(-1);
            quoteLineClone.SBQQ__EndDate__c = newEndDate;
            numberOfMonths++;
        } else {
            helper.processQuoteLine(quoteLine, quoteLineClone, action, newMoveInDate, newEndDate);
        } 
    }

    @testVisible
    private static void compileQuoteLineWithAmmedTerm(SBQQ__QuoteLine__c quoteLine, Date newEndDate){
            Integer monthsBetweenStartAndEndDate=0;
            Integer monthsBetweenStartDateAndNewEndDate=0;
            Date startDate = quoteLine.SBQQ__EffectiveStartDate__c != null ? quoteLine.SBQQ__EffectiveStartDate__c : quoteLine.SBQQ__StartDate__c;
            Date actualEndDate = quoteLine.SBQQ__EffectiveEndDate__c != null ? quoteLine.SBQQ__EffectiveEndDate__c : quoteLine.Segment_End_Date__c != null ?  quoteLine.Segment_End_Date__c :  quoteLine.SBQQ__EndDate__c;
            Date monthBeginning = startDate.toStartOfMonth();
           
            monthsBetweenStartAndEndDate = Date.newInstance(startDate.year(),startDate.Month(),startDate.day()).monthsBetween(Date.newInstance(actualEndDate.year(),actualEndDate.Month(),actualEndDate.day())) + 1;
            monthsBetweenStartDateAndNewEndDate = Date.newInstance(startDate.year(),startDate.Month(),startDate.day()).monthsBetween(Date.newInstance(quoteLine.New_End_Date__c.year(),quoteLine.New_End_Date__c.Month(),quoteLine.New_End_Date__c.day())) + 1;
            
            if(quoteLine.New_End_Date__c > actualEndDate){
                addMonthlyLine(renewalQuoteId,monthsBetweenStartAndEndDate,monthsBetweenStartDateAndNewEndDate,quoteLine, newEndDate);                
            }else if(quoteLine.New_End_Date__c < quoteLine.SBQQ__EffectiveEndDate__c){
                for(Integer i=monthsBetweenStartDateAndNewEndDate; i<monthsBetweenStartAndEndDate;i++){
                    monthlyLinestoRemove.add(String.valueof(i)+'-'+quoteLine.Inventory_Id__c);
                }
            }
    }
    private static void addMonthlyLine(String renewalQuoteId,Integer monthsBetweenStartAndEndDate,Integer monthsBetweenStartDateAndNewEndDate,SBQQ__QuoteLine__c quoteLine, Date newEndDate){
        for(Integer i=monthsBetweenStartAndEndDate+1; i<= monthsBetweenStartDateAndNewEndDate;i++){
            Product2 product = productWithNumbers.get(i);
            SBQQ__QuoteLine__c monthlyQuoteLine = new SBQQ__QuoteLine__c ();
            monthlyQuoteLine.SBQQ__Quote__c = renewalQuoteId;
            monthlyQuoteLine.CurrencyIsoCode = quoteLine.CurrencyIsoCode;
            monthlyQuoteLine.SBQQ__Product__c = product.Id;
            monthlyQuoteLine.SBQQ__PriceEditable__c = product.SBQQ__PriceEditable__c;
            monthlyQuoteLine.SBQQ__SubscriptionPricing__c = product.SBQQ__SubscriptionPricing__c;
            monthlyQuoteLine.SBQQ__SubscriptionBase__c = product.SBQQ__SubscriptionBase__c;
            monthlyQuoteLine.SBQQ__SubscriptionTerm__c = product.SBQQ__SubscriptionTerm__c;
            monthlyQuoteLine.SBQQ__ChargeType__c = product.SBQQ__ChargeType__c;
            monthlyQuoteLine.SBQQ__BillingType__c = product.SBQQ__BillingType__c;
            monthlyQuoteLine.SBQQ__BillingFrequency__c = product.SBQQ__BillingFrequency__c;
            monthlyQuoteLine.SBQQ__ProductSubscriptionType__c = product.SBQQ__SubscriptionType__c;
            monthlyQuoteLine.SBQQ__SubscriptionType__c = product.SBQQ__SubscriptionType__c;
            monthlyQuoteLine.SBQQ__DefaultSubscriptionTerm__c = product.SBQQ__SubscriptionTerm__c;
            monthlyQuoteLine.SBQQ__ProrateMultiplier__c = product.SBQQ__SubscriptionTerm__c;
            monthlyQuoteLine.SBQQ__Product__c = product.Id;
            monthlyQuoteLine.Disable_Proration__c = product.Disable_Proration__c;
            monthlyQuoteLine.SBQQ__ProductOption__c  = productOptionWithNumbers.get(i).Id;
            monthlyQuoteLine.SBQQ__RequiredBy__c = null;
            monthlyQuoteLine.SBQQ__StartDate__c = quoteLine.SBQQ__EffectiveStartDate__c.toStartOfMonth().addMonths(i-1);
            Date enddate = monthlyQuoteLine.SBQQ__StartDate__c.addMonths(1);
            enddate =enddate.addDays(-1);
            monthlyQuoteLine.Segment_End_Date__c = enddate;
            monthlyQuoteLine.SBQQ__EndDate__c = newEndDate;
            monthlyQuoteLine.Inventory_Id__c = quoteLine.Inventory_Id__c;
            monthlyQuoteLine.SBQQ__ListPrice__c = quoteLine.Inventory_Id__r.List_Price__c;
            monthlyQuoteLine.Building_Id__c = quoteLine.Building_Id__c;
            monthlyQuoteLine.SBQQ__Quantity__c = 1;
            if(productNameWithPriceBookEntries.containskey(product.Id)){
                monthlyQuoteLine.SBQQ__PricebookEntryId__c = productNameWithPriceBookEntries.get(product.Id).Id;                
            }
            if(productNameWithPriceBookEntries.containskey(quoteLine.SBQQ__Product__c)){
                Decimal listPrice = monthlyQuoteLine.Inventory_Id__c == null ? productNameWithPriceBookEntries.get(quoteLine.SBQQ__Product__c).UnitPrice : monthlyQuoteLine.SBQQ__ListPrice__c;
                monthlyQuoteLine.SBQQ__ListPrice__c = listPrice;
            }
            monthlyQuoteLine.QuoteLineSource__c = CPQConstants.AMENDMENT_CLONE;
            newMonthlyLines.add(monthlyQuoteLine);
        }
    }
    
    public class RenewalQuoteCloneWrapper{ 
        @InvocableVariable(required=true)
        @TestVisible public List<String> ammendQuoteIds;       
        @InvocableVariable(required=true)
        @TestVisible public List<String> selectedBundleLines;
        @InvocableVariable(required=true)
        @TestVisible public String renewalQuoteId;
        @InvocableVariable(required=true)
        @TestVisible public String action;
        @InvocableVariable(required=true)
        @TestVisible public Date actionDate;
    }
    public class CloneQuoteResponse {
        @InvocableVariable 
        public List<String> amendQuoteLines;
    }
}