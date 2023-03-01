//Suppressing TooManyFields as it's wrapped for flows
@SuppressWarnings('PMD.TooManyFields')
global class OrderLineWrapper {
    @InvocableVariable
    @AuraEnabled global String orderId;

    @InvocableVariable
    @AuraEnabled global Boolean onHold;

    @InvocableVariable
    @AuraEnabled global String salesItem;

    @InvocableVariable
    @AuraEnabled global String lineType;

    @InvocableVariable
    @AuraEnabled global String lineItemDescription;

    @InvocableVariable
    @AuraEnabled global Decimal quantity;

    @InvocableVariable
    @AuraEnabled global Decimal unitPrice;

    @InvocableVariable
    @AuraEnabled global String revenueTreatement;

    @InvocableVariable
    @AuraEnabled global Date fromDate;

    @InvocableVariable
    @AuraEnabled global Date toDate;

    @InvocableVariable
    @AuraEnabled global String costCenter;

    @InvocableVariable
    @AuraEnabled global String region;

    @InvocableVariable
    @AuraEnabled global String location;

    @InvocableVariable
    @AuraEnabled global String businessUnit;

    @InvocableVariable
    @AuraEnabled global String amendmentType;

    @InvocableVariable
    @AuraEnabled global Date amendmentEffectiveDate;

    @InvocableVariable
    @AuraEnabled global Date amendmentSignedDate;

    @InvocableVariable
    @AuraEnabled global String contractStatus;

    @InvocableVariable
    @AuraEnabled global String taxCode;
    
    @InvocableVariable
    @AuraEnabled global Decimal taxRate;
    
    @InvocableVariable
    @AuraEnabled global String taxAuthority;

    @InvocableVariable
    @AuraEnabled global Boolean taxable;

    @InvocableVariable
    @AuraEnabled global Decimal exemptAmount;

    @InvocableVariable
    @AuraEnabled global Decimal taxAmount;

}