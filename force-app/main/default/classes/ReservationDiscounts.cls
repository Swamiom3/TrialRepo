public with sharing class ReservationDiscounts {
    @InvocableVariable 
    @AuraEnabled public String startDate;

    @InvocableVariable 
    @AuraEnabled public String endDate;

    @InvocableVariable 
    @AuraEnabled public String discountUUID;

    @InvocableVariable 
    @AuraEnabled public String promotionCode;

    @InvocableVariable 
    @AuraEnabled public String locationUUID;

    @InvocableVariable 
    @AuraEnabled public String reservableUUID;

    @InvocableVariable 
    @AuraEnabled public Date changeDate;

    @InvocableVariable 
    @AuraEnabled public String reservationUUID;

    @InvocableVariable 
    @AuraEnabled public Decimal amount;
}