@isTest
private class InventorySearchControllerHelperTest {
    private static CPQTestUtils util = new CPQTestUtils();

    @testSetup
    static void testSetup() {
        util.setupCPQTestData();
    }
    
    @isTest
    static void testPositiveFlow() {
        Inventory__c inventory = [SELECT Id, List_Price__c FROM Inventory__c LIMIT 1];
        SBQQ__QuoteLine__c line = [SELECT Id, SBQQ__Quote__c, SBQQ__Product__c, Building_Id__c, SBQQ__StartDate__c, Commitment_Term__c, SBQQ__Number__c, 
                                   SBQQ__RequiredBy__c, SBQQ__ProductFamily__c, SBQQ__Product__r.Name FROM SBQQ__QuoteLine__c LIMIT 1];
        SBQQ__QuoteLine__c childLine = line.clone(false, true, false, false);
        childLine.SBQQ__RequiredBy__c = line.Id;
        insert childLine;
        
        InventorySearchControllerHelper helper = new InventorySearchControllerHelper();
        List<SBQQ__QuoteLine__c> lines = new List<SBQQ__QuoteLine__c>{line, childLine};
        Map<String, List<SBQQ__QuoteLine__c>> linesMap = new Map<String, List<SBQQ__QuoteLine__c>>{line.Id => lines};
        
        Test.startTest();
        Map<String,List<SBQQ__QuoteLine__c>> parentChildQLs = helper.getParentAndChildLines(lines);
        Map<Id,SBQQ__QuoteLine__c> quoteLines = helper.getQuoteLinesWithInventory(linesMap, new List<Inventory__c>{inventory}, null);
        Test.stopTest();

        System.assert(!parentChildQLs.isEmpty(), 'Failed to segregate parent & child lines');
        for(SBQQ__QuoteLine__c ql: quoteLines.values()) {
            System.assert(ql.SBQQ__ListPrice__c == inventory.List_Price__c, 'Failed to update inventory price on QuoteLine');
        }
    }
    
    @isTest
    static void testQuoteBuildingIdWithLineCount() {
        SBQQ__Quote__c quote = [SELECT Id, Building_Id__r.UUID__c, SBQQ__LineItemCount__c FROM SBQQ__Quote__c LIMIT 1];
        
        InventorySearchControllerHelper helper = new InventorySearchControllerHelper();
        
        Test.startTest();
        String msg;
        try {
            helper.updateQuoteBuildingId(quote, getInventorySearch(null));
        } catch(Exception e) {
            msg = e.getMessage();
        }
        Test.stopTest();
        
        System.assert(msg != null && msg.contains(Label.InventoryMultipleBuildingsError), 'Failed to test QuoteBuildId validation');
    }
    
    @isTest
    static void testIsInventoryWrapperEmpty() {
        InventorySearchControllerHelper helper = new InventorySearchControllerHelper();
        
        Test.startTest();
        Boolean result = helper.isInventoryWrapperEmpty(getInventorySearch(null));
        Test.stopTest();
        
        System.assert(result, 'Failed to verify the Inventory Wrapper');
    }
    
    @isTest
    static void testQuoteBuildingIdWithNoBuilding() {
        delete [SELECT Id, SBQQ__Product__r.Name, SBQQ__RequiredBy__c FROM SBQQ__QuoteLine__c];
        SBQQ__Quote__c quote = [SELECT Id, Building_Id__r.UUID__c, SBQQ__LineItemCount__c FROM SBQQ__Quote__c LIMIT 1];        

        InventorySearchControllerHelper helper = new InventorySearchControllerHelper();
        
        Test.startTest();
        String msg;
        try {
            helper.updateQuoteBuildingId(quote, getInventorySearch(''));
        } catch(Exception e) {
            msg = e.getMessage();
        }
        Test.stopTest();
        
        System.assert(msg != null && msg.contains(Label.BuildingMissingErrorMsg.replace(' {0}', '')), 'Failed to test Quote with no Building validation');
    }
    
    static InventorySearchController.InventorySearchWrapper getInventorySearch(String value) {
        InventorySearchController.Buildwrapper buildWrap = new InventorySearchController.Buildwrapper();
        buildWrap.value = value;
        InventorySearchController.InventoryBuildingWrapper buildingWrap = new InventorySearchController.InventoryBuildingWrapper();
        buildingWrap.buildingId = buildWrap;
        InventorySearchController.InventorySearchWrapper wrapper = new InventorySearchController.InventorySearchWrapper();
        wrapper.inventoryBuildingWrap = new List<InventorySearchController.InventoryBuildingWrapper>{buildingWrap};
        return wrapper;
    }
    
    @isTest
    static void testValidateInventories() {
        InventorySearchControllerHelper helper = new InventorySearchControllerHelper();
        
        Test.startTest();
        String msg;
        try {
            helper.validateInventories(new Set<String>{'Test1','Test2'});
        } catch(Exception e) {
            msg = e.getMessage();
        }
        Test.stopTest();
        
        System.assert(msg != null && msg.contains(Label.InventoryMissingWithUUIDError.replace(' {0}', '')), 'Failed to validate inventories');
    }
}