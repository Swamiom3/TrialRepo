/************************************************************************************************************************************
Author      :   Tayo Chestnut
Description :   This apex class create JSON for Bank Information and Settlment Data
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION      DATE         AUTHOR              DETAIL
    1            09/28/2021   Tayo Chestnut     Execute from Flow
**************************************************************************************************************************************/
public with sharing class BankInformationSettlementProcessor {
	
    @InvocableMethod (label='Bank Info and Settlement Data' description='JSON Listing for Band and Settlment Data' category='Mulesoft')
    public static void createBankInformationIntegration(List<Request> requests) {

        List<SObject> recordsToUpdate = new List<SObject>();
        List<Task> taskList = new List<Task>();

        String category = requests.get(0).category;
        String outputJSON;
        Decimal maxCounter;
        String memoDate = String.valueOf(System.today().year()) + String.valueOf(System.today().month()) + String.valueOf(System.today().day());
        String eftMemo = '';
        RefundSelector rSelector = new RefundSelector();
        List<blng__Refund__c> maxCounterRefunds = rSelector.getCurrentRefundCounter(memoDate);
        
        maxCounter = maxCounterRefunds.isEmpty() ? 1 : maxCounterRefunds.get(0).Sequential_Bank_Counter__c + 1;
         
        for(Integer count = 0; count < requests.size(); count++){
            Request req = requests[count];

            switch on category {
                when 'Refunds'{               
                    eftMemo = 'RF' + req.refundRecord.get(0).Batch_Date__c + '-' +  String.valueOf(maxCounter).leftPad(5,'0');
                    req.bankSettlementRecord.get(0).eftCheckMemo = eftMemo;
                    outputJSON = JSON.serialize(req.bankSettlementRecord);
                    req.refundRecord.get(0).Settlement_Data__c = outputJSON;
                    req.refundRecord.get(0).Sequential_Bank_Counter__c = maxCounter;
                    recordsToUpdate.add(req.refundRecord.get(0));
                }
                when 'PaymentMethods'{
                    outputJSON = JSON.serialize(req.bankWireRecord);
                    req.paymentMethodRecord.get(0).Wire_Information__c = outputJSON;
                    recordsToUpdate.add(req.paymentMethodRecord.get(0));
                }
            }
            maxCounter++;
        }    

        List<Database.SaveResult> results = new List<Database.SaveResult>();
        results = Database.update(recordsToUpdate);

        for (Database.SaveResult sr : results) {    
            if (!sr.isSuccess()) {
                for(Database.Error err : sr.getErrors()) {
                    Task errorTask = new Task();
                    errorTask.Description = category + ' ' + err.getStatusCode() + ': ' + err.getMessage();
                    errorTask.Subject = 'Integration Error';
                    errorTask.ActivityDate = System.today();
                    errorTask.Priority = 'High';
                    errorTask.Status = 'Open';
                    taskList.add(errorTask);            
                }
            }    
        }

        if(!taskList.isEmpty()){
            insert taskList;
        }
    }

    public class Request{
        @InvocableVariable
        public List<BankSettlementRecord> bankSettlementRecord;

        @InvocableVariable
        public List<BankAccountWireInformation> bankWireRecord;

        @InvocableVariable
        public List<blng__Refund__c> refundRecord;

        @InvocableVariable
        public List<blng__PaymentMethod__c> paymentMethodRecord;

        @InvocableVariable
        public String category;
    }
}