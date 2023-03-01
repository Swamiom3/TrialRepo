@isTest
private class SmallDealDeskTemplateControllerTest {
    @isTest
    static void testController() {
        SBQQ__Quote__c quote = new SBQQ__Quote__c();
        quote.Subscription_Type__c = 'Commitment Term';
        insert quote;

        SBQQ__QuoteTerm__c term1 = new SBQQ__QuoteTerm__c(SBQQ__Quote__c = quote.Id, SBQQ__PrintOrder__c = 1);
        insert term1;
        
        SmallDealDeskTemplateController ctrl = new SmallDealDeskTemplateController();
        ctrl.quoteId = quote.Id;
        System.assert(ctrl.quote != null, 'Failed to retrieve Quote');
        System.assertEquals(ctrl.modifiedTermsCount, 1, 'Failed to retrieve Quote Terms');
        System.assertEquals(ctrl.discountLinesCount, 0, 'Failed to retrieve Discount Lines');
        System.assertEquals(ctrl.nonStandardSRApprovalLinesCount, 0, 'Retrieve NonStandardSRApprovalLinesCount successfully');
        System.assertEquals(ctrl.nonStandardMoveOutApprovalLinesCount, 0, 'Retrieve NonStandardSRApprovalLinesCount successfully');
    }
}