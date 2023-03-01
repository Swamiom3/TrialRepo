public with sharing class ReservationCredits {
    @InvocableVariable 
    @AuraEnabled public String reservationUUID;

    @InvocableVariable 
    @AuraEnabled public Decimal amount;

    @InvocableVariable 
    @AuraEnabled public String allotmentType;

    @InvocableVariable 
    @AuraEnabled public String startDate;

    @InvocableVariable 
    @AuraEnabled public String endDate;
}