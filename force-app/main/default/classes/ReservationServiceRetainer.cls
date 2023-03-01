public with sharing class ReservationServiceRetainer {
    @InvocableVariable 
    @AuraEnabled public String isManualFinalizeSR;

    @InvocableVariable 
    @AuraEnabled public String manualFinalizeSRReason;
}