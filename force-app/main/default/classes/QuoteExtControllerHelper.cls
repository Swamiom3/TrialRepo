public with sharing class QuoteExtControllerHelper {
    public static ContractLineItemSelector contractLineItemSelector = new ContractLineItemSelector();
    public static Set<Id> serviceContracts = new Set<ID>();
    public static Set<Id> parentQuoteLineInventoryIds = new Set<ID>();    
    public static Set<Id> contractLineItemInventoryIds = new Set<ID>();
    
    public static List<String> allAccessAndCommitProducts = new List<String>{
        CPQConstants.PRODUCT_COMMIT,
        GlobalConstants.ALL_ACCESS,
        GlobalConstants.ALL_ACCESS_DYNAMIC,
        GlobalConstants.ALL_ACCESS_PAY_PER_USE
    };
    public Boolean techBundleExists(List<SBQQ__QuoteLine__c> quoteLines){
        Boolean result = false;
        for (SBQQ__QuoteLine__c quoteLine : quoteLines) {
            if (quoteLine.SBQQ__Product__r.Name.Contains(CPQConstants.TECH_BUNDLE)) {
                result = true;
                continue;
            }
        }
        return result;
    }    
    public Boolean isAddOnInventoryExists(List<SBQQ__QuoteLine__c> quoteLines){
        Boolean result = false;
        for(SBQQ__QuoteLine__c quoteLine : quoteLines){
            if(quoteLine.SBQQ__ProductFamily__c == CPQConstants.ADD_ON && quoteLine.Inventory_Id__c == null){
                result = true;
                continue;
            }
        }
        return result;
    }
    public Boolean isCommitmentError(List<SBQQ__QuoteLine__c> quoteLines){
        Boolean result = false;
        for(SBQQ__QuoteLine__c quoteLine : quoteLines){
            if (quoteLine.SBQQ__Quote__r.Subscription_Type__c != CPQConstants.SUBSCRIPTION_M2M &&
                allAccessAndCommitProducts.contains(quoteLine.SBQQ__Product__r.Name) &&
                quoteLine.Commitment_Term__c == null) {
                result = true;
                continue;
            }        
        }
        return result;
    }
    
    public Boolean isAddOnInventoryMatchParent(List<SBQQ__QuoteLine__c> quoteLines){
        Boolean result = false;
        for (Id addonInventoryId : buildInventoryIds(quoteLines)) {
            if (checkAddOnInventoryError(addonInventoryId)) {system.debug('*** Enter method');
                result = true;
                continue;
            }
        }
        return result;
    }
    
    private Set<Id> buildInventoryIds(List<SBQQ__QuoteLine__c> quoteLines){
        Set<Id> addOnInventoryIds = new Set<ID>();
        for(SBQQ__QuoteLine__c quoteLine : quoteLines){
            if (quoteLine.SBQQ__RequiredBy__c == null &&
                quoteLine.Inventory_Id__c != null &&
                quoteLine.SBQQ__ProductFamily__c != CPQConstants.ADD_ON) {
                parentQuoteLineInventoryIds.add(quoteLine.Inventory_Id__c);
            }
            if (quoteLine.SBQQ__ProductFamily__c == CPQConstants.ADD_ON && quoteLine.Inventory_Id__c != null) {
                addOnInventoryIds.add(quoteLine.Inventory_Id__c);
            }
        }
        serviceContracts.add(quoteLines.get(0).SBQQ__Quote__r.SBQQSC__MasterServiceContract__c);
        
        if (!serviceContracts.isEmpty()) {
            for (ContractLineItem contractLineItem : contractLineItemSelector.getContractItemsByServiceContractId(serviceContracts)) {
                contractLineItemInventoryIds.add(contractLineItem.Inventory_Id__c);
            }
        }
        return addOnInventoryIds;        
    }    
    private static Boolean checkAddOnInventoryError(Id addonInventoryId) {
        return ((parentQuoteLineInventoryIds.isEmpty() && contractLineItemInventoryIds.isEmpty()) ||
                 ((!parentQuoteLineInventoryIds.isEmpty() && !parentQuoteLineInventoryIds.contains(addonInventoryId) && contractLineItemInventoryIds.isEmpty())) ||
                 (!contractLineItemInventoryIds.isEmpty() && !contractLineItemInventoryIds.contains(addonInventoryId) && parentQuoteLineInventoryIds.isEmpty() ));        
    }
}