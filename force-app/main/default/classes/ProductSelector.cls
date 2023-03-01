/*************************************************************************************************************************************
 Author      :   Silpa Putti
 Description :   This class is selector implementation of particular SObject (Product2)
 --------------------------------------------------------------------------------------------------------------------------------------
 VERSION         DATE            AUTHOR              DETAIL
 1               14/7/2021       Silpa Putti        Initial Deployment
 **************************************************************************************************************************************/
public inherited sharing class ProductSelector extends SObjectSelector {
    public ProductSelector() {
        super(Product2.getSObjectType());
    }
    /****************************************************************************************************************************
     Author              : Silpa Putti
     Description         : This method is used to get default fields from Object
     Created Date        : 14/7/2021
     *****************************************************************************************************************************/
    public override Set<String> getDefaultFields(){
        return new Set<String>{'Id', 'Name'};
    }
    
    /****************************************************************************************************************************
     Author              : Silpa Putti
     Description         : This method is used to get product records from product name
     Created Date        : 14/7/2021
     *****************************************************************************************************************************/
    public List<Product2> getProductByProductCode(Set<String> productCodes){
        if(productCodes.isEmpty()){
            return null;
        }
        List<String> fields = new List<String>{'Id',
            'SBQQ__SubscriptionPricing__c',
            'SBQQ__SubscriptionBase__c',
            'SBQQ__SubscriptionTerm__c',
            'SBQQ__SubscriptionType__c',
            'ProductCode',
            'SBQQ__ChargeType__c',
            'SBQQ__BillingType__c',
            'SBQQ__BillingFrequency__c',
            'Disable_Proration__c',
            'Name',
            'SBQQ__PriceEditable__c',
            'Secondary_Sales_Item_UUID__c'
            };
         String whereClause = 'ProductCode IN :productCodes';
        List<Object> bindings = new List<Object>{productCodes};
        return (List<Product2>) getSObjects(fields, whereClause, bindings);
    }
    /****************************************************************************************************************************
     Author              : Silpa Putti
     Description         : This method is used to get product records from product name
     Created Date        : 15/7/2021
     *****************************************************************************************************************************/
    public List<Product2> getProductWithSubscriptionsOrderByProductName(List<String> productNames){
        if(productNames.isEmpty()){
            return null;
        }
        List<String> fields = new List<String>{'Id',
            'SBQQ__SubscriptionPricing__c',
            'SBQQ__SubscriptionBase__c',
            'SBQQ__SubscriptionTerm__c',
            'SBQQ__ChargeType__c',
            'SBQQ__SubscriptionType__c',
            'SBQQ__BillingType__c',
            'SBQQ__BillingFrequency__c',
            'Disable_Proration__c',
            'Name',
            'SBQQ__PriceEditable__c',
            'ProductCode',
            'Secondary_Sales_Item_UUID__c'
            };
        String whereClause = 'Name IN :productNames AND IsActive = true';
        List<Object> bindings = new List<Object>{productNames};
        return (List<Product2>) getSObjects(fields, whereClause, bindings);
    }  
}