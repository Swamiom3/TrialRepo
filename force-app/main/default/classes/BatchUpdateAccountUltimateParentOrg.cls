/************************************************************************************************************************************
Author      :  Salesforce
Description :  Update Sales Account UltimateParentOrg Field
Issue No    :  TWSPG-12319

-------------------------------------------------------------------------------------------------------------------------------------
VERSION       DATE             AUTHOR                DETAIL
   1      16-JUNE-2022       Salesforce         Initial Developement
**************************************************************************************************************************************/
public class BatchUpdateAccountUltimateParentOrg implements Database.Batchable<sObject>, Database.Stateful {
    public String query = '';
    public static final String ACCOUNT_TYPE_SALES = 'Sales';
    public Integer totalSucceededRecords = 0;
    public Integer totalFailedRecords = 0;
    
    public BatchUpdateAccountUltimateParentOrg(String query){
        this.query = query;
    }
    
    public Database.QueryLocator start(Database.BatchableContext batchContext){
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext batchContext, List<Account > accounts) {
        List<Account> accountsToUpdate = new List<Account>();
        try{
            for(Account accountRecord: accounts){
                accountRecord.Ultimate_Parent_Org__c = Id.valueOf(accountRecord.Parent_Org_Id__c);
                accountsToUpdate.add(accountRecord);
            }
            MetadataDrivenTriggerHandler.disableExecution();
            for(Database.SaveResult saveResultRecord: Database.update(accountsToUpdate, false)){
                if(saveResultRecord.isSuccess()){
                    totalSucceededRecords += 1;
                } else {
                    totalFailedRecords += 1;
                }
            }
            MetadataDrivenTriggerHandler.enableExecution();
        } 
        catch (Exception exe) {
            ApexDebugLog.logException(exe, JSON.serialize(accounts), 'BatchUpdateAccountUltimateParentOrg', 'execute');
        }
    }
    
    public void finish(Database.BatchableContext batchContext) {
        String totalRecords = String.valueOf(totalSucceededRecords + totalFailedRecords);
        
        AsyncApexJob apexJob = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email, CreatedBy.Name 
                                FROM AsyncApexJob WHERE Id =: batchContext.getJobId()];
        String messageBody = '<html><body>Hi '+apexJob.CreatedBy.Name+','+'<br><br>The batch Apex job is processed ' + apexJob.TotalJobItems +
                             ' batches with '+ apexJob.NumberOfErrors + ' failures.</br></br>'+'<br>Total number of record processed: '+totalRecords+
                             '</br><br>Total number of record updated: '+totalSucceededRecords+'</br><br>Total number of record failed: '+totalFailedRecords+
                             '</br><br><br>Thanks !</br></br></body></html>';
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        String[] toAddress = new String[] {apexJob.CreatedBy.Email};
        mail.setToAddresses(toAddress);
        mail.setSubject('Sales Account UltimateParentOrg Field Update Batch Apex Job status is ' + apexJob.Status);
        mail.setHtmlBody(messageBody); 
    	Messaging.sendEmail(new List<Messaging.Email>{ mail });
    }
}