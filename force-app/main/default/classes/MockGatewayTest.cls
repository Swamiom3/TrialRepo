@isTest
private class MockGatewayTest {
    
    private static final String SUCCESS = 'SUCCESS';
    private static final String DECLINE = 'DECLINE';
    private static final String SUCCESSRESPONSECODE = '100';
    private static final String FAILURERESPONSECODE = '200';
    private static final String SUCCESSRESPONSECODEMESSAGE = 'Payment Sent for Processing';
    private static final String FAILURERESPONSECODEMESSAGE = 'Transaction failed';
    private static final String GENERATETOKEN = 'GenerateToken';
    private static final String CHARGETRANSACTION = 'ChargeTransaction';
    private static final String REFUND = 'Refund';


    @isTest
    static void testGenerateTokenSuccess() {
        Map<String, blng.TransactionParameter> mapOfTransactionParameterById = new Map<String, blng.TransactionParameter>();
        blng.TransactionParameter transactionParameter = new blng.TransactionParameter();
        blng__PaymentMethod__c paymentMethod = new blng__PaymentMethod__c();
        transactionParameter.setPaymentMethod(paymentMethod);
        mapOfTransactionParameterById.put(transactionParameter.toString(), transactionParameter);
        
        Map<String, blng.TransactionResult> result = MockGateway.generateToken(mapOfTransactionParameterById);
        for(String idToProcess : result.KeySet()){
            blng.TransactionResult transactionResult = result.get(idToProcess);
            System.assertEquals(true, transactionResult.getIsSuccess());
            System.assertEquals(blng.TransactionResult.GatewayStatusType.RequiresReview,transactionResult.getGatewayStatus());
            System.assertEquals(SUCCESS, transactionResult.getResponseToValidate());
            System.assert(NULL != transactionResult.getPaymentToken());
        }
    }
    
    @isTest
    static void testChargeTransactionCCSuccess() {
        Map<String, blng.TransactionParameter> mapOfTransactionParameterById = new Map<String, blng.TransactionParameter>();
        blng.TransactionParameter transactionParameter = new blng.TransactionParameter();
        blng__PaymentMethod__c paymentMethod = new blng__PaymentMethod__c();
        paymentMethod.blng__PaymentType__c = 'Credit Card';
        paymentMethod.blng__CardNumber__c = '4111111111111111';
        transactionParameter.setPaymentMethod(paymentMethod);
        transactionParameter.setAmount('100');
        mapOfTransactionParameterById.put(transactionParameter.toString(), transactionParameter);
        
        Map<String, blng.TransactionResult> result = MockGateway.chargeTransaction(mapOfTransactionParameterById);
        for(String idToProcess : result.KeySet()) {
            blng.TransactionResult transactionResult = result.get(idToProcess);
            System.assertEquals(true, transactionResult.getIsSuccess(),'Transaction Failed');
            System.assertEquals(blng.TransactionResult.GatewayStatusType.RequiresReview,transactionResult.getGatewayStatus(),'Transaction Failed');
            System.assertEquals(SUCCESS, transactionResult.getResponseToValidate());
            System.assert(NULL != transactionResult.getGatewayId(),'Transaction Gateway Failed'); 
        }
    }

    @isTest
    static void testChargeTransactionACHSuccess() {
        Map<String, blng.TransactionParameter> mapOfTransactionParameterById = new Map<String, blng.TransactionParameter>();
        blng.TransactionParameter transactionParameter = new blng.TransactionParameter();
        blng__PaymentMethod__c paymentMethod = new blng__PaymentMethod__c();
        paymentMethod.blng__PaymentType__c = 'ACH';
        paymentMethod.blng__BankAccountNumber__c = '1111';
        transactionParameter.setPaymentMethod(paymentMethod);
        transactionParameter.setAmount('100');
        mapOfTransactionParameterById.put(transactionParameter.toString(), transactionParameter);
        
        Map<String, blng.TransactionResult> result = MockGateway.chargeTransaction(mapOfTransactionParameterById);
        for(String idToProcess : result.KeySet()) {
            blng.TransactionResult transactionResult = result.get(idToProcess);
            System.assertEquals(true, transactionResult.getIsSuccess(), 'Transaction Failed');
            System.assertEquals(blng.TransactionResult.GatewayStatusType.RequiresReview,transactionResult.getGatewayStatus(),'Transaction Failed');
            System.assertEquals(SUCCESS, transactionResult.getResponseToValidate(),'Transaction Failed');
            System.assert(NULL != transactionResult.getGatewayId(),'Transaction Gateway Failed'); 
        }
    }
    
    @isTest
    static void testProcessPayments(){
        Map<String, blng.TransactionParameter> mapOfTransactionParameterById = new Map<String, blng.TransactionParameter>();
        blng.PaymentGatewayParameter paymentGatewayParameter = new blng.PaymentGatewayParameter();
        Map<String, blng.TransactionResult> result = MockGateway.processPayments(mapOfTransactionParameterById,paymentGatewayParameter);
        System.assertEquals(null, null, 'Payment Processor Ran');
    }
    
    @isTest
    static void testvoidTransaction(){
        Map<String, blng.TransactionParameter> mapOfTransactionParameterById = new Map<String, blng.TransactionParameter>();
        Map<String, blng.TransactionResult> result = MockGateway.voidTransaction(mapOfTransactionParameterById);
        System.assertEquals(null, null, 'Void Transaction Processor Ran');
    }
    
    @isTest
    static void testAuthorizeTransaction(){
        Map<String, blng.TransactionParameter> mapOfTransactionParameterById = new Map<String, blng.TransactionParameter>();
        Map<String, blng.TransactionResult> result = MockGateway.authorizeTransaction(mapOfTransactionParameterById);
        System.assertEquals(null, null, 'Void Authorize Transaction Processor Ran');
    }
    
    @isTest
    static void testRefundTransaction(){
        Map<String, blng.TransactionParameter> mapOfTransactionParameterById = new Map<String, blng.TransactionParameter>();
        Map<String, blng.TransactionResult> result = MockGateway.refundTransaction(mapOfTransactionParameterById);
        System.assertEquals(null, null, 'Refund Transaction Processor Ran');
    }
}