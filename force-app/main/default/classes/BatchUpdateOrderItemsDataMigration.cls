/************************************************************************************************************************************
Author      :  Salesforce
Description :  Update Order Items Data Migration
Issue No    :  TWSPG-10733

-------------------------------------------------------------------------------------------------------------------------------------
VERSION		DATE      		AUTHOR            	DETAIL
   1      9-MAY-2022      Salesforce       Initial Developement
**************************************************************************************************************************************/
public class BatchUpdateOrderItemsDataMigration implements Database.Batchable<sObject>, Database.Stateful {
    public String query = '';
    public static final String USER_FULLNAME = 'Mulesoft Data Migration User';
    public static final String BILLING_INVOICE_RUN_PROCESSING_STATUS = 'Pending Billing';
    public Integer totalSucceededRecords = 0;
    public Integer totalFailedRecords = 0;
    
    public Database.QueryLocator start(Database.BatchableContext batchContext){
 
        query = 'SELECT Id, blng__BillingAccount__c, Order.blng__BillingAccount__c, Building_Account_Id__c, Order.Building_Account_Id__c, SBQQ__BillingType__c,'+
                ' Product2.SBQQ__BillingType__c, SBQQ__BillingFrequency__c, Product2.SBQQ__BillingFrequency__c, SBQQ__ChargeType__c, Product2.SBQQ__ChargeType__c,'+
                ' SBQQ__ProductSubscriptionType__c, Product2.SBQQ__SubscriptionType__c, SBQQ__SubscriptionType__c,'+
                ' blng__BillingRule__c, Product2.blng__BillingRule__c, blng__TaxRule__c, Product2.blng__TaxRule__c, blng__RevenueRecognitionRule__c,'+
                ' Product2.blng__RevenueRecognitionRule__c, Segment_End_Date__c, EndDate, SBQQ__DefaultSubscriptionTerm__c, blng__BillableUnitPrice__c,'+
                ' TotalPrice, blng__InvoiceRunProcessingStatus__c, ServiceDate, blng__BilledAmountwithouttax__c, SBQQ__SubscriptionPricing__c, Product2.SBQQ__SubscriptionPricing__c'+
                ' FROM OrderItem WHERE CreatedBy.Name =: USER_FULLNAME';
        
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext batchContext, List<OrderItem > orderItems) {
        List<OrderItem> orderItemsToUpdate = new List<OrderItem>();
        try{
            for(OrderItem orderItem: orderItems){
                orderItem.blng__BillingAccount__c = orderItem.Order.blng__BillingAccount__c;
                orderItem.Building_Account_Id__c = orderItem.Order.Building_Account_Id__c;
                orderItem.SBQQ__BillingType__c = orderItem.Product2.SBQQ__BillingType__c;
                orderItem.SBQQ__BillingFrequency__c = orderItem.Product2.SBQQ__BillingFrequency__c;
                orderItem.SBQQ__ChargeType__c = orderItem.Product2.SBQQ__ChargeType__c;
                orderItem.SBQQ__ProductSubscriptionType__c = orderItem.Product2.SBQQ__SubscriptionType__c;
                orderItem.SBQQ__SubscriptionType__c = orderItem.Product2.SBQQ__SubscriptionType__c;
                orderItem.blng__BillingRule__c = orderItem.Product2.blng__BillingRule__c;
                orderItem.blng__TaxRule__c = orderItem.Product2.blng__TaxRule__c;
                orderItem.blng__RevenueRecognitionRule__c = orderItem.Product2.blng__RevenueRecognitionRule__c;
                orderItem.Segment_End_Date__c = orderItem.EndDate;
                orderItem.SBQQ__DefaultSubscriptionTerm__c = 1.0;
                orderItem.blng__BillableUnitPrice__c = orderItem.TotalPrice;
                if(orderItem.ServiceDate != null && orderItem.ServiceDate >= System.today()){
                    orderItem.blng__InvoiceRunProcessingStatus__c = BILLING_INVOICE_RUN_PROCESSING_STATUS;
                }
                orderItem.blng__BilledAmountwithouttax__c = 0.0;
                orderItem.SBQQ__SubscriptionPricing__c = orderItem.Product2.SBQQ__SubscriptionPricing__c;
                orderItemsToUpdate.add(orderItem);
            }
            for(Database.SaveResult saveResultRecord: Database.update(orderItemsToUpdate, false)){
                if(saveResultRecord.isSuccess()){
                    totalSucceededRecords += 1;
                } else {
                    totalFailedRecords += 1;
                }
            }
        } 
        catch (Exception exe) {
            ApexDebugLog.logException(exe, JSON.serialize(orderItems), 'BatchUpdateOrderItemsDataMigration', 'execute');
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
        mail.setSubject('Order Item Data Migration Field Update Batch Apex Job status is ' + apexJob.Status);
        mail.setHtmlBody(messageBody); 
    	Messaging.sendEmail(new List<Messaging.Email>{ mail });
    }
}