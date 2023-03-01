/*************************************************************************************************************************************
    Author      :   Oleg Krasko
    Description :   This class is selector implementation of particular SObject (sbaa__ApprovalRule__c)
    --------------------------------------------------------------------------------------------------------------------------------------
    VERSION         DATE            AUTHOR              DETAIL
    1               17 Mar, 2022    Oleg Krasko      Initial Deployment
**************************************************************************************************************************************/
public with sharing class ApprovalRuleSelector extends SObjectSelector{
    public ApprovalRuleSelector() {
        super(sbaa__ApprovalRule__c.getSObjectType());
    }

    public override Set<String> getDefaultFields() {
        return new Set<String> { 'Id', 'Name' };
    }

    public List<sbaa__ApprovalRule__c> getApprovalRulesByIds(List<Id> approvalRuleIds){
        if (approvalRuleIds?.isEmpty() != false) {
            return new List<sbaa__ApprovalRule__c>();
        }

        List<String> fields = new List<String>{'Original_Conditions_Met__c', 'sbaa__ConditionsMet__c'};
        return (List<sbaa__ApprovalRule__c>) getSObjectByIds(fields, approvalRuleIds);
    }
}