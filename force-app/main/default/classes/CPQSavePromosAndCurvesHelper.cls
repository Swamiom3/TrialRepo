/*************************************************************************************************************************************
 Author      :   Arun
 Description :   Helper class for CPQAddPromos
 --------------------------------------------------------------------------------------------------------------------------------------
 VERSION         DATE            AUTHOR              DETAIL
 1               03/15/2021       Arun        Initial Deployment
**************************************************************************************************************************************/
public class CPQSavePromosAndCurvesHelper {
    public SavePromoAndCurveWrapper getInventoryUUIDsWithCurves(List<CPQAddPromosWrapper.ResponseWithInventory> responseWrapper) {
        SavePromoAndCurveWrapper wrapper = new SavePromoAndCurveWrapper();
        
        for(CPQAddPromosWrapper.ResponseWithInventory responsewithInventory : responseWrapper){
            if(responsewithInventory.response == null || responsewithInventory.response.discounts == null) {
                continue;
            }
            for(CPQAddPromosWrapper.DiscountsWrapper discountWrapper : responsewithInventory.response.discounts){
                for(CPQAddPromosWrapper.PromotionsWrapper promotionWrapper : discountWrapper.promotions){
                    for(CPQAddPromosWrapper.DatapointsWrapper datapoint : promotionWrapper.dataPoints){
                        String inventoryUuid = responsewithInventory.uuid;
                        wrapper.inventoryUUIDwithBaseDiscounts.put(inventoryUuid +'-'+promotionWrapper.name,discountWrapper.baseDiscount);
                        if(wrapper.inventoryUUIDwithCurveValues.containskey(inventoryUuid +'-'+promotionWrapper.name)){                            
                            wrapper.inventoryUUIDwithCurveValues.get(inventoryUuid +'-'+promotionWrapper.name).add(datapoint.value);
                        }else{                            
                            wrapper.inventoryUUIDwithCurveValues.put(inventoryUuid +'-'+promotionWrapper.name,new List<Decimal>{datapoint.value});
                        }
                    }
                }
            }
        }
        return wrapper;
    }
    
    public class SavePromoAndCurveWrapper {
        public Map<String,List<Decimal>> inventoryUUIDwithCurveValues;
        public Map<String,Decimal> inventoryUUIDwithBaseDiscounts;
        public SavePromoAndCurveWrapper() {
            this.inventoryUUIDwithCurveValues = new Map<String,List<Decimal>>();
            this.inventoryUUIDwithBaseDiscounts = new Map<String,Decimal>();
        }
    }
}