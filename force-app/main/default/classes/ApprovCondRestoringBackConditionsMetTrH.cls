/************************************************************************************************************************************
    Author         : Oleg Krasko
    Description    : This class provides the logic to restore back original Conditions Met value on parent Approval Rule
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION        DATE            AUTHOR             DETAIL
    1              16 Mar, 2022    Oleg Krasko        Initial Deployment
**************************************************************************************************************************************/
public with sharing class ApprovCondRestoringBackConditionsMetTrH extends SObjectTriggerHandler{
    private List<sbaa__ApprovalCondition__c> newApprovalConditions;
    @TestVisible
    private final String CIRCLE_CI_PERMISSION_SET_NAME = 'CircleCi';
    private ApprovalRuleSelector approvalRuleSelector;

    @TestVisible
    private ApprovCondRestoringBackConditionsMetTrH(List<sbaa__ApprovalCondition__c> newApprovalConditions){
        this.newApprovalConditions = newApprovalConditions;
    }

    public ApprovCondRestoringBackConditionsMetTrH(){
        this(Trigger.new);
    }

    public override void afterInsert(){
        if (isCircleCIUser()) {
            restoreBackConditionsMet();
        }
    }

    private void restoreBackConditionsMet(){
        Set<Id> approvalRuleIds = collectApprovalRuleIds();
        if (approvalRuleIds.isEmpty()) {
            return;
        }
        List<sbaa__ApprovalRule__c> approvalRulesToUpdate = new List<sbaa__ApprovalRule__c>();
        for (sbaa__ApprovalRule__c approvalRule : getApprovalRules(approvalRuleIds)) {
            if (String.isBlank(approvalRule.Original_Conditions_Met__c)
                || approvalRule.sbaa__ConditionsMet__c == approvalRule.Original_Conditions_Met__c) {
                continue;
            }
            approvalRulesToUpdate.add(new sbaa__ApprovalRule__c(
                Id = approvalRule.Id,
                sbaa__ConditionsMet__c = approvalRule.Original_Conditions_Met__c
            ));
        }
        if (!approvalRulesToUpdate.isEmpty()) {
            update approvalRulesToUpdate;
        }
    }

    private Set<Id> collectApprovalRuleIds(){
        Set<Id> approvalRuleIds = new Set<Id>();
        for (sbaa__ApprovalCondition__c approvalCondition : newApprovalConditions) {
            approvalRuleIds.add(approvalCondition.sbaa__ApprovalRule__c);
        }
        return approvalRuleIds;
    }

    private List<sbaa__ApprovalRule__c> getApprovalRules(Set<Id> approvalRuleIds){
        approvalRuleSelector = new ApprovalRuleSelector();
        return approvalRuleSelector.getApprovalRulesByIds(new List<Id>(approvalRuleIds));
    }

    private Boolean isCircleCIUser(){
        return ![SELECT Id 
                FROM PermissionSetAssignment 
                WHERE AssigneeId = :UserInfo.getUserId()
                AND PermissionSet.Name = :CIRCLE_CI_PERMISSION_SET_NAME]
                .isEmpty();
    }
}