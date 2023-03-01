@SuppressWarnings('PMD.TooManyFields')
global class InvoicesCreditsDebitsWrapper {
    @InvocableVariable
    @AuraEnabled global String id;
    
    @InvocableVariable
    @AuraEnabled global String lineDescription;
    
    @InvocableVariable
    @AuraEnabled global String invoiceId;
    
    @InvocableVariable
    @AuraEnabled global Decimal discount;
    
    @InvocableVariable
    @AuraEnabled global Decimal discountAmount;
    
    @InvocableVariable
    @AuraEnabled global String currencyIsoCode;
    
    @InvocableVariable
    @AuraEnabled global Decimal quantity;
    
    @InvocableVariable
    @AuraEnabled global Decimal totalAmount;
    
    @InvocableVariable
    @AuraEnabled global String productUUID;
    
    @InvocableVariable
    @AuraEnabled global String uom;
    
    @InvocableVariable
    @AuraEnabled global Date startDate;
    
    @InvocableVariable
    @AuraEnabled global Date endDate;
    
    @InvocableVariable
    @AuraEnabled global String contractLineId;
    
    @InvocableVariable
    @AuraEnabled global Boolean taxable;
    
    @InvocableVariable
    @AuraEnabled global Decimal hstgstTax;

    @InvocableVariable
    @AuraEnabled global Decimal pstrstTax;

    @InvocableVariable
    @AuraEnabled global Decimal qstTax;

    @InvocableVariable
    @AuraEnabled global Decimal cityTax;

    @InvocableVariable
    @AuraEnabled global Decimal countyTax;

    @InvocableVariable
    @AuraEnabled global Decimal stateTax;

    @InvocableVariable
    @AuraEnabled global Decimal districtTax;

    @InvocableVariable
    @AuraEnabled global Decimal exemptAmount;

    @InvocableVariable
    @AuraEnabled global String creditAmount;

    @InvocableVariable
    @AuraEnabled global String debitAmount;

    @InvocableVariable
    @AuraEnabled global List<TaxItemWrapper> taxItems;
    
}