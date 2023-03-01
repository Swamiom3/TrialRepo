public with sharing class ReservationAddOns {

    @InvocableVariable 
    @AuraEnabled public String locationUUID;

    @InvocableVariable 
    @AuraEnabled public String startedOn;

    @InvocableVariable 
    @AuraEnabled public Decimal amount;

    @InvocableVariable 
    @AuraEnabled public String quantity;

    @InvocableVariable 
    @AuraEnabled public String resourceUUID;

    @InvocableVariable 
    @AuraEnabled public String endedOn;

    @InvocableVariable 
    @AuraEnabled public String productUUID;
}