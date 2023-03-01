/************************************************************************************************************************************
Author      :  Salesforce
Description :  Insert Usage Summaries post Data Migration
Issue No    :  TWSPG-10593

-------------------------------------------------------------------------------------------------------------------------------------
VERSION		DATE      		AUTHOR            	DETAIL
	1       10-MAY-2022     Salesforce          Initial Developement
**************************************************************************************************************************************/
@SuppressWarnings('PMD.FormalParameterNamingConventions')
public class BatchCreateUsageSummariesDataMigration implements Database.Batchable<sObject>, Database.Stateful {
    public Date lastModDate = System.today().AddDays(-1);
    public String query = '';
    public Integer totalSucceededRecords = 0;
    public Integer totalFailedRecords = 0;
    public Date previousMonth;


    public Database.QueryLocator start(Database.BatchableContext batchContext){               
        query = 'SELECT Id, SBQQ__BillingTermUnit__c, SBQQ__BillingTerm__c, SBQQ__Category__c, SBQQ__ConsumptionSchedule__c, SBQQ__Description__c,' +
                ' SBQQ__MatchingAttribute__c, SBQQ__OrderItem__c, SBQQ__RatingMethod__c, SBQQ__Type__c, SBQQ__UnitOfMeasure__c, blng__BillingGLRule__c,' +
                ' blng__BillingGLTreatment__c, blng__BillingRule__c, blng__BillingTreatment__c, blng__FinanceBookAccounting__c, blng__LegalEntity__c,' + 
                ' blng__RevenueRecognitionRule__c, blng__TaxGLRule__c, blng__TaxGLTreatment__c, blng__TaxRule__c, blng__TaxTreatment__c, SBQQ__OrderItem__r.ServiceDate, ' +
                ' SBQQ__OrderItem__r.blng__BillingAccount__c, SBQQ__OrderItem__r.Building_Account_Id__c, SBQQ__OrderItem__r.OrderId, SBQQ__OrderItem__r.Order.OrderNumber' +
                ' FROM SBQQ__OrderItemConsumptionSchedule__c ORDER BY SBQQ__OrderItem__r.Order.OrderNumber DESC';

        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext BC, List<SBQQ__OrderItemConsumptionSchedule__c> orderConsumptionItems) {
        List<blng__UsageSummary__c> usageSummariesToInsert = new List<blng__UsageSummary__c>();
        Integer billingTerm = 0;
        try{
            for(SBQQ__OrderItemConsumptionSchedule__c orderConsumptionItem: orderConsumptionItems){
                billingTerm = Integer.valueOf(orderConsumptionItem.SBQQ__BillingTerm__c);
                for (Integer i = 1; i <= billingTerm; i++) {
                    blng__UsageSummary__c usageSummary = new blng__UsageSummary__c();
                    usageSummary.blng__Account__c = orderConsumptionItem.SBQQ__OrderItem__r.blng__BillingAccount__c;
                    usageSummary.Building_Account_Id__c = orderConsumptionItem.SBQQ__OrderItem__r.Building_Account_Id__c;
                    usageSummary.blng__OrderProduct__c = orderConsumptionItem.SBQQ__OrderItem__c;
                    usageSummary.blng__OrderItemConsumptionSchedule__c = orderConsumptionItem.Id;
                    
                    if(previousMonth==null){
                        usageSummary.blng__SummaryStartDate__c = orderConsumptionItem.SBQQ__OrderItem__r.ServiceDate;
                        usageSummary.blng__SummaryEndDate__c = orderConsumptionItem.SBQQ__OrderItem__r.ServiceDate.addMonths(i).AddDays(-1);
                    }
                    else{
                        usageSummary.blng__SummaryStartDate__c = previousMonth;
                        usageSummary.blng__SummaryEndDate__c = orderConsumptionItem.SBQQ__OrderItem__r.ServiceDate.addMonths(i).AddDays(-1);
                    }                    
                    previousMonth = orderConsumptionItem.SBQQ__OrderItem__r.ServiceDate.addMonths(i);
                    
                    usageSummary.blng__Order__c = orderConsumptionItem.SBQQ__OrderItem__r.OrderId;
                    usageSummary.blng__Status__c = 'New';
                    usageSummary.blng__Source__c = 'External';
                    usageSummary.blng__UnitOfMeasure__c = 'Credits';

                    usageSummariesToInsert.add(usageSummary);
                }                
            }

            for(Database.SaveResult saveResultRecord: Database.insert(usageSummariesToInsert, false)){
                if(saveResultRecord.isSuccess()){
                    totalSucceededRecords += 1;
                } else {
                    totalFailedRecords += 1;
                }
            }            
        } catch (Exception ex) {
            ApexDebugLog.logException(ex, JSON.serialize(orderConsumptionItems), 'BatchCreateUsageSummariesDataMigration', 'execute');
        }
    }

    public void finish(Database.BatchableContext BC) {
        String totalRecords = String.valueOf(totalSucceededRecords + totalFailedRecords);
        
        AsyncApexJob apexJob = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email, CreatedBy.Name 
                                FROM AsyncApexJob WHERE Id =: BC.getJobId()];
        String messageBody = '<html><body>Hi ' + apexJob.CreatedBy.Name+',' + '<br><br>The batch Apex job is processed ' + apexJob.TotalJobItems + 
                             ' batches with '+ apexJob.NumberOfErrors + ' failures.</br></br>'+'<br>Total number of record processed: ' + 
                             totalRecords + '</br><br>Total number of record updated: ' + totalSucceededRecords + '</br><br>Total number of record failed: ' + 
                             totalFailedRecords + '</br><br><br>Thanks !</br></br></body></html>';
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        String[] toAddress = new String[] {apexJob.CreatedBy.Email};
        mail.setToAddresses(toAddress);
        mail.setSubject('Usage Summaries Data Migration Insert Batch Apex Job status is ' + apexJob.Status);
        mail.setHtmlBody(messageBody); 
    	Messaging.sendEmail(new List<Messaging.Email>{ mail });        
    }    
}