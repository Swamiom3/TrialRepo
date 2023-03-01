@isTest
private class CPQAddPromosHelperTest {
	static CPQTestUtils util = new CPQTestUtils();
    static CPQAddPromosHelper helper = new CPQAddPromosHelper();
    static final String PROD_FAMILY = 'TEST_FAMILY';
    static final String UUID = 'TEST_UUID';
    
    @isTest
    static void testGetpromoCodesWithTypesEmpty() {
        Test.startTest();
        Map<String, List<Promo_Code__c>> promoCodesWithTypes = helper.getpromoCodesWithTypes(new Set<String>{'TEST_TYPE'});
        Test.stopTest();

        System.assert(promoCodesWithTypes.isEmpty(), 'Failed to do empty check for getpromoCodesWithTypes()');
    }
    
    @isTest
    static void testGetM2MAndAllAccessQuoteLines() {
        List<SBQQ__QuoteLine__c> quoteLines = new List<SBQQ__QuoteLine__c>();
        SBQQ__QuoteLine__c quoteLine = new SBQQ__QuoteLine__c();
        quoteLines.add((SBQQ__QuoteLine__c) util.mockSObject(quoteLine, new Map<String, Object>{'SBQQ__ProductName__c' => CPQConstants.COMMITMENT, 'SBQQ__ProductFamily__c' => PROD_FAMILY, 
            'Inventory_Id__c' => 'TEST'}));
        
        quoteLines[0].Inventory_Id__r = getInventory();
        
        Test.startTest();
        List<CPQAddPromosWrapper.ResponseWithInventory> responsewithInventoryList = helper.getM2MAndAllAccessQuoteLines(quoteLines, new Map<String, List<Promo_Code__c>>());
        Test.stopTest();

        for(CPQAddPromosWrapper.ResponseWithInventory resp: responsewithInventoryList) {
            System.assert(resp.uuid == UUID, 'Failed to verify UUID for ResponseWithInventory');
        }
    }

    @isTest
    static void testGetTermTypesFromService() {
        String testId = 'TEST_ID';
        String testName = 'TEST_NAME';

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

        CPQAddPromosWrapper.ResponseWithInventory respInventory = new CPQAddPromosWrapper.ResponseWithInventory();
        
        Test.startTest();
        CPQAddPromosWrapper.ResponseWithInventory respWithInv = helper.getTermTypesFromService(respInventory, new List<CPQAddPromosWrapper.ResponseWrapper>{resp});
        Test.stopTest();

        System.assert(respWithInv.curvesAvailable, 'DiscountsWrapper should not be empty');
    }

    @isTest
    static void testGetPromoCodes() {
        SBQQ__QuoteLine__c quoteLine = (SBQQ__QuoteLine__c) util.mockSObject(new SBQQ__QuoteLine__c(), new Map<String, Object>{'SBQQ__ProductName__c' => CPQConstants.COMMITMENT, 
            'SBQQ__StartDate__c' => System.today(), 'Commitment_Term__c' => 1});
        Inventory__c inventory = getInventory();
        quoteLine.Inventory_Id__r = inventory;
        
        List<Promo_Code__c> codes = new List<Promo_Code__c>();
        codes.add(new Promo_Code__c(Duration__c = '0'));

        Test.startTest();
        List<Promo_Code__c> promoCodes = helper.getPromoCodes(quoteLine, new Map<String, List<Promo_Code__c>>{inventory.Type__c => codes});
        Test.stopTest();

        for(Promo_Code__c code: promoCodes) {
            System.assert(code.Duration__c == codes[0].Duration__c, 'Duration should be same with received PromoCodes');
        }
    }
    
    @isTest
    static void testPartnerDiscountQLs() {
        List<SBQQ__QuoteLine__c> quoteLinesData = new List<SBQQ__QuoteLine__c>();
        SBQQ__QuoteLine__c quoteLine = new SBQQ__QuoteLine__c();
        quoteLinesData.add((SBQQ__QuoteLine__c) util.mockSObject(quoteLine, new Map<String, Object>{'SBQQ__ProductName__c' => CPQConstants.COMMITMENT, 'SBQQ__ProductFamily__c' => PROD_FAMILY,
            'Inventory_Id__c' => 'TEST', 'SBQQ__ProductCode__c' => 1}));
        
        Product2 prod = new Product2(Name = CPQConstants.COMMITMENT);
        Inventory__c inventory = getInventory();
        quoteLinesData[0].Inventory_Id__r = inventory;
        quoteLinesData[0].SBQQ__Product__r = prod;
        
        List<Decimal> inventoryDatapoints = new List<Decimal>{12};
        
        Test.startTest();
        List<SBQQ__QuoteLine__c> quoteLines = helper.getQuoteLinesWithPartnerDiscount(quoteLinesData, new Map<String, List<Decimal>>{inventory.UUID__c => inventoryDatapoints});
        Test.stopTest();

        for(SBQQ__QuoteLine__c ql: quoteLines) {
            System.assert(String.isBlank(ql.Promo_Code_Id__c), 'PromoCode Id on QuoteLine should be blank');
        }
    }
    
    @isTest
    static void testGetPromoDiscounts() {
        List<SBQQ__QuoteLine__c> quoteLinesData = new List<SBQQ__QuoteLine__c>();
        SBQQ__QuoteLine__c quoteLine = new SBQQ__QuoteLine__c();
        quoteLinesData.add((SBQQ__QuoteLine__c) util.mockSObject(quoteLine, new Map<String, Object>{'SBQQ__ProductName__c' => CPQConstants.MONTH, 'SBQQ__ProductFamily__c' => PROD_FAMILY,
            'Inventory_Id__c' => 'TEST', 'SBQQ__ProductCode__c' => 1, 'SBQQ__StartDate__c' => System.today()}));
        
        Product2 prod = new Product2(Name = CPQConstants.MONTH);
        SBQQ__Quote__c quote = new SBQQ__Quote__c(Subscription_Type__c = CPQConstants.SUBSCRIPTION_M2M);
        Promo_Code__c promoCode = new Promo_Code__c(Name  = 'Test_Promo', Duration__c = '1', Percent__c = 1);
        insert promoCode;
        
        quoteLinesData[0].Inventory_Id__r = getInventory();
        quoteLinesData[0].SBQQ__Product__r = prod;
        quoteLinesData[0].SBQQ__Quote__r = quote;
        
        CPQAddPromosWrapper.PromoSelect promoSelect = new CPQAddPromosWrapper.PromoSelect();
        promoSelect.UUID = UUID;
        promoSelect.promoId = promoCode.Id;
        promoSelect.percent = '1';
        promoSelect.duration = '1';
        
        Map<String, CPQAddPromosWrapper.PromoSelect> promoMap = new Map<String, CPQAddPromosWrapper.PromoSelect>{UUID => promoSelect};
        
        Test.startTest();
        List<SBQQ__QuoteLine__c> quoteLines = helper.getPromoDiscounts(quoteLinesData, promoMap);
        Test.stopTest();

        for(SBQQ__QuoteLine__c ql: quoteLines) {
            System.assert(ql.Promo_Code_Id__c == promoSelect.promoId, 'PromoCode Id should be same as PromoSelect PromoId');
            System.assert(ql.SBQQ__PartnerDiscount__c == Decimal.valueOf(promoSelect.percent), 'PartnerDiscount should be same as PromoSelect Percent');
        }
    }

    static Inventory__c getInventory() {
        return new Inventory__c(Name = 'Test', List_Price__c = 123, Type__c = 'Office', UUID__c = UUID);
    }
}