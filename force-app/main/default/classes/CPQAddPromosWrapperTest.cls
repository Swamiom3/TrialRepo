@isTest
private class CPQAddPromosWrapperTest {
    @isTest
    static void testWrapper() {
        String uuid = 'TEST_UUID';
        String testId = 'TEST_ID';
        String testName = 'TEST_NAME';
        
        CPQAddPromosWrapper.CurveSelect curveSelect = new CPQAddPromosWrapper.CurveSelect();
        curveSelect.curvename = testName;
        curveSelect.uuid = uuid;
        
        CPQAddPromosWrapper.PromoSelect promoSelect = new CPQAddPromosWrapper.PromoSelect();
        promoSelect.uuid = uuid;
        promoSelect.promoId = testId;
        
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
            
        System.assert(curveSelect.curvename == testName, 'Failed to populate the Curve Name');
        System.assert(promoSelect.uuid == uuid, 'Failed to populate the UUID');
        System.assert(promoSelect.promoId == testId, 'Failed to populate Promo Id');
    }
}