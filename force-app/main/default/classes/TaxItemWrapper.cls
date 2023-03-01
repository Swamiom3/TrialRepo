global class TaxItemWrapper {
    @InvocableVariable
    @AuraEnabled global String id;
    
    @InvocableVariable
    @AuraEnabled global String adminZoneLevel;
    
    @InvocableVariable
    @AuraEnabled global String authorityName;
    
    @InvocableVariable
    @AuraEnabled global String authorityUUID;

    @InvocableVariable
    @AuraEnabled global String authorityType;
    
    @InvocableVariable
    @AuraEnabled global String currencyIsoCode;
    
    @InvocableVariable
    @AuraEnabled global String erpTaxCode;
    
    @InvocableVariable
    @AuraEnabled global Decimal recoverableRate;

    @InvocableVariable
    @AuraEnabled global Decimal taxAmount;
    
    @InvocableVariable
    @AuraEnabled global Decimal taxRate;
    
    @InvocableVariable
    @AuraEnabled global String taxRateCode;
    
    @InvocableVariable
    @AuraEnabled global String taxType;
    
    @InvocableVariable
    @AuraEnabled global String taxableCountry;
    
    @InvocableVariable
    @AuraEnabled global Decimal undocumentedTaxAmount;
    
    @InvocableVariable
    @AuraEnabled global String zoneLevel;
    
    @InvocableVariable
    @AuraEnabled global String zoneName;
    
    @InvocableVariable
    @AuraEnabled global String creditNoteLineItemId;
    
    @InvocableVariable
    @AuraEnabled global String debitNoteLineItemId;
    
    @InvocableVariable
    @AuraEnabled global String invoiceLineItemId;
     
}