public with sharing class Reservations {

    @InvocableVariable 
    @AuraEnabled public String action;

    @InvocableVariable 
    @AuraEnabled public String changeType;

    @InvocableVariable 
    @AuraEnabled public String changeDate;

    @InvocableVariable 
    @AuraEnabled public Integer terms;

    @InvocableVariable 
    @AuraEnabled public Integer capacity;

    @InvocableVariable 
    @AuraEnabled public Boolean committed;

    @InvocableVariable 
    @AuraEnabled public String locationUUID;

    @InvocableVariable 
    @AuraEnabled public Decimal marketPrice;

    @InvocableVariable 
    @AuraEnabled public Decimal price;

    @InvocableVariable 
    @AuraEnabled public String moveInDate;

    @InvocableVariable 
    @AuraEnabled public String moveOutDate;

    @InvocableVariable 
    @AuraEnabled public String reservableUUID;

    @InvocableVariable 
    @AuraEnabled public String reservableNumber;

    @InvocableVariable 
    @AuraEnabled public String reservableType;

    @InvocableVariable 
    @AuraEnabled public String modificationTypes;

    @InvocableVariable 
    @AuraEnabled public String discountReason;

    @InvocableVariable 
    @AuraEnabled public String reservationUUID;

    @InvocableVariable 
    @AuraEnabled public List<ReservationInitialTerms> initialterms;
}