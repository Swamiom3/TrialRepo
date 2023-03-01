global with sharing class QuoteProductSearchPlugin implements SBQQ.ProductSearchPlugin{
    public static final String ADDON_FAMILY = 'addons';
    global String getAdditionalSearchFilters(SObject quote, Map<String,Object> fieldValuesMap){        
        String buildingId = String.valueOf(quote.get('Building_Id__c'));
        if(String.IsBlank(buildingId)){
            return null;
        }
        BuildingSelector buildingSelector = new BuildingSelector();
        List<Building__c> building = buildingSelector.getBuildingById(buildingId);
        if(building.IsEmpty() == null){
            return null;
        }
         
        Map<String, ProductServiceOutput> output = AddonProductSvcCallOut.getbuildingAddons(building.get(0).UUID__c);        
        if(output.IsEmpty()){
            return null; 
        }
        
        Set<Id> newOrUsedFilter = new Set<Id>();
        ProductSelector productSelector = new ProductSelector();
        for(Product2 product : productSelector.getProductByProductCode(output.keySet())){
            newOrUsedFilter.add(product.Id);
        }      
        String priceBookId = String.valueOf(quote.get('SBQQ__PricebookId__c'));
        PriceBookEntrySelector priceBookEntrySelector = new PriceBookEntrySelector();        
        for(PriceBookEntry priceBookEntry : priceBookEntrySelector.getPriceBookEntriesbyPriceBookIdAndProductFamily(priceBookId, ADDON_FAMILY)){
            if(priceBookEntry.Product2.SBQQ__Component__c == false){
                newOrUsedFilter.add(priceBookEntry.Product2Id); 
            }
        }
        return 'Product2.Id  IN ' + inClausify(newOrUsedFilter);
    }
    @TestVisible
    private String inClausify(Set<Id> ids) {
        String inClause = String.format( '(\'\'{0}\'\')', 
                             new List<String> { String.join( new List<Id>(ids) , '\',\'') });
        return inClause;
    }
    
    global String getAdditionalSuggestFilters(SObject quote, Map<String,Object> fieldValuesMap){
        return null;
    }
    
    global List<PricebookEntry> search(SObject quote, Map<String,Object> filters){
        return new List<PricebookEntry>();
    }
    
    global Boolean isInputHidden(SObject quote, String input){
        return false;
    }
    
    global String getInputDefaultValue(SObject quote, String input){
        return null;
    }
    
    global List<PriceBookEntry> suggest(SObject quote, Map<String,Object> fieldValuesMap){
        return null;
    }
    
    global Boolean isSuggestCustom(SObject quote, Map<String,Object> inputValuesMap){
        return false;
    }    
    
    global Boolean isFilterHidden(SObject quote, String fieldName){
        return false;
    }
    
    global String getFilterDefaultValue(SObject quote, String fieldName){
        return null;
    }
    
    global Boolean isSearchCustom(SObject quote, Map<String,Object> fieldValuesMap){
        return false;
    }
}