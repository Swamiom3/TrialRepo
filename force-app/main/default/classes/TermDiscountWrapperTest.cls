@isTest
private class TermDiscountWrapperTest {
    @isTest
    static void testWrapper() {
        String displayItem = 'Test Item';
        String inventoryName = 'Test Inventory';
        List<String> commitmentTerms = new List<String>{'1'};
        
        Test.startTest();
        TermCommitmentWrapper commitmentTermData = new TermCommitmentWrapper(commitmentTerms, '1');
        TermDiscountWrapper wrapper = new TermDiscountWrapper(displayItem, inventoryName, commitmentTermData, new SBQQ__QuoteLine__c(), false, false);
        Test.stopTest();        
        
        System.assert(wrapper.displayItem == displayItem, 'Failed to populate the Display Item');
        System.assert(wrapper.inventoryName == inventoryName, 'Failed to populate the Inventory Name');
        System.assert(wrapper.commitmentTermData.commitmentTerms == commitmentTerms, 'Failed to populate the Commitment Terms');
    }
}