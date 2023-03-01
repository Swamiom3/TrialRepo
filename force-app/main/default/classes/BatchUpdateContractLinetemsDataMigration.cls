/************************************************************************************************************************************
Author      :  Salesforce
Description :  Update Contract Line Items Data Migration
Issue No    :  TWSPG-10771

-------------------------------------------------------------------------------------------------------------------------------------
VERSION		DATE      		AUTHOR            	DETAIL
	1       9-MAY-2022      Salesforce            Initial Developement
**************************************************************************************************************************************/
@SuppressWarnings('PMD.FormalParameterNamingConventions')
public class BatchUpdateContractLinetemsDataMigration implements Database.Batchable<sObject>, Database.Stateful {
    public static final String USER_FULLNAME = 'Mulesoft Data Migration User';
    public Date lastModDate = System.today().AddDays(-1);
    public String query = '';
    public Integer totalSucceededRecords = 0;
    public Integer totalFailedRecords = 0;

    public Database.QueryLocator start(Database.BatchableContext batchContext){               
        query = 'SELECT Id, SBQQSC__ChargeType__c, ServiceContractId, ServiceContract.SBQQSC__Order__c, ServiceContract.Pricebook2Id, Product2Id, Product2.SBQQ__ChargeType__c, '+
                ' SBQQSC__CustomerPrice__c, UnitPrice, SBQQSC__NetPrice__c, SBQQSC__Product__c, SBQQSC__ProrateMultiplier__c, SBQQSC__RegularPrice__c, SBQQSC__RenewalQuantity__c,' +
                ' SBQQSC__RootId__c, SBQQSC__SpecialPrice__c, SBQQSC__SubscriptionEndDate__c, ServiceContract.EndDate, SBQQSC__SubscriptionStartDate__c, ServiceContract.StartDate,' +
                ' Building_Id__c, ServiceContract.Building_Id__c, Inventory_Id__c, Segment_End_Date__c, SBQQSC__SegmentEndDate__c, SBQQSC__OrderProduct__c, SBQQSC__SubscriptionType__c,' + 
                ' Subscription_Type__c, SBQQSC__ProductSubscriptionType__c, SBQQSC__SubscriptionPricing__c, Product_Code__c, SBQQSC__Bundle__c, Inventory_Name__c, Product2.SBQQ__BillingType__c, SBQQSC__BillingType__c' +
                ' FROM ContractLineItem WHERE CreatedBy.Name =: USER_FULLNAME ' +
                ' AND ServiceContract.SBQQSC__Order__c <> NULL';

        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext BC, List<ContractLineItem> contractItems) {
        List<ContractLineItem> contractItemsToUpdate = new List<ContractLineItem>();
        Set<Id> contractIds = (new Map<Id, ContractLineItem>(contractItems)).keySet();
        Set<Id> priceBookIds = new Set<Id>();
        Set<Id> orderIds = new Set<Id>();        
        Map<Id, PricebookEntry> priceBookEntryMap =  new Map<Id, PricebookEntry>();
        Map<String, OrderItem> orderItemsMap =  new Map<String, OrderItem>();
        Boolean isHeader = false;

        for(ContractLineItem contractItem : contractItems){
            priceBookIds.add(contractItem.ServiceContract.Pricebook2Id);
            orderIds.add(contractItem.ServiceContract.SBQQSC__Order__c);
        }

        List<PricebookEntry> priceBookEntries = [SELECT Id, Pricebook2Id, Product2Id, Product2.SBQQ__ChargeType__c, Product2.SBQQ__BillingType__c, Product2.SBQQ__SubscriptionType__c, Product2.SBQQ__SubscriptionPricing__c, Product2.ProductCode,Product2.Family FROM PricebookEntry WHERE Pricebook2Id IN: priceBookIds];
        List<OrderItem> orderItems = [SELECT Id, OrderId, EndDate, Product2Id, Inventory_Id__c, Inventory_Id__r.Name FROM OrderItem WHERE OrderId IN: orderIds];

        for(OrderItem orderItem : orderItems){
            orderItemsMap.put(orderItem.Product2Id + '|' + orderItem.Inventory_Id__c, orderItem);
        }

        for(PricebookEntry priceBookEntry : priceBookEntries){
            priceBookEntryMap.put(priceBookEntry.Product2Id, priceBookEntry);
        }

        try{
            for(ContractLineItem contractItem: contractItems){                
                contractItem.SBQQSC__CustomerPrice__c = contractItem.UnitPrice;
                contractItem.SBQQSC__NetPrice__c = contractItem.UnitPrice;
                contractItem.SBQQSC__RegularPrice__c = contractItem.UnitPrice;
                contractItem.SBQQSC__SpecialPrice__c = contractItem.UnitPrice;
                contractItem.SBQQSC__Product__c = contractItem.Product2Id;                
                contractItem.SBQQSC__ProrateMultiplier__c = 1;
                contractItem.SBQQSC__RenewalQuantity__c = 1;
                contractItem.SBQQSC__RootId__c = contractItem.Id;
                contractItem.SBQQSC__SubscriptionEndDate__c = contractItem.ServiceContract.EndDate;
                contractItem.SBQQSC__SubscriptionStartDate__c = contractItem.ServiceContract.StartDate;
                contractItem.Building_Id__c = contractItem.ServiceContract.Building_Id__c;                
                
                OrderItem orderItem  = orderItemsMap.get(contractItem.Product2Id + '|' + contractItem.Inventory_Id__c);
                contractItem.SBQQSC__OrderProduct__c = orderItem.Id;
                contractItem.Segment_End_Date__c = orderItem.EndDate;          
                contractItem.Inventory_Id__c = orderItem.Inventory_Id__c;      
                contractItem.Inventory_Name__c = orderItem.Inventory_Id__r.Name;

                PricebookEntry priceBookEntry = priceBookEntryMap.get(contractItem.Product2Id);
                contractItem.SBQQSC__ChargeType__c = priceBookEntry.Product2.SBQQ__ChargeType__c;
                contractItem.SBQQSC__BillingType__c = priceBookEntry.Product2.SBQQ__BillingType__c;                
                contractItem.SBQQSC__SubscriptionType__c = priceBookEntry.Product2.SBQQ__SubscriptionType__c;
                contractItem.SBQQSC__ProductSubscriptionType__c = priceBookEntry.Product2.SBQQ__SubscriptionType__c;
                contractItem.SBQQSC__SubscriptionPricing__c = priceBookEntry.Product2.SBQQ__SubscriptionPricing__c;
                contractItem.Product_Code__c = priceBookEntry.Product2.ProductCode;
                if(priceBookEntry.Product2.ProductCode == 'M2M' || priceBookEntry.Product2.ProductCode == 'PHYS-MBRSHP' || priceBookEntry.Product2.Family=='All Access'){
                    isHeader =  true;
                }
                contractItem.SBQQSC__Bundle__c = isHeader;

                contractItemsToUpdate.add(contractItem);
            }

            for(Database.SaveResult saveResultRecord: Database.update(contractItemsToUpdate, false)){
                if(saveResultRecord.isSuccess()){
                    totalSucceededRecords += 1;
                } else {
                    totalFailedRecords += 1;
                }
            }            
        } catch (Exception ex) {
            ApexDebugLog.logException(ex, JSON.serialize(contractItems), 'BatchUpdateContractLinetemsDataMigration', 'execute');
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
        mail.setSubject('Contract Line Item Data Migration Field Update Batch Apex Job status is ' + apexJob.Status);
        mail.setHtmlBody(messageBody); 
    	Messaging.sendEmail(new List<Messaging.Email>{ mail });        
    }
}