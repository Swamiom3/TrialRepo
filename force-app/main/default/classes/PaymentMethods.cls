public with sharing class PaymentMethods{
    @InvocableVariable 
    @AuraEnabled public String paymentMethod;
    
    @InvocableVariable
    @AuraEnabled public String displayData;
    
    @InvocableVariable
    @AuraEnabled public String uuid;
    
    @InvocableVariable
    @AuraEnabled public String paymentType;
    
    @InvocableVariable
    @AuraEnabled public String chargingProfileUuid;
    
    @InvocableVariable
    @AuraEnabled public String typename;
    
    @InvocableVariable
    @AuraEnabled public String gatewayName;

    @InvocableVariable
    @AuraEnabled public String beneficiaryAddressLine1;

    @InvocableVariable
    @AuraEnabled public String beneficiaryAddressLine2;

    @InvocableVariable
    @AuraEnabled public String beneficiaryCity;

    @InvocableVariable
    @AuraEnabled public String beneficiaryCountry;

    @InvocableVariable
    @AuraEnabled public String beneficiaryPostalCode;

    @InvocableVariable
    @AuraEnabled public String beneficiaryStateProvince;

    @InvocableVariable
    @AuraEnabled public String refundMethod;  
}