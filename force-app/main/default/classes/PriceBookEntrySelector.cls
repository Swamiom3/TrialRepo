/*************************************************************************************************************************************
 Author      :   Silpa Putti
 Description :   This class is selector implementation of particular SObject (PricebookEntry)
 --------------------------------------------------------------------------------------------------------------------------------------
 VERSION         DATE            AUTHOR              DETAIL
 1               15/7/2021       Silpa Putti        Initial Deployment
 **************************************************************************************************************************************/
public inherited sharing class PriceBookEntrySelector extends SObjectSelector {
    public PriceBookEntrySelector() {
        super(PriceBookEntry.getSObjectType());
    }
    
    /****************************************************************************************************************************
     Author              : Silpa Putti
     Description         : This method is used to get default fields from Object
     Created Date        : 15/7/2021 
     *****************************************************************************************************************************/
    public override Set<String> getDefaultFields(){
        return new Set<String>{'Id', 'Name'};
    }
    
     /****************************************************************************************************************************
     Author              : Silpa Putti
     Description         : This method is used to get PricebookEntry records from pricebookId
     Created Date        : 15/7/2021
     *****************************************************************************************************************************/
    public List<PricebookEntry> getPriceBookEntriesbyPriceBookIdAndProductId(String priceBookId, String productId){
        if (priceBookId == null || productId == null) {
            return null;
        }
        List<String> fields = new List<String>{
                'Id',
                'Product2Id'};
        String whereClause = '(Pricebook2Id =: priceBookId AND Product2Id = :productId)';
        List<Object> bindings = new List<Object>{priceBookId, productId};
        return (List<PriceBookEntry>) getSObjects(fields, whereClause, bindings);
    }
    
     /****************************************************************************************************************************
     Author              : Silpa Putti
     Description         : This method is used to get PricebookEntry records from pricebookId
     Created Date        : 15/7/2021
     *****************************************************************************************************************************/
    public List<PriceBookEntry> getPriceBookEntriesbyPriceBookId(String priceBookId){
        if (priceBookId == null) {
            return null;
        }
        List<String> fields = new List<String>{
                'Id',
                'Product2Id',
                'UnitPrice'};
        String whereClause = '(Pricebook2Id = :priceBookId)';
        List<Object> bindings = new List<Object>{priceBookId};
        return (List<PriceBookEntry>) getSObjects(fields, whereClause, bindings);
    }
    
    /****************************************************************************************************************************
     Author              : Silpa Putti
     Description         : This method is used to get PricebookEntry records from pricebookId
     Created Date        : 15/7/2021
     *****************************************************************************************************************************/
    public List<PricebookEntry> getPriceBookEntriesbyPriceBookIdAndProductFamily(String priceBookId, String productFamily){
        if (priceBookId == null || productFamily == null) {
            return null;
        }
        List<String> fields = new List<String>{
                'Id',
                'Product2Id',
                'Product2.Family',
                'Product2.SBQQ__Component__c'};
        String whereClause = '(Pricebook2Id = :priceBookId AND Product2.Family != :productFamily)';
        List<Object> bindings = new List<Object>{priceBookId, productFamily};
        return (List<PriceBookEntry>) getSObjects(fields, whereClause, bindings);
    }
}