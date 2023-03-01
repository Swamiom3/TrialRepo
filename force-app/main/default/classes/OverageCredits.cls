public with sharing class OverageCredits{
    @InvocableVariable 
    @AuraEnabled public Double price;
    
    @InvocableVariable 
    @AuraEnabled public String id;

    @InvocableVariable
    @AuraEnabled public Double quantity;

    @InvocableVariable
    @AuraEnabled public Date startedOn;

    @InvocableVariable
    @AuraEnabled public Date endedOn;
    
    @InvocableVariable
    @AuraEnabled public String reservableUUID;
    
    @InvocableVariable
    @AuraEnabled public String paymentType;
    
    @InvocableVariable
    @AuraEnabled public String accountUUID;
    
    @InvocableVariable
    @AuraEnabled public String locationUUID;
    
    @InvocableVariable
    @AuraEnabled public String currencyCode;
    
}