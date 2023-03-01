/************************************************************************************************************************************
Author      :   Tayo Chestnut
Description :   This apex class create JSON for Workday Platform Events
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION      DATE         AUTHOR              DETAIL
    1            09/28/2021   Tayo Chestnut     Execute from Flow
**************************************************************************************************************************************/
public with sharing class PlatformEventsWorkday {
	
    @InvocableMethod (label='JSON Stringify Child Lines' description='JSON Listing of Child Lines' category='Workday')
    public static void publishWorkdayEvent(List<Request> requests) {
        List<String> returnString = new List<String>();
        List<List<String>> returnStringFinal = new List<List<String>>();
        List<Payment_Event__e> payEvents=new List<Payment_Event__e>();
        List<Invoice_Event__e> invoiceEvents=new List<Invoice_Event__e>();
        List<Order_Contract__e> orderEvents=new List<Order_Contract__e>();
        List<Task> taskList = new List<Task>();

        String category = requests.get(0).category;
        String outputJSON;
        
        for(integer count=0;count<requests.size();count++){
            Request req = requests[count];
            switch on category {
                when 'Payment'{
                    outputJSON = JSON.serialize(req.paymentLines);
                    req.paymentEvent.Details__c = outputJSON;
                    payEvents.add(req.paymentEvent);
                }when 'Invoice'{
                    outputJSON = JSON.serialize(req.invoiceCreditDebitLines);
                    req.invoiceEvent.Line_Details__c = outputJSON;
                    invoiceEvents.add(req.invoiceEvent);
                }when 'Credit'{
                    for(Invoice_Event__e creditPEs: req.creditDebitEvents){
                        outputJSON = JSON.serialize(req.invoiceCreditDebitLines);
                        creditPEs.Line_Details__c = outputJSON;
                        invoiceEvents.add(creditPEs);
                    }
                }when 'Debit'{
                    if(req.creditDebitEvents!=null){
                        for(Invoice_Event__e debitPEs: req.creditDebitEvents){
                            outputJSON = JSON.serialize(req.invoiceCreditDebitLines);
                            debitPEs.Line_Details__c = outputJSON;
                            invoiceEvents.add(debitPEs);
                        }
                    }
                    
                }when 'Order'{
                    outputJSON = JSON.serialize(req.orderLines);
                    req.orderEvent.Order_Line_Items__c = outputJSON;
                    orderEvents.add(req.orderEvent);
                }
            }
        }    
        
        List<Database.SaveResult> results = new List<Database.SaveResult>();
        switch on category {
            when 'Payment' {
                results = EventBus.publish(payEvents);
            }when 'Invoice', 'Credit', 'Debit' {
                results = EventBus.publish(invoiceEvents);
            }when 'Order' {
                results = EventBus.publish(orderEvents);
            }
        }

        for (Database.SaveResult sr : results) {    
            if (!sr.isSuccess()) {
                for(Database.Error err : sr.getErrors()) {
                    Task errorTask = new Task();
                    errorTask.Description = category + ' ' + err.getStatusCode() + ': ' + err.getMessage();
                    errorTask.Subject = 'Platform Event Error';
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
        public List<PaymentLineWrapper> paymentLines;

        @InvocableVariable
        public Payment_Event__e paymentEvent;

        @InvocableVariable
        public List<OrderLineWrapper> orderLines;

        @InvocableVariable
        public Order_Contract__e orderEvent;

        @InvocableVariable
        public List<InvoicesCreditsDebitsWrapper> invoiceCreditDebitLines;

        @InvocableVariable
        public Invoice_Event__e invoiceEvent;

        @InvocableVariable
        public List<Invoice_Event__e> creditDebitEvents;

        @InvocableVariable
        public String category;
    }
}