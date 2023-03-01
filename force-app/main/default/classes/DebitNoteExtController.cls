public with sharing class DebitNoteExtController {
    private Id dnId;
    public DebitNoteExtController(ApexPages.StandardController stdController) {
        dnId = stdController.getId();
    }
    public PageReference onSubmit() {
        if (dnId != null) {
            SBAA.ApprovalAPI.submit(dnId, SBAA__Approval__c.Debit_Note_Id__c);
        }
        return new PageReference('/' + dnId);
    }
    public PageReference onRecall() {
        if (dnId != null) {
            SBAA.ApprovalAPI.recall(dnId, SBAA__Approval__c.Debit_Note_Id__c);
        }
        return new PageReference('/' + dnId);
    }
}