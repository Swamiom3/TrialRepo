public with sharing class QuoteExtController {
    private Id quoteId;
    private static final String COMMIT_ERROR = 'Please select Commitment term and Start date for all the Physical Membership/All Acess products in the Quote';
    private static final String BUNDLE_ERROR = 'Please add a Physical Membership workspace to the quote';
    private static final String ADD_ON_NO_INVENTORY_ERROR = 'You had Addons that are not associated with Inventory. Please associate the addons to existing Inventory on the quote before approval.';
    private static final String BILLING_ERROR = 'In order to Preview this Quote, you must go to the related Opportunity and add a Billing Account.';
    private static final String ADD_ON_ERROR = 'The piece of inventory you are trying to associate addons to is not part of this quote or the associated master service contract';
    private static final String TECH_BUNDLE_ERROR = 'You dont have Technology Bundle under quote. Please consider adding before approval or continue with approval.';
    private static final String OPPORTUNITY_STAGE_ERROR = 'The Opportunity must be in Closing in order to Preview Approval. Please go to related Opportunity and update the status.';
    public static QuoteLineSelector quoteLineSelector = new QuoteLineSelector();    
    public Boolean showContinue { get; set; }
    public static QuoteSelector quoteSelector = new QuoteSelector();
    
    public QuoteExtController(ApexPages.StandardController stdController) {
        quoteId = stdController.getId();
        showContinue = false;
    }
    public PageReference onSubmit() {
        if (quoteId != null && validateQuote(quoteId) && validateQuoteLines(quoteId)) {
            SBAA.ApprovalAPI.submit(quoteId, SBAA__Approval__c.Quote__c);
            return new PageReference('/' + quoteId);
        }
        return null;
    }

    public PageReference onContinueSubmit() {
        SBAA.ApprovalAPI.submit(quoteId, SBAA__Approval__c.Quote__c);
        return new PageReference('/' + quoteId);
    }

    public PageReference onRecall() {
        if (quoteId != null) {
            SBAA.ApprovalAPI.recall(quoteId, SBAA__Approval__c.Quote__c);
        }
        return new PageReference('/' + quoteId);
    }
    public PageReference cancel() {
        return new PageReference('/' + quoteId);
    }

    public PageReference onPreview() {
        if (validateQuote(quoteId) && validateOpportunity(quoteId) && validateQuoteLines(quoteId)) {
            return new PageReference('/apex/sbaa__PreviewApprovals?Id=' + quoteId);
        }
        return null;
    }

    public PageReference onContinue() {
        return new PageReference('/apex/sbaa__PreviewApprovals?Id=' + quoteId);
    }
    
    private Boolean validateQuote(Id quoteId){
        SBQQ__Quote__c quote = quoteSelector.getQuoteById(quoteId)[0];
        if(String.IsBlank(quote.Billing_Account__c)){
            showContinue = false;
            String instanceUrl = System.Url.getSalesforceBaseUrl().toExternalForm();
            String link = '<a href="'
                          + instanceUrl +
                          '/lightning/action/quick/Opportunity.Billing_Account_Selector?objectApiName&context=RECORD_DETAIL&recordId='
                          + quote.SBQQ__Opportunity2__c +
                          '&backgroundContext=%2Flightning%2Fr%2FOpportunity%2F'
                          + quote.SBQQ__Opportunity2__c +
                          '%2Fview">Billing Account Selector</a>';
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, BILLING_ERROR + ' ' + link));
            return false;
        }
        return true;
    }
    private Boolean validateQuoteLines(Id quoteId) {
        QuoteExtControllerHelper helper = new QuoteExtControllerHelper();
        List<SBQQ__QuoteLine__c> quoteLines = quoteLineSelector.getQuoteLinesByQuoteId(quoteId);
        if(quoteLines.isEmpty()){
            return false;
        }
        //buildInventoryIds(quoteLines);
        if(helper.isCommitmentError(quoteLines)){
            showContinue = false;
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, COMMIT_ERROR));
            return false;
        }else if(helper.isAddOnInventoryExists(quoteLines)){
            showContinue = false;
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, ADD_ON_NO_INVENTORY_ERROR));
            return false;
        }else if(helper.isAddOnInventoryMatchParent(quoteLines)){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, ADD_ON_ERROR));
            return false;
        }else if(helper.techBundleExists(quoteLines)){
            showContinue = true;
            ApexPages.addmessage(
                new ApexPages.message(ApexPages.severity.WARNING, TECH_BUNDLE_ERROR)
            );
            return false;
        }
        return true;
    }
    
    private Boolean validateOpportunity(Id quoteId){
        List<SBQQ__Quote__c> getQuote = quoteSelector.getQuoteById(quoteId);
        if(String.IsBlank(getQuote.get(0).SBQQ__Opportunity2__c)){
            return false;
        }
        if(getQuote.get(0).SBQQ__Opportunity2__r.StageName != GlobalConstants.OPP_CLOSING_STAGE_NAME){
        	ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,OPPORTUNITY_STAGE_ERROR));
            return false;
        }
        return true;
    }
}