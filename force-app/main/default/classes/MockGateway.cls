global class MockGateway implements blng.PaymentGateWay, blng.PaymentGateWays, blng.PaymentGateWayStatus  {

    private static final String SUCCESS = 'SUCCESS';
    private static final String DECLINE = 'DECLINE';
    private static final String SUCCESSRESPONSECODE = '100';
    private static final String FAILURERESPONSECODE = '200';
    private static final String SUCCESSRESPONSECODEMESSAGE = 'Payment Sent for Processing';
    private static final String FAILURERESPONSECODEMESSAGE = 'Transaction failed';
    private static final String GENERATETOKEN = 'GenerateToken';
    private static final String CHARGETRANSACTION = 'ChargeTransaction';
    private static final String REFUND = 'Refund';
    Map<String, blng.TransactionParameter> mapOfTransactionParameterById = new Map<String, blng.TransactionParameter>();

    private static MockGateway mockGatewayInstance;
    
    private static MockGateway service() {
        if (null == mockGatewayInstance) {
            mockGatewayInstance = new MockGateway();
        }
        return mockGatewayInstance;
    }

    private static String getRandomNumber(integer stringLength){
        final Integer max = integer.valueOf(Math.pow(10,stringLength) - 1);
        return String.valueOf(Math.Round(Math.Random() * max)).leftPad(stringLength,'0');
    }
    
    private static Map<String, blng.TransactionResult> constructResponse(String transactionType,
                Map<String, blng.TransactionParameter> mapOfTransactionParameterById) {
                                                                         
        Map<String, blng.TransactionResult> mapOfTransactionResultById = new Map<String, blng.TransactionResult>();
        for(String idToProcess : mapOfTransactionParameterById.KeySet()) {
            blng.TransactionParameter transactionParameterToProcess = mapOfTransactionParameterById.get(idToProcess);            
            constructSuccessResponse(transactionType, transactionParameterToProcess);
            mapOfTransactionResultById.put(idToProcess, transactionParameterToProcess.transactionResult);
        }
        return mapOfTransactionResultById;
    }
    
    private static void constructSuccessResponse(String transactionType,
                                                 blng.TransactionParameter transactionParameterToProcess) {
        
        transactionParameterToProcess.transactionResult.setResponseToValidate(SUCCESS);
        transactionParameterToProcess.transactionResult.setIsSuccess(true);
        transactionParameterToProcess.transactionResult.setResponseMessage(SUCCESS);
        transactionParameterToProcess.transactionResult.setResponseCode(SUCCESSRESPONSECODE);
        transactionParameterToProcess.transactionResult.setResponseCodeMessage(SUCCESSRESPONSECODEMESSAGE);
                                      
        String randomNumber = getRandomNumber(8) + getRandomNumber(8);                                                     
        if (GENERATETOKEN == transactionType) {
            transactionParameterToProcess.transactionResult.setPaymentToken(randomNumber);
        } else {
            transactionParameterToProcess.transactionResult.setGatewayId(randomNumber);
        }
        
        transactionParameterToProcess.transactionResult.setGatewayStatus(blng.TransactionResult.GatewayStatusType.RequiresReview);
    }

    
    global static Map<String, blng.TransactionResult> generateToken(Map<String,
                                                                    blng.TransactionParameter> mapOfTransactionParameterById) {
        return constructResponse(GENERATETOKEN, mapOfTransactionParameterById);
    }
     
    global static Map<String, blng.TransactionResult> chargeTransaction(Map<String,
                                                                        blng.TransactionParameter> mapOfTransactionParameterById) {
        return constructResponse(CHARGETRANSACTION, mapOfTransactionParameterById);
    }

    global static Map<String, blng.TransactionResult> refundTransaction(Map<String,
                                                                         blng.TransactionParameter> mapOfTransactionParameterById) {
        return null;
    }
    
    global static Map<String, blng.TransactionResult> authorizeTransaction(Map<String,
                                                                           blng.TransactionParameter> mapOfTransactionParameterById) {
        return null;
    }
    
    global static Map<String, blng.TransactionResult> voidTransaction(Map<String,
                                                                      blng.TransactionParameter> mapOfTransactionParameterById) {
        return null;
    }
    
    global static Map<String, blng.TransactionResult> processPayments(Map<String, blng.TransactionParameter> mapOfTransactionParameterById,
                                                                      blng.PaymentGatewayParameter paymentGatewayParameter) {
        return null;
    }

    global static void populateGatewayStatus(blng.TransactionResult transactionResult) {
        String gateWayStatus; 
    }  

}