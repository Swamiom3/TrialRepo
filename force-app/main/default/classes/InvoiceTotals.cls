public with sharing class InvoiceTotals {

    @InvocableVariable
    @AuraEnabled public String invoiceType;

    @InvocableVariable
    @AuraEnabled public Double amount;

    @InvocableVariable
    @AuraEnabled public Double paid;

    @InvocableVariable
    @AuraEnabled public Double usdAmount;

    @InvocableVariable
    @AuraEnabled public Double usdPaid;

    @InvocableVariable
    @AuraEnabled public Double taxAmount;
}