/*************************************************************************************************************************************
 Author      :   Salesforce
 Description :   This class is selector implementation of particular SObject (SBQQ__QuoteLine__c)
 --------------------------------------------------------------------------------------------------------------------------------------
 VERSION         DATE            AUTHOR              DETAIL
 1               14/7/2021       Salesforce        Initial Deployment
 **************************************************************************************************************************************/
public inherited sharing class QuoteLineSelector extends SObjectSelector {
    
    public QuoteLineSelector() {
        super(SBQQ__QuoteLine__c.getSObjectType());
    }
    
     /****************************************************************************************************************************
     Author              : Salesforce
     Description         : This method is used to get default fields from Object
     Created Date        : 14/7/2021
     *****************************************************************************************************************************/
    public override Set<String> getDefaultFields(){
        return new Set<String>{'Id', 'Name'};
    }
    
     /****************************************************************************************************************************
     Author              : Salesforce
     Description         : This method is used to get quoteLines record from quoteId
     Created Date        : 14/7/2021
     *****************************************************************************************************************************/
    public List<SBQQ__QuoteLine__c> getQuoteLinesByQuoteId(String quoteId){
        if(quoteId ==null){
            return null;
        }
        List<String> fields = new List<String>{'Id',
                'Name',
                'SBQQ__Product__r.Name',
                'Inventory_Id__r.UUID__c',
                'Inventory_Id__r.Name',
                'Inventory_Id__r.Type__c',
                'Commitment_Term__c',
                'SBQQ__RequiredBy__c',
                'SBQQ__RequiredBy__r.Commitment_Term__c',
                'SBQQ__Number__c',
                'Inventory_Id__c',
                'Building_Id__c',
                'SBQQ__EndDate__c',
                'SBQQ__Quote__c',
                'SBQQ__Quote__r.SBQQ__PricebookId__c',
                'SBQQ__ProductFamily__c',
                'SBQQ__Quote__r.Subscription_Type__c',
                'SBQQ__ProductCode__c',
                'SBQQ__ProductName__c',
                'SBQQ__RequiredBy__r.SBQQ__ProductFamily__c',
                'SBQQ__RequiredBy__r.SBQQ__Product__r.Name',
                'SBQQ__StartDate__c',
                'SBQQ__Quote__r.SBQQSC__MasterServiceContract__c',
                'SBQQ__ProductOption__c',
                'SBQQ__RequiredBy__r.SBQQ__StartDate__c'};
        return (List<SBQQ__QuoteLine__c>) getSObjectByField(fields, 'SBQQ__Quote__c', quoteId, false);
    }
    /****************************************************************************************************************************
     Author              : Salesforce
     Description         : This method is used to get quoteLines from inventoryIds and quoteId
     Created Date        : 14/7/2021
     *****************************************************************************************************************************/
    public List<SBQQ__QuoteLine__c> getQuoteLinesWithInventories(String quoteId, Set<String> inventoryIds){        
        if (quoteId == null) {
            return null;
        }
        List<String> fields = new List<String>{
                'Id',
                'SBQQ__RequiredBy__c',
                'SBQQ__Number__c',
                'SBQQ__ProductFamily__c',
                'SBQQ__Quote__c',
                'SBQQ__Product__r.Name',
                'Inventory_Id__c',
                'SBQQ__RequiredBy__r.SBQQ__ProductFamily__c'};
        String whereClause = '(SBQQ__Quote__c =: quoteId AND Inventory_Id__r.UUID__c NOT In:inventoryIds)';
        List<Object> bindings = new List<Object>{quoteId, inventoryIds};
        return (List<SBQQ__QuoteLine__c>) getSObjects(fields, whereClause, bindings);
    }
    
    /****************************************************************************************************************************
     Author              : Salesforce
     Description         : This method is used to get quoteLines from inventoryIds and quoteId
     Created Date        : 14/7/2021
     *****************************************************************************************************************************/
    public List<SBQQ__QuoteLine__c> getQuoteLinesByQuoteIdAndProductCode(String quoteId){
        if (quoteId == null) {
            return null;
        }
        List<String> fields = new List<String>{
                'Id',
                'SBQQ__Quote__r.CurrencyIsoCode',
                'SBQQ__Product__r.ProductCode',
                'SBQQ__Product__r.Name',
                'SBQQ__Quote__c',
                'SBQQ__Quote__r.Subscription_Type__c',
                'SBQQ__Number__c',
                'Inventory_Id__c',
                'Inventory_Id__r.Name',
                'Commitment_Term__c',
                'SBQQ__StartDate__c',
                'Building_Id__c',
                'Inventory_Id__r.UUID__c',
                'SBQQ__RequiredBy__c',
                'SBQQ__Quote__r.SBQQ__PricebookId__c',
                'SBQQ__ProductCode__c',
                'Promo_Code_Id__r.Name',
                'SBQQ__RequiredBy__r.SBQQ__ProductFamily__c',
                'SBQQ__ProductFamily__c',
                'SBQQ__ProductName__c',
                'SBQQSC__UpgradedContractLine__c',
                'QuoteLineSource__c'};
        String whereClause = 'SBQQ__Quote__c = :quoteId';
        List<Object> bindings = new List<Object>{quoteId};
        return (List<SBQQ__QuoteLine__c>) getSObjects(fields, whereClause, bindings);
    }
    
    
    /****************************************************************************************************************************
     Author              : Salesforce
     Description         : This method is used to get monthly QuoteLines by QuoteID
     Created Date        : 15/7/2021
     *****************************************************************************************************************************/
    public List<SBQQ__QuoteLine__c> getQuoteLinesByQuoteIdOrderByProductName(String quoteId){
        if(quoteId==null){
            return null;
        }
        List<String> fields = new List<String>{'Id',
            'SBQQ__RequiredBy__c',
            'SBQQ__RequiredBy__r.SBQQ__EndDate__c',
            'SBQQ__Source__c',
            'SBQQ__Product__c',
            'SBQQ__Product__r.Name',
            'Inventory_Id__r.List_Price__c',
            'SBQQ__ProductFamily__c',
            'SBQQ__Quote__c',
            'SBQQ__Number__c',
            'Disable_Proration__c',
            'SBQQ__RequiredBy__r.SBQQ__ProductFamily__c',
            'SBQQ__RequiredBy__r.SBQQ__Product__c',
            'SBQQ__ProductCode__c'            
            };
        String whereClause = 'SBQQ__Quote__c = :quoteId AND SBQQ__RequiredBy__c != null';
        String orderByClause = 'SBQQ__Product__r.ProductCode, SBQQ__RequiredBy__c NULLS LAST';
        List<Object> bindings = new List<Object>{quoteId};
        return (List<SBQQ__QuoteLine__c>) getSObjects(fields, whereClause, bindings, orderByClause);
    }
    
    
    /****************************************************************************************************************************
     Author              : Salesforce
     Description         : This method is used to get quoteLines from inventoryIds and quoteId
     Created Date        : 14/7/2021
     *****************************************************************************************************************************/
    public List<SBQQ__QuoteLine__c> getQuoteLinesByInventoryUUIDs(Set<String> inventoryIds, String quoteId){
        if (quoteId == null || inventoryIds.isEmpty()) {
            return null;
        }
        List<String> fields = new List<String>{
                'Id',
                'SBQQ__ProductCode__c',
                'SBQQ__Product__r.Name',
                'SBQQ__RequiredBy__c',
                'SBQQ__RequiredBy__r.Commitment_Term__c',
                'Commitment_Term__c',
                'SBQQ__Quote__c',
                'Inventory_Id__r.UUID__c'};
        String whereClause = '( Inventory_Id__r.UUID__c IN:inventoryIds AND SBQQ__Quote__c = :quoteId)';
        List<Object> bindings = new List<Object>{inventoryIds, quoteId};
        return (List<SBQQ__QuoteLine__c>) getSObjects(fields, whereClause, bindings);
    }
    
    public List<SBQQ__QuoteLine__c> getQuoteLinesByQuoteIdAndInventoryIds(Set<String> quoteIds, Set<String> productCodes){
        if(quoteIds.isEmpty()){
            return null;
        }
        List<String> fields = new List<String>{
                'Id', 'SBQQ__Number__c','SBQQ__Quote__r.SBQQ__PricebookId__c', 'Inventory_Id__c', 'SBQQ__Quote__c', 'CurrencyIsoCode', 'SBQQ__Product__c', 'SBQQ__SubscriptionPricing__c',
                'Commitment_Term__c', 'SBQQ__SubscriptionBase__c', 'SBQQ__SubscriptionTerm__c', 'SBQQ__ProductSubscriptionType__c', 'SBQQ__SubscriptionType__c',
                'SBQQ__DefaultSubscriptionTerm__c','SBQQ__ProrateMultiplier__c','SBQQ__Quantity__c','SBQQ__PricebookEntryId__c', 'SBQQ__ChargeType__c',
                'SBQQ__BillingType__c','SBQQ__BillingFrequency__c','Disable_Proration__c','SBQQ__PriceEditable__c', 'SBQQ__RequiredBy__c', 'SBQQ__Source__c',
                'SBQQ__ProductOption__c','SBQQ__StartDate__c', 'SBQQ__EndDate__c', 'Segment_End_Date__c', 'Maximum_Discount__c', 'SBQQ__AdditionalDiscount__c',
                'SBQQ__PartnerDiscount__c','Building_Id__c', 'Discount_End_Date__c', 'SBQQ__ListPrice__c', 'SBQQ__EffectiveStartDate__c','SBQQSC__UpgradedContractLine__c',
                'New_Move_in_Date__c','Inventory_Id__r.List_Price__c','SBQQ__ProductName__c','New_End_Date__c','SBQQ__ProductCode__c','SBQQ__ProductFamily__c','SBQQ__EffectiveEndDate__c',
                'SBQQ__RequiredBy__r.SBQQ__ProductName__c','SBQQ__RequiredBy__r.Inventory_Id__c','QuoteLineSource__c','SBQQ__Discount__c','Quote_Line_Billing_Status__c'};
                String whereClause = '( SBQQ__Quote__c IN : quoteIds AND SBQQ__ProductCode__c NOT IN : productCodes)';
                String orderByClause = 'Name';
                List<Object> bindings = new List<Object>{quoteIds, productCodes};
                return (List<SBQQ__QuoteLine__c>) getSObjects(fields, whereClause, bindings, orderByClause); 
        
    }
    
    public List<SBQQ__QuoteLine__c> getQuoteLinesByIds(Set<String> quoteLineIds){
        if(quoteLineIds.isEmpty()){
            return null;
        }
        List<String> fields = new List<String>{
            'Id',            
            'SBQQ__Product__r.Name',
            'Inventory_Id__c',
            'SBQQ__ProductFamily__c',
            'SBQQ__ProductCode__c',
            'SBQQ__Number__c',
            'New_Move_in_Date__c',
            'SBQQ__StartDate__c',
            'SBQQ__EndDate__c',
            'Segment_End_Date__c',
            'Inventory_Id__r.List_Price__c',
            'New_End_Date__c',
            'SBQQ__Quote__r.SBQQ__PricebookId__c',
            'SBQQ__Product__c',
            'SBQQ__RequiredBy__c',
            'SBQQ__RequiredBy__r.Inventory_Id__c',
            'SBQQ__ProductName__c'
        };
        String whereClause = 'Id IN :quoteLineIds';
        String orderByClause = 'Inventory_Id__c,SBQQ__RequiredBy__c,SBQQ__ProductCode__c';
        List<Object> bindings = new List<Object>{quoteLineIds};            
        return (List<SBQQ__QuoteLine__c>) getSObjects(fields, whereClause, bindings,orderByClause);
    }
    
}