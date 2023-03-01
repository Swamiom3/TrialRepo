@isTest
public class PlatformEventsWorkdayTest {

    @isTest
    public static void testPaymentEventPositive() {
        Test.startTest();
        String paymentWjsonString = '{"remittanceType":"Test","details":"Test", "paymentId": "Test", "amountToPay": 100, "invoiceCurrency": "USD", "billToCustomer":"Test"}';
        PaymentLineWrapper pLineWrapper = (PaymentLineWrapper)JSON.deserialize(paymentWjsonString, PaymentLineWrapper.class);
        List<PaymentLineWrapper> pLineWrapperList = new List<PaymentLineWrapper>();
        pLineWrapperList.add(pLineWrapper);    
        Payment_Event__e paymentEvent = new Payment_Event__e();
        
        List<PlatformEventsWorkday.Request> requests = new List<PlatformEventsWorkday.Request>();
        PlatformEventsWorkday.Request platformWorkday = new PlatformEventsWorkday.Request();
        platformWorkday.category = 'Payment';
        platformWorkday.paymentLines = pLineWrapperList;
        platformWorkday.paymentEvent = new Payment_Event__e(Amount_to_Pay__c = 0);
        requests.add(platformWorkday);
        PlatformEventsWorkday.publishWorkdayEvent(requests);
        Test.stopTest();
        List<Task> checkTasks = new List<Task>([Select id from Task]);
        System.assertEquals(0, checkTasks.size(),'Failed and Platform Events Not Created Successfully');
    }

    @isTest
    public static void testPaymentEventNegative() {
        Test.startTest();
        String paymentWjsonString = '{"remittanceType":"Test","details":"Test", "paymentId": "Test", "amountToPay": 100, "invoiceCurrency": "USD", "billToCustomer":"Test"}';
        PaymentLineWrapper pLineWrapper = (PaymentLineWrapper)JSON.deserialize(paymentWjsonString, PaymentLineWrapper.class);
        List<PaymentLineWrapper> pLineWrapperList = new List<PaymentLineWrapper>();
        pLineWrapperList.add(pLineWrapper);    
        Payment_Event__e paymentEvent = new Payment_Event__e();
        
        List<PlatformEventsWorkday.Request> requests = new List<PlatformEventsWorkday.Request>();
        PlatformEventsWorkday.Request platformWorkday = new PlatformEventsWorkday.Request();
        platformWorkday.category = 'Payment';
        platformWorkday.paymentLines = pLineWrapperList;
        platformWorkday.paymentEvent = new Payment_Event__e();
        requests.add(platformWorkday);
        PlatformEventsWorkday.publishWorkdayEvent(requests);
        Test.stopTest();
        List<Task> checkTasks = new List<Task>([Select id from Task]);
        System.assertEquals(1, checkTasks.size(),'Platform Events Created Successfully');
    }

    @isTest
    public static void testInvoiceEventPositive(){
        Test.startTest();
        String invoiceCreditDebitWrapperJSON = '{"id":"1234","lineDescription":"test","invoiceId":"INV-01",';
        invoiceCreditDebitWrapperJSON += '"discount":100,"discountAmount":100,"currencyIsoCode":"USD",';
        invoiceCreditDebitWrapperJSON += '"quantity":10,"totalAmount":100,"productUUID":"Test","UOM":"Test",';
        invoiceCreditDebitWrapperJSON += '"contractLineId":"1234","taxable":true,"taxCode":"Test","taxRate":10,';
        invoiceCreditDebitWrapperJSON += '"taxType":"Test","creditAmount":"10","debitAmount":"10"}';
        InvoicesCreditsDebitsWrapper invoiceCDWrapper = (InvoicesCreditsDebitsWrapper)JSON.deserialize(invoiceCreditDebitWrapperJSON, InvoicesCreditsDebitsWrapper.class);
        List<InvoicesCreditsDebitsWrapper> invoiceCDWrapperList = new List<InvoicesCreditsDebitsWrapper>();
        invoiceCDWrapperList.add(invoiceCDWrapper);

        List<PlatformEventsWorkday.Request> requests = new List<PlatformEventsWorkday.Request>();
        PlatformEventsWorkday.Request platformWorkday = new PlatformEventsWorkday.Request();
        platformWorkday.category = 'Invoice';
        platformWorkday.invoiceCreditDebitLines = invoiceCDWrapperList;
        platformWorkday.invoiceEvent = new Invoice_Event__e(Invoice_Type__c = 'Standard', Invoice_ID__c = 'TestInvoiceID',Payment_Terms__c = 'Terms', Currency__c = 'CAD', Sold_to_Customer__c = 'Customer');
        requests.add(platformWorkday);
        PlatformEventsWorkday.publishWorkdayEvent(requests);
        Test.stopTest();

        List<Task> checkTasks = new List<Task>([Select id, Description from Task]);
        System.assertEquals(0, checkTasks.size(),'Failed and Platform Events Not Created Successfully');
    }
    @isTest
    public static void testInvoiceEventNegative(){
        Test.startTest();
        String invoiceCreditDebitWrapperJSON = '{"id":"1234","lineDescription":"test","invoiceId":"INV-01",';
        invoiceCreditDebitWrapperJSON += '"discount":100,"discountAmount":100,"currencyIsoCode":"USD",';
        invoiceCreditDebitWrapperJSON += '"quantity":10,"totalAmount":100,"productUUID":"Test","UOM":"Test",';
        invoiceCreditDebitWrapperJSON += '"contractLineId":"1234","taxable":true,"taxCode":"Test","taxRate":10,';
        invoiceCreditDebitWrapperJSON += '"taxType":"Test","creditAmount":"10","debitAmount":"10"}';
        InvoicesCreditsDebitsWrapper invoiceCDWrapper = (InvoicesCreditsDebitsWrapper)JSON.deserialize(invoiceCreditDebitWrapperJSON, InvoicesCreditsDebitsWrapper.class);
        List<InvoicesCreditsDebitsWrapper> invoiceCDWrapperList = new List<InvoicesCreditsDebitsWrapper>();
        invoiceCDWrapperList.add(invoiceCDWrapper);

        List<PlatformEventsWorkday.Request> requests = new List<PlatformEventsWorkday.Request>();
        PlatformEventsWorkday.Request platformWorkday = new PlatformEventsWorkday.Request();
        platformWorkday.category = 'Invoice';
        platformWorkday.invoiceCreditDebitLines = invoiceCDWrapperList;
        platformWorkday.invoiceEvent = new Invoice_Event__e(Invoice_ID__c = 'TestInvoiceID',Payment_Terms__c = 'Terms', Currency__c = 'CAD', Sold_to_Customer__c = 'Customer');
        requests.add(platformWorkday);
        PlatformEventsWorkday.publishWorkdayEvent(requests);
        Test.stopTest();
        
        List<Task> checkTasks = new List<Task>([Select id, Description from Task]);
        System.assertEquals(1, checkTasks.size(),'Platform Events Created Successfully');
    }
    @isTest
    public static void testCreditEventPositive(){
        Test.startTest();
        String invoiceCreditDebitWrapperJSON = '{"id":"1234","lineDescription":"test","invoiceId":"INV-01",';
        invoiceCreditDebitWrapperJSON += '"discount":100,"discountAmount":100,"currencyIsoCode":"USD",';
        invoiceCreditDebitWrapperJSON += '"quantity":10,"totalAmount":100,"productUUID":"Test","UOM":"Test",';
        invoiceCreditDebitWrapperJSON += '"contractLineId":"1234","taxable":true,"taxCode":"Test","taxRate":10,';
        invoiceCreditDebitWrapperJSON += '"taxType":"Test","creditAmount":"10","debitAmount":"10"}';
        InvoicesCreditsDebitsWrapper invoiceCDWrapper = (InvoicesCreditsDebitsWrapper)JSON.deserialize(invoiceCreditDebitWrapperJSON, InvoicesCreditsDebitsWrapper.class);
        List<InvoicesCreditsDebitsWrapper> invoiceCDWrapperList = new List<InvoicesCreditsDebitsWrapper>();
        invoiceCDWrapperList.add(invoiceCDWrapper);
        List<Invoice_Event__e> invoiceEventList = new List<Invoice_Event__e>();
        Invoice_Event__e invoiceEvent = new Invoice_Event__e(Invoice_Type__c = 'Standard', Invoice_ID__c = 'TestInvoiceID', Payment_Terms__c = 'Terms', Currency__c = 'CAD', Sold_to_Customer__c = 'Customer');
        invoiceEventList.add(invoiceEvent);
        List<PlatformEventsWorkday.Request> requests = new List<PlatformEventsWorkday.Request>();
        PlatformEventsWorkday.Request platformWorkday = new PlatformEventsWorkday.Request();
        platformWorkday = new PlatformEventsWorkday.Request();
        platformWorkday.category = 'Credit';
        platformWorkday.invoiceCreditDebitLines = invoiceCDWrapperList;
        platformWorkday.creditDebitEvents = invoiceEventList;
        requests.add(platformWorkday);
        PlatformEventsWorkday.publishWorkdayEvent(requests);
        Test.stopTest();

        List<Task> checkTasksCredit = new List<Task>([Select id from Task]);
        System.assertEquals(0, checkTasksCredit.size(),'Failed and Platform Events Not Created Successfully');

    }

    @isTest
    public static void testCreditEventNegative(){
        Test.startTest();
        String invoiceCreditDebitWrapperJSON = '{"id":"1234","lineDescription":"test","invoiceId":"INV-01",';
        invoiceCreditDebitWrapperJSON += '"discount":100,"discountAmount":100,"currencyIsoCode":"USD",';
        invoiceCreditDebitWrapperJSON += '"quantity":10,"totalAmount":100,"productUUID":"Test","UOM":"Test",';
        invoiceCreditDebitWrapperJSON += '"contractLineId":"1234","taxable":true,"taxCode":"Test","taxRate":10,';
        invoiceCreditDebitWrapperJSON += '"taxType":"Test","creditAmount":"10","debitAmount":"10"}';
        InvoicesCreditsDebitsWrapper invoiceCDWrapper = (InvoicesCreditsDebitsWrapper)JSON.deserialize(invoiceCreditDebitWrapperJSON, InvoicesCreditsDebitsWrapper.class);
        List<InvoicesCreditsDebitsWrapper> invoiceCDWrapperList = new List<InvoicesCreditsDebitsWrapper>();
        invoiceCDWrapperList.add(invoiceCDWrapper);
        List<Invoice_Event__e> invoiceEventList = new List<Invoice_Event__e>();
        Invoice_Event__e invoiceEvent = new Invoice_Event__e(Invoice_ID__c = 'TestInvoiceID', Payment_Terms__c = 'Terms', Currency__c = 'CAD', Sold_to_Customer__c = 'Customer');
        invoiceEventList.add(invoiceEvent);
        List<PlatformEventsWorkday.Request> requests = new List<PlatformEventsWorkday.Request>();
        PlatformEventsWorkday.Request platformWorkday = new PlatformEventsWorkday.Request();
        platformWorkday = new PlatformEventsWorkday.Request();
        platformWorkday.category = 'Credit';
        platformWorkday.invoiceCreditDebitLines = invoiceCDWrapperList;
        platformWorkday.creditDebitEvents = invoiceEventList;
        requests.add(platformWorkday);
        PlatformEventsWorkday.publishWorkdayEvent(requests);
        Test.stopTest();

        List<Task> checkTasksCredit = new List<Task>([Select id from Task]);
        System.assertEquals(1, checkTasksCredit.size(),'Platform Events Created Successfully');

    }

    @isTest
    public static void testDebitEventPositive(){
        Test.startTest();
        String invoiceCreditDebitWrapperJSON = '{"id":"1234","lineDescription":"test","invoiceId":"INV-01",';
        invoiceCreditDebitWrapperJSON += '"discount":100,"discountAmount":100,"currencyIsoCode":"USD",';
        invoiceCreditDebitWrapperJSON += '"quantity":10,"totalAmount":100,"productUUID":"Test","UOM":"Test",';
        invoiceCreditDebitWrapperJSON += '"contractLineId":"1234","taxable":true,"taxCode":"Test","taxRate":10,';
        invoiceCreditDebitWrapperJSON += '"taxType":"Test","creditAmount":"10","debitAmount":"10"}';
        InvoicesCreditsDebitsWrapper invoiceCDWrapper = (InvoicesCreditsDebitsWrapper)JSON.deserialize(invoiceCreditDebitWrapperJSON, InvoicesCreditsDebitsWrapper.class);
        List<InvoicesCreditsDebitsWrapper> invoiceCDWrapperList = new List<InvoicesCreditsDebitsWrapper>();
        invoiceCDWrapperList.add(invoiceCDWrapper);
        List<Invoice_Event__e> invoiceEventList = new List<Invoice_Event__e>();
        Invoice_Event__e invoiceEvent = new Invoice_Event__e(Invoice_Type__c = 'Standard', Invoice_ID__c = 'TestInvoiceID', Payment_Terms__c = 'Terms', Currency__c = 'CAD', Sold_to_Customer__c = 'Customer');
        invoiceEventList.add(invoiceEvent);
        List<PlatformEventsWorkday.Request> requests = new List<PlatformEventsWorkday.Request>();
        PlatformEventsWorkday.Request platformWorkday = new PlatformEventsWorkday.Request();
        platformWorkday = new PlatformEventsWorkday.Request();
        platformWorkday.category = 'Debit';
        platformWorkday.invoiceCreditDebitLines = invoiceCDWrapperList;
        platformWorkday.creditDebitEvents = invoiceEventList;
        requests.add(platformWorkday);
        PlatformEventsWorkday.publishWorkdayEvent(requests);
        Test.stopTest();

        List<Task> checkTasks = new List<Task>([Select id from Task]);
        System.assertEquals(0, checkTasks.size(),'Failed and Platform Events Not Created Successfully');

    }

    public static void testDebitEventNegative(){
        Test.startTest();
        String invoiceCreditDebitWrapperJSON = '{"id":"1234","lineDescription":"test","invoiceId":"INV-01",';
        invoiceCreditDebitWrapperJSON += '"discount":100,"discountAmount":100,"currencyIsoCode":"USD",';
        invoiceCreditDebitWrapperJSON += '"quantity":10,"totalAmount":100,"productUUID":"Test","UOM":"Test",';
        invoiceCreditDebitWrapperJSON += '"contractLineId":"1234","taxable":true,"taxCode":"Test","taxRate":10,';
        invoiceCreditDebitWrapperJSON += '"taxType":"Test","creditAmount":"10","debitAmount":"10"}';
        InvoicesCreditsDebitsWrapper invoiceCDWrapper = (InvoicesCreditsDebitsWrapper)JSON.deserialize(invoiceCreditDebitWrapperJSON, InvoicesCreditsDebitsWrapper.class);
        List<InvoicesCreditsDebitsWrapper> invoiceCDWrapperList = new List<InvoicesCreditsDebitsWrapper>();
        invoiceCDWrapperList.add(invoiceCDWrapper);
        List<Invoice_Event__e> invoiceEventList = new List<Invoice_Event__e>();
        Invoice_Event__e invoiceEvent = new Invoice_Event__e(Invoice_ID__c = 'TestInvoiceID', Payment_Terms__c = 'Terms', Currency__c = 'CAD', Sold_to_Customer__c = 'Customer');
        invoiceEventList.add(invoiceEvent);
        List<PlatformEventsWorkday.Request> requests = new List<PlatformEventsWorkday.Request>();
        PlatformEventsWorkday.Request platformWorkday = new PlatformEventsWorkday.Request();
        platformWorkday = new PlatformEventsWorkday.Request();
        platformWorkday.category = 'Debit';
        platformWorkday.invoiceCreditDebitLines = invoiceCDWrapperList;
        platformWorkday.creditDebitEvents = invoiceEventList;
        requests.add(platformWorkday);
        PlatformEventsWorkday.publishWorkdayEvent(requests);
        Test.stopTest();

        List<Task> checkTasks = new List<Task>([Select id from Task]);
        System.assertEquals(1, checkTasks.size(),'Platform Events Created Successfully');

    }

    @isTest
    public static void testOrderPositive(){
        Test.startTest();
        List<OrderLineWrapper> orderLines = new List<OrderLineWrapper>();
        String orderLJSON = '{"orderId":"1234","onHold":false,"salesItem":"test","lineType":"test",';
        orderLJSON += '"lineItemDescription":"test","quantity":10,"unitPrice":10,"revenueTreatement":"test",';
        orderLJSON += '"costCenter":"test","region":"test","location":"test","businessUnit":"test",';
        orderLJSON += '"amendmentType":"test","contractStatus":"test"}';
        OrderLineWrapper orderLineW = (OrderLineWrapper)JSON.deserialize(orderLJSON, OrderLineWrapper.class);
        orderLines.add(orderLineW);
        
        List<PlatformEventsWorkday.Request> requests = new List<PlatformEventsWorkday.Request>();
        PlatformEventsWorkday.Request platformWorkday = new PlatformEventsWorkday.Request();
        platformWorkday.category = 'Order';
        platformWorkday.orderLines = orderLines;
        platformWorkday.orderEvent = new Order_Contract__e(Currency__c = 'CAD');
        requests.add(platformWorkday);
        PlatformEventsWorkday.publishWorkdayEvent(requests);
        Test.stopTest();
        List<Task> checkTasksOrder = new List<Task>([Select id from Task]);
        System.assertEquals(0, checkTasksOrder.size(),'Failed and Platform Events Not Created Successfully');
        
    }
   
    @isTest
    public static void testOrderNegative(){
        Test.startTest();
        List<OrderLineWrapper> orderLines = new List<OrderLineWrapper>();
        String orderLJSON = '{"orderId":"1234","onHold":false,"salesItem":"test","lineType":"test",';
        orderLJSON += '"lineItemDescription":"test","quantity":10,"unitPrice":10,"revenueTreatement":"test",';
        orderLJSON += '"costCenter":"test","region":"test","location":"test","businessUnit":"test",';
        orderLJSON += '"amendmentType":"test","contractStatus":"test"}';
        OrderLineWrapper orderLineW = (OrderLineWrapper)JSON.deserialize(orderLJSON, OrderLineWrapper.class);
        orderLines.add(orderLineW);
        
        List<PlatformEventsWorkday.Request> requests = new List<PlatformEventsWorkday.Request>();
        PlatformEventsWorkday.Request platformWorkday = new PlatformEventsWorkday.Request();
        platformWorkday.category = 'Order';
        platformWorkday.orderLines = orderLines;
        platformWorkday.orderEvent = new Order_Contract__e();
        requests.add(platformWorkday);
        PlatformEventsWorkday.publishWorkdayEvent(requests);
        Test.stopTest();
        List<Task> checkTasksOrder = new List<Task>([Select id from Task]);
        System.assertEquals(1, checkTasksOrder.size(),'Platform Events Created Successfully');
        
    }
}