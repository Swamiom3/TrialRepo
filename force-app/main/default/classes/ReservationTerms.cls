public with sharing class ReservationTerms {
    @InvocableVariable 
    @AuraEnabled public String calendarUnits;

    @InvocableVariable 
    @AuraEnabled public String locationUUID;

    @InvocableVariable 
    @AuraEnabled public String startedOn;

    @InvocableVariable 
    @AuraEnabled public Integer count;
}