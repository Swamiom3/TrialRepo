public with sharing class SpacemanReservations {

    @InvocableVariable 
    @AuraEnabled public List<Reservations> reservations;

    @InvocableVariable 
    @AuraEnabled public List<ReservationAddOns> addOns;
    
    @InvocableVariable 
    @AuraEnabled public List<ReservationSetupFees> setupFees;

    @InvocableVariable 
    @AuraEnabled public List<ReservationServiceRetainer> serviceRetainerInfo;

    @InvocableVariable 
    @AuraEnabled public List<ReservationTerms> terms;

    @InvocableVariable 
    @AuraEnabled public List<ReservationDiscounts> discounts;

    @InvocableVariable 
    @AuraEnabled public List<ReservationCredits> credits;

    @InvocableVariable 
    @AuraEnabled public String locationUUID;

    @InvocableVariable 
    @AuraEnabled public String accountUUID;

    @InvocableVariable 
    @AuraEnabled public String accountAdminUUID;

    @InvocableVariable 
    @AuraEnabled public String signedPDFURL;

    @InvocableVariable 
    @AuraEnabled public Decimal earlyTerminationPenalty;

    @InvocableVariable 
    @AuraEnabled public String sfOrderId;

}