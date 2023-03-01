@isTest
public class InventorySearchControllerTest {
    @testSetup 
    static void setup() {
        Building__c building = new Building__c();
        building.Name = 'testbuild-001';
        building.Building_ID__c = 'test';
        building.UUID__c = 'test';
        building.Time_Zone__c ='America/Denver';
        insert building;
        
        Building__c building2 = new Building__c();
        building2.Name = 'testbuild-002';
        building2.Building_ID__c = 'test';
        building.UUID__c = 'test';
        building2.Time_Zone__c = 'America/Denver';
        insert building2;
        
        Inventory__c inventory = new Inventory__c();
        inventory.Name = 'testinv';
        inventory.List_Price__c = 100;
        inventory.Type__c = 'Office';
        inventory.UUID__c = '1234';
        inventory.Building__c = building.Id;
        insert inventory; 
        
        List<Product2> products = new List<Product2>();
        Set<String> productCodes = new Set<String>{'Physical Membership', 'Setup Fee', 'Service Retainer', 'Late Fee',
                            'Month-to-Month','Conference Room Credit','Color Printing Credit','Black & White Printing Credit'};
            for(String productCode : productCodes){
                Product2 product = new Product2( Name = productCode,Product_UUID__c = 'Product-'+ productCode, IsActive = true, ProductCode = productCode,Family = 'Workspace');       
                products.add(product);
            }
        insert products;       
        
        List<SBQQ__ProductOption__c> productOptions = new List<SBQQ__ProductOption__c>();
        for(Product2 productwihProductCode : products){
            SBQQ__ProductOption__c productOptionSetupFee = new SBQQ__ProductOption__c(SBQQ__Number__c = 1, SBQQ__OptionalSKU__c = productwihProductCode.Id,SBQQ__ConfiguredSKU__c = products[0].Id);
            productOptions.add(productOptionSetupFee);
        }
        insert productOptions;
        
        SBQQ__Quote__c quote = new SBQQ__Quote__c();
        quote.Building_Id__c = building.Id;
        quote.Subscription_Type__c = 'Commitment Term';
        insert quote;
    }
    
     @isTest 
     static void testQuotedata() {
        Test.startTest();
        SBQQ__Quote__c quote = [SELECT Id,Building_Id__c FROM SBQQ__Quote__c LIMIT 1];
        SBQQ__Quote__c result = InventorySearchController.getQuote(quote.Id);
        System.assert(quote.Building_Id__c == result.Building_Id__c,'Error in retrieving quote');
        Test.stopTest();
    }
    
    @isTest 
    static void testCreationofQuotelinesPositive() {
        Test.startTest();
        Building__c building = [SELECT Id,Building_ID__c,UUID__c FROM  Building__c WHERE Name='testbuild-001'];
        SBQQ__Quote__c quote = [SELECT Id, Building_Id__c FROM SBQQ__Quote__c WHERE Building_Id__c = :building.Id];
        Inventory__c inventory = [SELECT Id, UUID__c FROM Inventory__c LIMIT 1];
        InventorySearchController.InventorySearchWrapper inventorySearchWrapper = new InventorySearchController.InventorySearchWrapper();
        List<InventorySearchController.inventoryBuildingWrapper> inventoryBuildingWrapperList = new List<InventorySearchController.inventoryBuildingWrapper>();
        InventorySearchController.inventoryBuildingWrapper inventoryBuildingWrapper = new InventorySearchController.inventoryBuildingWrapper();
        InventorySearchController.buildWrapper buildingWrapper = new InventorySearchController.buildWrapper();
        buildingWrapper.value = 'test';
        inventoryBuildingWrapper.buildingId = buildingWrapper;
        inventoryBuildingWrapper.inventoryId = inventory.UUID__c; 
        inventoryBuildingWrapperList.add(inventoryBuildingWrapper);
        inventorySearchWrapper.inventorybuildingwrap = inventoryBuildingWrapperList;
        inventorySearchWrapper.quoteId = quote.Id;
        String jsonString = JSON.serialize(inventorySearchWrapper);
        DatabaseResult result = InventorySearchController.createQuoteLines(jsonString); 
        List<SBQQ__QuoteLine__c> quotelinesInserted = [SELECT Id, SBQQ__Quote__c, Inventory_Id__c FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c =: quote.Id];
        System.assert(inventory.Id == quotelinesInserted[0].Inventory_Id__c,'Updated Inventory is not correct');   
        System.assert(result.success, 'Error in update of QuoteLines');
        Test.stopTest();
    }
    
    @isTest 
    static void testCreationofQuotelinesNegative() {
        Test.startTest();
        Building__c building = [SELECT Id, Building_ID__c,UUID__c FROM  Building__c WHERE Name ='testbuild-001'];
        SBQQ__Quote__c quote = [SELECT Id, Building_Id__c FROM SBQQ__Quote__c WHERE Building_Id__c =:building.Id];
        Inventory__c inventory = [SELECT Id, UUID__c FROM Inventory__c LIMIT 1];
        Product2 product = [SELECT Id, Name FROM Product2 WHERE Name = 'Physical Membership'];
        SBQQ__QuoteLine__c quoteLine = new SBQQ__QuoteLine__c();
        quoteLine.SBQQ__Quote__c = quote.Id;
        quoteLine.SBQQ__Product__c = product.Id;
        quoteLine.Building_Id__c = building.Id;
        quoteLine.Inventory_Id__c = inventory.Id;
        quoteLine.SBQQ__StartDate__c = System.today();
        quoteLine.Commitment_Term__c = '1';
        quoteLine.SBQQ__Number__c = 1;
        insert quoteLine;
        InventorySearchController.InventorySearchWrapper inventorySearchWrapper = new InventorySearchController.InventorySearchWrapper();
        List<InventorySearchController.inventoryBuildingWrapper> inventoryBuildingWrapperList = new List<InventorySearchController.inventoryBuildingWrapper>();
        InventorySearchController.inventoryBuildingWrapper inventoryBuildingWrapper = new InventorySearchController.inventoryBuildingWrapper();
        InventorySearchController.buildWrapper buildingWrapper = new InventorySearchController.buildWrapper();
        buildingWrapper.value = 'test';
        inventoryBuildingWrapper.buildingId = buildingWrapper;
        inventoryBuildingWrapper.inventoryId = inventory.UUID__c; 
        inventoryBuildingWrapperList.add(inventoryBuildingWrapper);
        inventorySearchWrapper.inventorybuildingwrap = inventoryBuildingWrapperList;
        inventorySearchWrapper.quoteId = quote.Id;
        String jsonString = JSON.serialize(inventorySearchWrapper);
        try{
            DatabaseResult result = InventorySearchController.createQuoteLines(jsonString);
        }catch(exception e){
            System.assert(e.getMessage() =='You can select inventories only under single building', 'quote lines are created');
        }        
        Test.stopTest();
    }
}