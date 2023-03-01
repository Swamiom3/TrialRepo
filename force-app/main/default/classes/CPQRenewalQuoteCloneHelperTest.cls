@isTest
private class CPQRenewalQuoteCloneHelperTest {
    static Inventory__c inventory;
    static CPQTestUtils util = new CPQTestUtils();

    static void testSetup() {
        inventory = new Inventory__c();
        inventory.Name = 'testinv';
        inventory.List_Price__c = 100;
        inventory.Type__c = 'Office';
        inventory.UUID__c = '3665lghjh27mnb';
        insert inventory;
    }
    
    @isTest
    static void testGetParentLines() {
        testSetup();
        
        List<SBQQ__QuoteLine__c> quoteLines = new List<SBQQ__QuoteLine__c>();
        SBQQ__QuoteLine__c quoteLine = new SBQQ__QuoteLine__c();
        quoteLines.add((SBQQ__QuoteLine__c) util.mockSObject(quoteLine, new Map<String, Object>{'SBQQ__ProductName__c' => CPQConstants.COMMITMENT, 'Inventory_Id__c' => inventory.Id}));
        quoteLines.add((SBQQ__QuoteLine__c) util.mockSObject(quoteLine, new Map<String, Object>{'SBQQ__ProductName__c' => CPQConstants.ALL_ACCESS, 'Inventory_Id__c' => inventory.Id}));
        
        Test.startTest();
        CPQRenewalQuoteCloneHelper helper = new CPQRenewalQuoteCloneHelper();
        Map<String, String> parentQuoteLines = helper.getParentLines(quoteLines);
        helper.updateRequiredByOnChildLines(quoteLines, parentQuoteLines);
        Test.stopTest();
        
        System.assert(parentQuoteLines.containsKey(inventory.Id) && parentQuoteLines.get(inventory.Id) == quoteLines[0].Id, 'Parent QuoteLines Map should contain the Inventory Id');
    }
    
    @isTest
    static void testUtilConditions() {
        testSetup();
        SBQQ__QuoteLine__c quoteLine = new SBQQ__QuoteLine__c();
        quoteLine = (SBQQ__QuoteLine__c) util.mockSObject(quoteLine, new Map<String, Object>{'SBQQ__ProductName__c' => CPQConstants.COMMITMENT, 'Inventory_Id__c' => inventory.Id});
        SBQQ__QuoteLine__c cloneQL = (SBQQ__QuoteLine__c) util.mockSObject(quoteLine, new Map<String, Object>{'SBQQ__ProductName__c' => 'Setup Fee', 'Inventory_Id__c' => inventory.Id});
        
        CPQRenewalQuoteCloneHelper helper = new CPQRenewalQuoteCloneHelper();
        Date startDate = System.today();
        
        Test.startTest();
        Boolean checkBundleLines = helper.checkSelectedBundleLines(new Set<String>(), quoteLine);
        Boolean isPhysicalMoveInDate = helper.isPhysicalAccessMoveInDate(quoteLine, CPQConstants.CHANGE_MOVEIN_DATE_ACTION);
        Boolean isPhysicalAmend = helper.isPhysicalAccessAmend(quoteLine, CPQConstants.AMEND_TERM);
        Boolean isMonthAmend = helper.isMonthProdAmendAction(quoteLine, CPQConstants.CHANGE_MOVEIN_DATE_ACTION);
        Boolean isMonthMoveInAction = helper.isMonthProdMoveInAction(quoteLine, CPQConstants.AMEND_TERM);
        Boolean verifyActionDate = helper.verifyMonthProdActionDate(quoteLine, cloneQL, CPQConstants.AMEND_TERM, System.today());
        helper.processQuoteLine(cloneQL, quoteLine, CPQConstants.CHANGE_MOVEIN_DATE_ACTION, startDate, System.today());
        helper.processQuoteLine(quoteLine, cloneQL, CPQConstants.CHANGE_MOVEIN_DATE_ACTION, System.today(), System.today());
        Test.stopTest();
        
        System.assert(checkBundleLines, 'Failed to verify checkSelectedBundleLines()');
        System.assert(!isPhysicalMoveInDate, 'Failed to verify isPhysicalAccessMoveInDate()');
        System.assert(!isPhysicalAmend, 'Failed to verify isPhysicalAccessAmend()');
        System.assert(!isMonthAmend, 'Failed to verify isMonthProdAmendAction()');
        System.assert(!isMonthMoveInAction, 'Failed to verify isMonthProdMoveInAction()');
        System.assert(verifyActionDate, 'Failed to verify verifyMonthProdActionDate()');
        System.assert(quoteLine.SBQQ__StartDate__c == startDate, 'Failed to verify the data for processQuoteLine()');
    }
}