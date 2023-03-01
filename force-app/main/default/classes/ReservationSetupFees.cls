public with sharing class ReservationSetupFees {
    @InvocableVariable 
    @AuraEnabled public String startedOn;

    @InvocableVariable 
    @AuraEnabled public String locationUUID;

    @InvocableVariable 
    @AuraEnabled public String amount;
}