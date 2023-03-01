@isTest
private class CPQSavePromosAndCurvesHelperTest {
    @isTest
    static void testUUIDWithCurves() {
        String testName = 'TEST_NAME';
        String uuid = 'TEST_UUID';
        
        CPQAddPromosWrapper.DatapointsWrapper datapoints = new CPQAddPromosWrapper.DatapointsWrapper();
        datapoints.month = 1;
        datapoints.value = 1;
        
        CPQAddPromosWrapper.PromotionsWrapper promotion = new CPQAddPromosWrapper.PromotionsWrapper();
        promotion.name = testName;
        promotion.dataPoints = new List<CPQAddPromosWrapper.DatapointsWrapper>{datapoints};
            
        CPQAddPromosWrapper.DiscountsWrapper discount = new CPQAddPromosWrapper.DiscountsWrapper();
        discount.termTypeLabel = testName;
        discount.promotions = new List<CPQAddPromosWrapper.PromotionsWrapper>{promotion};
            
        CPQAddPromosWrapper.CurrentPriceWrapper currentPrice = new CPQAddPromosWrapper.CurrentPriceWrapper();
        currentPrice.price = 1;
            
        CPQAddPromosWrapper.ResponseWrapper resp = new CPQAddPromosWrapper.ResponseWrapper();
        resp.currentPrice = currentPrice;
        resp.discounts = new List<CPQAddPromosWrapper.DiscountsWrapper>{discount};
            
        CPQAddPromosWrapper.ResponseWithInventory respWithInventory = new CPQAddPromosWrapper.ResponseWithInventory();
        respWithInventory.inventoryName = testName;
        respWithInventory.termTypes = new List<String>{'TYPE_1'};
        respWithInventory.response = resp;
        respWithInventory.promoCodes = new List<Promo_Code__c>{};
        respWithInventory.curvesAvailable = false;
        respWithInventory.promoCodesAvailable = false;
        respWithInventory.uuid = uuid;
        
        CPQSavePromosAndCurvesHelper.SavePromoAndCurveWrapper wrapper = new CPQSavePromosAndCurvesHelper().getInventoryUUIDsWithCurves(
            new List<CPQAddPromosWrapper.ResponseWithInventory>{respWithInventory});
        
        System.assert(wrapper.inventoryUUIDwithCurveValues.get(uuid+'-'+promotion.name)[0] == datapoints.value, 'Failed to verify the Data Points value');
    }
}