public with sharing class ReservationInitialTerms {
    @InvocableVariable 
    @AuraEnabled public String calendarUnit;

    @InvocableVariable 
    @AuraEnabled public Integer count;

    @InvocableVariable 
    @AuraEnabled public String moveInDate;

    @InvocableVariable 
    @AuraEnabled public String locationUUID;
}