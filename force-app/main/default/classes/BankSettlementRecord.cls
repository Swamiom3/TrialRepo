global with sharing class BankSettlementRecord{
    @AuraEnabled
    global String weWorkAccountNumber;
    
    @AuraEnabled
    global String vendor;
    
    @AuraEnabled
    global String payToBankAccountNumber;
    
    @AuraEnabled
    global String paymentType;
    
    @AuraEnabled
    global String budgetCode;
    
    @AuraEnabled
    global String currencyCode;
    
    @AuraEnabled
    global Decimal amount;

    @AuraEnabled
    global String vendorCountry;

    @AuraEnabled
    global String eftCheckMemo;

    @AuraEnabled
    global String reason1;

    @AuraEnabled
    global String reason2;

    @AuraEnabled
    global String reason3;

    @AuraEnabled
    global String reason4;

    @AuraEnabled
    global String freeText1;

    @AuraEnabled
    global String freeText2;

    @AuraEnabled
    global String freeText3;

    @AuraEnabled
    global String debitCreditReportingFlag;

}