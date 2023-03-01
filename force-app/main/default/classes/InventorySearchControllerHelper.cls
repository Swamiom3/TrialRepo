/*************************************************************************************************************************************
 Author      :   Arun
 Description :   This is an helper class for InventorySearchController
 --------------------------------------------------------------------------------------------------------------------------------------
 VERSION         DATE            AUTHOR              DETAIL
 1               11/18/2021       Arun        Initial Deployment
 **************************************************************************************************************************************/
public inherited sharing class InventorySearchControllerHelper {
    private BuildingSelector buildingSelector = new BuildingSelector();
    private InventorySelector inventorySelector = new InventorySelector();
    private QuoteLineSelector quoteLineSelector = new QuoteLineSelector();
    private ProductSelector productSelector = new ProductSelector();
    
    public Boolean isInventoryWrapperEmpty(InventorySearchController.InventorySearchWrapper inventoryWrapper) {
        return inventoryWrapper.inventoryBuildingWrap.isEmpty() || inventoryWrapper.quoteId == null;
    }

    public List<SBQQ__QuoteLine__c> getQuoteLinesByIdOrInventories(InventorySearchController.InventorySearchWrapper inventoryWrapper, Set<String> inventoryUUIDs) {
        List<SBQQ__QuoteLine__c> quoteLines = new List<SBQQ__QuoteLine__c>();
        quoteLines = inventoryUUIDs.isEmpty() ? quoteLineSelector.getQuoteLinesByQuoteId(inventoryWrapper.QuoteId) : 
        quoteLineSelector.getQuoteLinesWithInventories(inventoryWrapper.QuoteId, inventoryUUIDs);
        return quoteLines;
    }

    public Map<String,List<SBQQ__QuoteLine__c>> getParentAndChildLines(List<SBQQ__QuoteLine__c> quoteLines) {
        Map<String,List<SBQQ__QuoteLine__c>> parentQuoteLinesWithChilds = new Map<String,List<SBQQ__QuoteLine__c>>();
        for(SBQQ__QuoteLine__c quoteLine : quoteLines){
            if(quoteLine.SBQQ__RequiredBy__c != null && parentQuoteLinesWithChilds.containskey(quoteLine.SBQQ__RequiredBy__c)){
                parentQuoteLinesWithChilds.get(quoteLine.SBQQ__RequiredBy__c).add(quoteLine);
            }else if(quoteLine.SBQQ__ProductFamily__c == CPQConstants.WORKSPACE && quoteLine.SBQQ__RequiredBy__c == null){
                parentQuoteLinesWithChilds.put(quoteLine.Id,new List<SBQQ__QuoteLine__c>{quoteLine});               
            }
        }
        return parentQuoteLinesWithChilds;
    }

    public void createParentQuoteLines(List<SBQQ__QuoteLine__c> parentQuoteLines) {
        if (Schema.SObjectType.SBQQ__QuoteLine__c.isCreateable()){            
            insert parentQuoteLines;
        }
    }

    public Map<Id,SBQQ__QuoteLine__c> getQuoteLinesWithInventory(Map<String, List<SBQQ__QuoteLine__c>> parentQuoteLinesWithChilds, 
        List<Inventory__c> inventoryList,String buildingId){
        Integer i = 0;
        Map<Id,SBQQ__QuoteLine__c> quoteLines = new Map<Id,SBQQ__QuoteLine__c>();
        for(String quotelineId : parentQuoteLinesWithChilds.keySet()){
            for(SBQQ__QuoteLine__c quoteLine : parentQuoteLinesWithChilds.get(quotelineId)){                
                if(quoteLine.Id != quotelineId && quoteLine.SBQQ__RequiredBy__c != quotelineId){
                       continue;                    
                }
                quoteLine.Inventory_Id__c = inventoryList[i].Id;
                quoteLine.Building_Id__c = buildingId;
                if(quoteLine.SBQQ__Product__r.Name.Startswith('Month')){
                    quoteLine.SBQQ__ListPrice__c = inventoryList[i].List_Price__c != null ? inventoryList[i].List_Price__c : 0;
                }
                quoteLines.put(quoteLine.Id,quoteLine);                
            }
            i=i+1;
        }
        return quoteLines;
    }

    public void updateQuoteBuildingId(SBQQ__Quote__c quote, InventorySearchController.InventorySearchWrapper inventoryWrapper){
        if(inventoryWrapper == null){
            return;
        }
        if(quote.Building_Id__r.UUID__c != inventoryWrapper.inventoryBuildingWrap[0].BuildingId.value){
            if(quote.SBQQ__LineItemCount__c > 0){
                AuraHandledException e = new AuraHandledException(Label.InventoryMultipleBuildingsError);
                e.setMessage(Label.InventoryMultipleBuildingsError);
                throw e;
            }else{
                Building__c building = getBuilding(inventoryWrapper.inventoryBuildingWrap[0].BuildingId.value);
                if(building == null){
                    String message = String.format(Label.BuildingMissingErrorMsg, new List<String>{inventoryWrapper.inventoryBuildingWrap[0].BuildingId.value});
                    AuraHandledException e = new AuraHandledException(message);
                    e.setMessage(message);
                    throw e;
                }else{
                    quote.Building_Id__c = building.Id;                
                    update quote;
                }
            }
        }
    }

    private Building__c getBuilding(String uuid){
        if(uuid == null){
            return new Building__c();
        }
        List<Building__c> buildings = buildingSelector.getBuildingsByBuildingUUId(uuid);
        if(buildings.isEmpty()){
            return null;
        }
        return buildings[0];         
    }

    public List<Inventory__c> validateInventories(Set<String> inventoryUUIds){
        if(inventoryUUIds.isEmpty()){
            return new List<Inventory__c>();
        }
        List<Inventory__c> inventoryList = inventorySelector.getInventoriesByUUID(inventoryUUIds);
        Map<String,Inventory__c> inventoryWithUUID = new Map<String,Inventory__c>();
        
        for(Inventory__c inventory : inventoryList){
            inventoryWithUUID.put(inventory.UUID__c,inventory);
        }
        
        for(String inventoryId : inventoryUUIds){
            if(!inventoryWithUUID.containskey(inventoryId)){
                String message = String.format(Label.InventoryMissingWithUUIDError, new List<String>{inventoryId});
                AuraHandledException e = new AuraHandledException(message);
                e.setMessage(message);
                throw e;
            }
        }
        return inventoryList;
    }

    public Map<String,Product2> getProductWithProductCodes(List<String> productNames){    
        Map<String,Product2> productsWithProductCodes = new Map<String,Product2>();
        for(Product2 product : productSelector.getProductWithSubscriptionsOrderByProductName(productNames)){
            productsWithProductCodes.put(product.Name,product);
        }
        return productsWithProductCodes;
    }
}