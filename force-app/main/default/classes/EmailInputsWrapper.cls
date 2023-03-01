/************************************************************************************************************************************
Author      :   Salesforce
Description :   Apex wrapper class for flow consumption to send bulk emails, via FlowUtilities apex class
----------------------------------------------------------------------------------------------------------------------------------
    VERSION      DATE         AUTHOR              DETAIL
    1            04/05/2022   Salesforce          Initial creation
**************************************************************************************************************************************/
public class EmailInputsWrapper {
    @InvocableVariable
    @AuraEnabled public String templateId;
    @InvocableVariable
    @AuraEnabled public String toAddress;
    @InvocableVariable
    @AuraEnabled public String fromAddress;
    @InvocableVariable
    @AuraEnabled public String targetObjectId;
    @InvocableVariable
    @AuraEnabled public String targetWhatId;    
}