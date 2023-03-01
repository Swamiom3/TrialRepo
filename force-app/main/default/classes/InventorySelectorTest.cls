/*************************************************************************************************************************************
Author      :   Salesforce
Description :   This class provides sufficient test coverage for InventorySelector class
--------------------------------------------------------------------------------------------------------------------------------------
VERSION         DATE            AUTHOR              DETAIL
1               7/21/2021       Salesforce         Initial Deployment
**************************************************************************************************************************************/
@isTest
private class InventorySelectorTest {
    private static InventorySelector inventorySelector = new InventorySelector();
    
    @isTest
    static void getInventoriesByUUIDTest(){
        Inventory__c inventory = new Inventory__c();
        inventory.Name = 'testinv';
        inventory.List_Price__c = 100;
        inventory.Type__c = 'Office';
        inventory.UUID__c = '1234';
        insert inventory;
        Set<String> uuIds = new Set<String>{'1234'};
        List<Inventory__c> inventories = inventorySelector.getInventoriesByUUID(uuIds);
        System.assert(inventories !=null, 'Inventories not retrived successfully');
        
        uuIds = new Set<String>{'123456'};
        inventories = inventorySelector.getInventoriesByUUID(uuIds);
        System.assert(inventories.isEmpty(), 'Inventories should not be retrived');
    }
}