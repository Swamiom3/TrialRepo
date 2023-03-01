global class PaymentLineWrapper {
    
    @InvocableVariable
    @AuraEnabled global String remittanceType;

    @InvocableVariable
    @AuraEnabled global String details;

    @InvocableVariable
    @AuraEnabled global String paymentId;

    @InvocableVariable
    @AuraEnabled global Decimal amountToPay;

    @InvocableVariable
    @AuraEnabled global String invoiceCurrency;

    @InvocableVariable
    @AuraEnabled global String billToCustomer;
    
}