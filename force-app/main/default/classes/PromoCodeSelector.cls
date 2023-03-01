/*************************************************************************************************************************************
 Author      :   Salesforce
 Description :   This class is selector implementation of particular SObject (Promo_Code__c)
 --------------------------------------------------------------------------------------------------------------------------------------
 VERSION         DATE            AUTHOR              DETAIL
 1               08/21/2021       Salesforce        Initial Deployment
 **************************************************************************************************************************************/
public inherited sharing class PromoCodeSelector extends SObjectSelector {
    public PromoCodeSelector() {
        super(Promo_Code__c.getSObjectType());
    }
    
    public override Set<String> getDefaultFields(){
        return new Set<String>{'Id', 'Name'};
    }
    
    public List<Promo_Code__c> getPromoCodesByExpiryAndPercent(Set<String> inventoryTypes, Date expiryDate, Integer percent){
        if (expiryDate == null || percent == null) {
            return null;
        }
        List<String> fields = new List<String>{
                'Id',
                'Name',
                'Type__c',
                'Percent__c',
                'Duration__c'};
        String whereClause = '(Type__c IN :inventoryTypes AND Expiry_Date__c >=: expiryDate AND Percent__c != :percent)';        
        String orderByClause = 'Percent__c';
        List<Object> bindings = new List<Object>{inventoryTypes, expiryDate, percent};    
        return (List<Promo_Code__c>) getSObjects(fields, whereClause, bindings,orderByClause);
    }    
}