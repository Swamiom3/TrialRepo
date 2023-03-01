public with sharing class OverageParameters {
    @InvocableVariable 
    @AuraEnabled public String accountUUID;
    
    @InvocableVariable
    @AuraEnabled public String locationUUID;
}