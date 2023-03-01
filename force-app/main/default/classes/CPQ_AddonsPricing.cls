/************************************************************************************************************************************
Author      :   Salesforce
Description :   This class contains methods to get addon products per building.
----------------------------------------------------------------------------------------------------------------------------------
VERSION     DATE                AUTHOR                  DETAIL
1           06 AUG 2021         Salesforce            Initial Developement
**************************************************************************************************************************************/
@RestResource(urlMapping='/AddonsPricing/*')
global without sharing class CPQ_AddonsPricing {
    public static BuildingSelector buildingSelector = new BuildingSelector();
    @HttpPost
    global static String getAddonsPricing(List<String> productUUIds, String buildingId) {
        if(buildingId == null || productUUIds.isEmpty()){
            return null;
        }
        List<ProductServiceResponseWrapper> productServiceResponses = new List<ProductServiceResponseWrapper>();
        List<Building__c> buildings = buildingSelector.getBuildingById(buildingId);
        if(buildings.isEmpty() || buildings[0].UUID__c == null){
            return null;
        }
        Map<String, ProductServiceOutput> output = AddonProductSvcCallOut.getBuildingAddons(buildings[0].UUID__c);        
        if(output.isEmpty()){
            return null;
        }
        Set<String> addonUuids = output.keySet();
        for(String productUUID : productUUIds){
            if(!addonUuids.contains(productUUID)){
                continue;
            }
            ProductServiceResponseWrapper productServiceResponseWrapItem = new ProductServiceResponseWrapper();
            productServiceResponseWrapItem.uuid = productUUID;
            productServiceResponseWrapItem.price = output.get(productUUID).productPrice;
            productServiceResponseWrapItem.setupFee = output.get(productUUID).productSetupFee;
            productServiceResponseWrapItem.colocationFee = output.get(productUUID).productCoLocationFee;
            productServiceResponses.add(productServiceResponseWrapItem);
        }
        return JSON.serialize(productServiceResponses);
    }
    
    public class ProductServiceResponseWrapper{
        public String uuid {get;set;}
        public String price {get;set;}
        public String setupFee {get;set;}
        public String colocationFee {get;set;}
    }
}