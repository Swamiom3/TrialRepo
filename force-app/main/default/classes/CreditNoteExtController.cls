public with sharing class CreditNoteExtController {
    private Id quoteId;
    public CreditNoteExtController(ApexPages.StandardController stdController) {
        quoteId = stdController.getId();
    }
    public PageReference onSubmit() {
        if (quoteId != null) {
            SBAA.ApprovalAPI.submit(quoteId, SBAA__Approval__c.Credit_Note_Id__c);
        }
        return new PageReference('/' + quoteId);
    }
    public PageReference onRecall() {
        if (quoteId != null) {
            SBAA.ApprovalAPI.recall(quoteId, SBAA__Approval__c.Credit_Note_Id__c);
        }
        return new PageReference('/' + quoteId);
    }
}