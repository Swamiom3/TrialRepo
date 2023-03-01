/************************************************************************************************************************************
    Author      :   Arun Vadduri
    Description :   This class call the logic required within Small Deal Desk Email Template.
    Issue No    :   TWSPG-4305
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION      DATE          AUTHOR            DETAIL
    1        8 November 2021    Arun Vadduri     Initial Development
**************************************************************************************************************************************/
public with sharing class SmallDealDeskTemplateController {
    public Id quoteId {get; set;}
    public SBQQ__Quote__c quote {
        get {
            if(quote == null) {
                List<SBQQ__Quote__c> quotes = this.quoteSelector.getQuoteForDealDeskEmail(this.quoteId);
                if(quotes != null && !quotes.isEmpty()) {
                    quote = quotes[0];
                }
            }
            return quote;
        }
        set;
    }
    private QuoteSelector quoteSelector;
    public Integer modifiedTermsCount {
        get {
            if(modifiedTermsCount == null) {
                List<AggregateResult> result = this.quoteSelector.getModifiedTermsCount(this.quoteId);
                modifiedTermsCount = (Integer) result[0].get('totalTerms');
            }
            return modifiedTermsCount;
        }
        private set;
    }
    
    public Integer discountLinesCount {
        get {
            if(discountLinesCount == null) {
                List<AggregateResult> result = this.quoteSelector.getDiscountLinesCount(this.quoteId);
                discountLinesCount = (Integer) result[0].get('totalLines');
            }
            return discountLinesCount;
        }
        private set;
    }
    
    public Integer nonStandardSRApprovalLinesCount {
        get {
            if(nonStandardSRApprovalLinesCount == null) {
                List<AggregateResult> result = this.quoteSelector.getNonStandardSRApprovalLinesCount(this.quoteId);
                nonStandardSRApprovalLinesCount = (Integer) result[0].get('totalLines');
            }
            return nonStandardSRApprovalLinesCount;
        }
        private set;
    }
    
    public Integer nonStandardMoveOutApprovalLinesCount {
        get {
            if(nonStandardMoveOutApprovalLinesCount == null) {
                List<AggregateResult> result = this.quoteSelector.getNonStandardMoveOutApprovalLinesCount(this.quoteId);
                nonStandardMoveOutApprovalLinesCount = (Integer) result[0].get('totalLines');
            }
            return nonStandardMoveOutApprovalLinesCount;
        }
        private set;
    }
    
    public SmallDealDeskTemplateController() {
        this.quoteSelector = new QuoteSelector();
    }
}