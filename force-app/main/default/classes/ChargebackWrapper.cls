public with sharing class ChargebackWrapper {
    @InvocableVariable 
    @AuraEnabled public String originalUUID;
    
    @InvocableVariable
    @AuraEnabled public String originalMerchantTransactionId;

    @InvocableVariable 
    @AuraEnabled public String chargebackUUID;
    
    @InvocableVariable
    @AuraEnabled public Decimal amount;

    @InvocableVariable 
    @AuraEnabled public String currencyCode;
    
    @InvocableVariable
    @AuraEnabled public String reason;

    @InvocableVariable
    @AuraEnabled public Datetime reversalDateTime;

    @InvocableVariable
    @AuraEnabled public Datetime chargebackDateTime;

}