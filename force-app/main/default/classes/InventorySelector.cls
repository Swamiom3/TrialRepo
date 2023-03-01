/*************************************************************************************************************************************
 Author      :   Silpa Putti
 Description :   This class is selector implementation of particular SObject (Inventory__c)
 --------------------------------------------------------------------------------------------------------------------------------------
 VERSION         DATE            AUTHOR              DETAIL
 1               7/14/2021       Silpa Putti        Initial Deployment
 **************************************************************************************************************************************/
public inherited sharing class InventorySelector extends SObjectSelector {

    public InventorySelector() {
        super(Inventory__c.getSObjectType());
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
     Description         : This method is used to get inventories records from uuid
     Created Date        : 14/7/2021
     *****************************************************************************************************************************/
    public List<Inventory__c> getInventoriesByUUID(Set<String> uuids){
        if(uuids.isEmpty()){
            return null;
        }
        List<String> fields = new List<String>{'Id',
                'Name',
                'UUID__c',
                'List_Price__c'};
        return (List<Inventory__c>) getSObjectByField(fields, 'UUID__c', uuids, false);
    }
}