/*************************************************************************************************************************************
Author      :   Salesforce
Description :   This class provides sufficient test coverage for QUoteSelector class
--------------------------------------------------------------------------------------------------------------------------------------
VERSION         DATE            AUTHOR              DETAIL
1               7/21/2021       Salesforce         Initial Deployment
**************************************************************************************************************************************/
@isTest
private class QuoteSelectorTest {
    private static QuoteSelector quoteSelector = new QuoteSelector();

    @TestSetup
    static void makeData(){
        OperatingHours operatingHour = new OperatingHours(Name = 'EDT: Standard 9AM - 5PM Weekday');
        insert operatingHour;
        
        Building__c building = new Building__c();
        building.Name = 'testbuild-001';
        building.Building_ID__c = 'test';
        building.UUID__c = 'test';
        building.Time_Zone__c ='America/Denver';
        insert building;

        Account account = TestingUtility.createAccount('Acme', true);
        Opportunity opp = TestingUtility.createOpportunity(account.Id, true);
        
        SBQQ__Quote__c quote = new SBQQ__Quote__c();
        quote.Building_Id__c = building.Id;
        quote.Subscription_Type__c = 'Commitment Term';
        quote.SBQQ__Opportunity2__c = opp.Id;
        quote.SBQQ__Primary__c = true;
        insert quote;
    }
    
    @isTest
    static void getQuoteByQuoteIdTest(){
        SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        List<SBQQ__Quote__c> quoteResult = quoteSelector.getQuoteById(quote.Id);
        System.assert(!quoteResult.isEmpty(), 'Quote not retrived successfully');
        List<SBQQ__Quote__c> quoteResultNegative = quoteSelector.getQuoteById('1234');
        System.assert(quoteResultNegative.isEmpty(), 'Quote retrived successfully');
        List<SBQQ__Quote__c> quoteWithSubscription = quoteSelector.getQuoteByIdWithSubscriptionType(quote.Id);
        System.assert(!quoteWithSubscription.isEmpty(), 'Quote not retrived successfully');
        List<SBQQ__Quote__c> quoteWithSubscriptionNegative = quoteSelector.getQuoteByIdWithSubscriptionType('1234');
        System.assert(quoteWithSubscriptionNegative.isEmpty(), 'Quote retrived successfully');  
        List<SBQQ__Quote__c> quoteDealDesk = quoteSelector.getQuoteForDealDeskEmail(quote.Id);
        System.assert(!quoteDealDesk.isEmpty(), 'Quote not retrived successfully');
        List<SBQQ__Quote__c> quoteDealDeskNegative = quoteSelector.getQuoteForDealDeskEmail('1234');
        System.assert(quoteDealDeskNegative.isEmpty(), 'Quote retrived successfully');
        List<SBQQ__Quote__c> quoteDealDeskNull = quoteSelector.getQuoteForDealDeskEmail(null);
        System.assertEquals(quoteDealDeskNull, null, 'Quote retrived successfully');
        List<AggregateResult> modifiedTerms = quoteSelector.getModifiedTermsCount('1234');
        System.assert(!modifiedTerms.isEmpty(), 'Modified Terms retrived successfully');
        List<AggregateResult> discountLines = quoteSelector.getDiscountLinesCount('1234');
        System.assert(!discountLines.isEmpty(), 'Discount Lines retrived successfully');
        List<AggregateResult> nonStandardSRApprovalLinesCount = quoteSelector.getNonStandardSRApprovalLinesCount(quote.Id);
        System.assert(!nonStandardSRApprovalLinesCount.isEmpty(),'NonStandardSRApprovalLinesCount retrived successfully');
        List<AggregateResult> nonStandardMoveOutApprovalLinesCount = quoteSelector.getNonStandardMoveOutApprovalLinesCount(quote.Id);
        System.assert(!nonStandardMoveOutApprovalLinesCount.isEmpty(),'NonStandardMoveOutApprovalLinesCount retrived successfully');
    } 

    @isTest
    static void getPrimaryQuotesForOpportunitiesTest(){
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        List<SBQQ__Quote__c> quoteResult = quoteSelector.getPrimaryQuotesForOpportunities(new List<Id>{opp.id});
        System.assert(!quoteResult.isEmpty(), 'Primary Quotes not returned');
    }
}