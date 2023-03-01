/************************************************************************************************************************************
    Author      :   Stepan Vardzal
    Description :   Used to update MSA PaymentTerms on Account objact
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION     DATE                AUTHOR                  DETAIL
    1           Jul 07, 2022        Stepan Vardzal          Initial version
**************************************************************************************************************************************/
public class MSAPaymentTermsUpdatedOnAccountsBatch implements Database.Batchable<SObject>, Database.Stateful {
    @TestVisible
    private Integer totalSucceededRecords = 0;
    @TestVisible
    private Integer totalFailedRecords = 0;

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([SELECT Id, Payment_Terms__c FROM Account WHERE MSA_Expiration__c = null and Payment_Terms__c = 'Due on receipt']);
    }

    public void execute(Database.BatchableContext bc, List<Account> accountsForUpdate){
        paymentTermsFieldUpdate(accountsForUpdate);
    }
    
    public void finish(Database.BatchableContext bc){
        AsyncApexJob apexJob = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email, CreatedBy.Name FROM AsyncApexJob WHERE Id = :bc.getJobId()];
        getResultMessage(apexJob.CreatedBy.Name, apexJob.TotalJobItems, apexJob.NumberOfErrors, apexJob.CreatedBy.Email, apexJob.Status);
    }

    @TestVisible
    private void paymentTermsFieldUpdate(List<Account> accountsForUpdate) {
        try {
            for (Account account : accountsForUpdate) {
                account.Payment_Terms__c = null;
            }
            for(Database.SaveResult saveResultRecord: Database.update(accountsForUpdate, false)){
                if(saveResultRecord.isSuccess()){
                    totalSucceededRecords += 1;
                } else {
                    totalFailedRecords += 1;
                }
            }     
        } catch (Exception ex) {
            ApexDebugLog.logException(ex, JSON.serialize(accountsForUpdate), 'MSAPaymentTermsUpdatedOnAccountsBatch', 'execute');
        }   
    }

    @TestVisible
    private void getResultMessage(String createdByName, Integer totalJobItems, Integer numberOfErrors, String createdByEmail, String status) {
        String totalRecords = String.valueOf(totalSucceededRecords + totalFailedRecords);
        String messageBody = '<html><body>Hi ' + createdByName +',' + '<br><br>The batch Apex job is processed ' + totalJobItems + 
                             ' batches with '+ numberOfErrors + ' failures.</br></br>'+'<br>Total number of record processed: ' + 
                             totalRecords + '</br><br>Total number of record updated: ' + totalSucceededRecords + '</br><br>Total number of record failed: ' + 
                             totalFailedRecords + '</br><br><br>Thanks !</br></br></body></html>';
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        String[] toAddress = new String[] {createdByEmail};
        mail.setToAddresses(toAddress);
        mail.setSubject('MSA PaymentTerms Updated On Accounts Batch Apex Job status is ' + status);
        mail.setHtmlBody(messageBody);
        Messaging.sendEmail(new List<Messaging.Email>{ mail });
    }
}