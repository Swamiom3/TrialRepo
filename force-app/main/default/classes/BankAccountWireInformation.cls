@SuppressWarnings('PMD')
global with sharing class BankAccountWireInformation{

    @AuraEnabled
    global String action;
    
    @AuraEnabled
    global String dataType;
    
    @AuraEnabled
    global String thirdPartyCode;
    
    @AuraEnabled
    global String beneficiaryName1;
    
    @AuraEnabled
    global String beneficiaryName2;
    
    @AuraEnabled
    global String creditor;
    
    @AuraEnabled
    global String debitor;

    @AuraEnabled
    global String corpIdCode;

    @AuraEnabled
    global Integer otherIdType;

    @AuraEnabled
    global String beneficiaryAddress1;

    @AuraEnabled
    global String beneficiaryAddress2;

    @AuraEnabled
    global String beneficiaryCity;

    @AuraEnabled
    global String beneficiaryPostalCode;

    @AuraEnabled
    global String beneficiaryProvince;

    @AuraEnabled
    global String beneficiaryCountry;

    @AuraEnabled
    global String bankStreet;

    @AuraEnabled
    global String bankStreet2;

    @AuraEnabled
    global String bankCity;

    @AuraEnabled
    global String bankPostal;

    @AuraEnabled
    global String bankName;

    @AuraEnabled
    global String bankCountry;
    @AuraEnabled
    global String bicCode;

    @AuraEnabled
    global String bankOtherTypeId;

    @AuraEnabled
    global String bkOtherId;

    @AuraEnabled
    global String accountCurrency;

    @AuraEnabled
    global String accountIdType;

    @AuraEnabled
    global String accountId;

    @AuraEnabled
    global String accountNumber;

    @AuraEnabled
    global String defaultAccount;

    @AuraEnabled
    global String oneTimeCorrespondent;

    @AuraEnabled
    global String correspondentBic;

    @AuraEnabled
    global String correspondentCountryCode;

    @AuraEnabled
    global String thirdPartyHideInList;

    @AuraEnabled
    global String accountHideInList;

    @AuraEnabled
    global String accountClosureDate;

    @AuraEnabled
    global String accountOwnerName;

    @AuraEnabled
    global String sortCode;

    @AuraEnabled
    global String iban; 
}