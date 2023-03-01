/*************************************************************************************************************************************
 Author      :   Salesforce
 Description :   This class is selector implementation of particular SObject (ContractLineItem)
 --------------------------------------------------------------------------------------------------------------------------------------
 VERSION         DATE            AUTHOR              DETAIL
 1               14/7/2021       Salesforce        Initial Deployment
 **************************************************************************************************************************************/
public inherited sharing class ContractLineItemSelector extends SObjectSelector{
	public ContractLineItemSelector() {
        super(ContractLineItem.getSObjectType());
    }
    
    /****************************************************************************************************************************
     Author              : Salesforce
     Description         : This method is used to get default fields from Object
     Created Date        : 16/11/2021
     *****************************************************************************************************************************/
    public override Set<String> getDefaultFields(){
        return new Set<String>{'Id', 'Name'};
    }
    
    /****************************************************************************************************************************
     Author              : Salesforce
     Description         : This method is used to get ContractItems records from ServiceContractId
     Created Date        : 16/11/2021
     *****************************************************************************************************************************/
    public List<ContractLineItem> getContractItemsByServiceContractId(Set<Id> serviceContractIds){
        if(serviceContractIds.isEmpty()){
            return null;
        }
        List<String> fields = new List<String>{
                'Inventory_Id__c'                
                };
        String whereClause = '(ServiceContractId =: serviceContractId AND Inventory_Id__c != null)';
        List<Object> bindings = new List<Object>{serviceContractIds};
        return (List<ContractLineItem>) getSObjects(fields, whereClause, bindings);
    }
}