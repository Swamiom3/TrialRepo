/*************************************************************************************************************************************
 Author      :   Silpa Putti
 Description :   This class is selector implementation of particular SObject (SBQQ__ProductOption__c)
 --------------------------------------------------------------------------------------------------------------------------------------
 VERSION         DATE            AUTHOR              DETAIL
 1               15/7/2021       Silpa Putti        Initial Deployment
 **************************************************************************************************************************************/
public inherited sharing class ProductOptionSelector extends SObjectSelector {
	
    public ProductOptionSelector() {
        super(SBQQ__ProductOption__c.getSObjectType());
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
     Description         : This method is used to get ProductOption records from Product Name
     Created Date        : 15/7/2021
     *****************************************************************************************************************************/
    public List<SBQQ__ProductOption__c> getProductOptionByProductCode(List<String> productNames){
        if(productNames.isEmpty()){
            return null;
        }
        List<String> fields = new List<String>{'Id','SBQQ__ProductName__c','SBQQ__ConfiguredSKU__c'};
        String whereClause = 'SBQQ__ProductName__c IN :productNames';
        List<Object> bindings = new List<Object>{productNames};
        return (List<SBQQ__ProductOption__c>) getSObjects(fields, whereClause, bindings);
    }
    
     /****************************************************************************************************************************
     Author              : Silpa Putti
     Description         : This method is used to get productoption from product name
     Created Date        : 15/7/2021
     *****************************************************************************************************************************/
    public List<SBQQ__ProductOption__c> getProductOptionsBySBQQNumber(Integer sbqqMaxValue){
        if(sbqqMaxValue==null){
            return null;
        }
        List<String> fields = new List<String>{'Id',
            'SBQQ__Number__c','SBQQ__ConfiguredSKU__c'};
        String whereClause = 'SBQQ__Number__c <=  :sbqqMaxValue';
        String orderByClause ='SBQQ__ProductCode__c';
        List<Object> bindings = new List<Object>{sbqqMaxValue};
        return (List<SBQQ__ProductOption__c>) getSObjects(fields, whereClause, bindings, orderByClause);
    }
}