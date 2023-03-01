@isTest
private class CPQAddPromosConditionsHelperTest {
    @isTest
    static void testConditions() {
        CPQTestUtils util = new CPQTestUtils();
        CPQAddPromosConditionsHelper helper = new CPQAddPromosConditionsHelper();

        SBQQ__QuoteLine__c quoteLine = (SBQQ__QuoteLine__c) util.mockSObject(new SBQQ__QuoteLine__c(),
        new Map<String, Object>{
            'SBQQ__ProductName__c' => CPQConstants.COMMITMENT,
            'SBQQ__ProductFamily__c' => 'TEST_FAMILY', 
            'Inventory_Id__c' => 'TEST'
        });
        Product2 prod = new Product2(Name = CPQConstants.COMMITMENT);
        quoteLine.SBQQ__Product__r = prod;

        Test.startTest();
        Boolean checkInventory = helper.checkInventoryAndAllAccess(quoteLine);
        Boolean isM2MOrCommitmentProd = helper.isM2MOrCommitmentProd(quoteLine);
        Boolean savePromosInitialCheck = helper.savePromosInitialCheck(new List<SBQQ__QuoteLine__c>{quoteLine}, null, null);
        Boolean isCommitmentM2MProd = helper.isCommitmentM2MProd(quoteLine);
        Boolean inventoryAndSubType = helper.checkInventoryAndSubType(quoteLine);
        Boolean checkInventoryDataPoint = helper.checkInventoryDataPoint(quoteLine, new Map<String, List<Decimal>>());
        Boolean promosIntialCheck = helper.getPromosIntialCheck(quoteLine, new Map<String, List<Promo_Code__c>>());
        Boolean isNotMonthAllAccessProd = helper.isNotMonthAllAccessProd(quoteLine);
        Boolean checkPromoInventoryUUID = helper.checkPromoInventoryUUID(quoteLine, new Map<String, CPQAddPromosWrapper.PromoSelect>());
        Test.stopTest();

        System.assert(checkInventory, 'Failed to verify checkInventoryAndAllAccess()');
        System.assert(!isM2MOrCommitmentProd, 'Failed to verify isM2MOrCommitmentProd()');
        System.assert(savePromosInitialCheck, 'Failed to verify savePromosInitialCheck()');
        System.assert(isCommitmentM2MProd, 'Failed to verify isCommitmentM2MProd()');
        System.assert(inventoryAndSubType, 'Failed to verify checkInventoryAndSubType()');
        System.assert(!checkInventoryDataPoint, 'Failed to verify checkInventoryDataPoint()');
        System.assert(promosIntialCheck, 'Failed to verify getPromosIntialCheck()');
        System.assert(!isNotMonthAllAccessProd, 'Failed to verify isNotMonthAllAccessProd()');
        System.assert(!checkPromoInventoryUUID, 'Failed to verify checkPromoInventoryUUID()');
    }
}