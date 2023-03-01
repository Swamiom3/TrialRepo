@isTest
private with sharing class ApprovalRuleSelectorTest {
    static ApprovalRuleSelector approvalRuleSelector = new ApprovalRuleSelector();
    @isTest
    static void test_positive(){
        sbaa__ApprovalRule__c approvalRule = new sbaa__ApprovalRule__c(
            sbaa__TargetObject__c = 'Opportunity', 
            Name = 'Test Approval Rule Name'
        );
        insert approvalRule;

        Test.startTest();
        List<sbaa__ApprovalRule__c> approvalRules = approvalRuleSelector.getApprovalRulesByIds(new List<Id>{approvalRule.Id});
        Test.stopTest();

        System.assert(!approvalRules.isEmpty(), 'ApprovalRules list should be populated by selector');
    }

    @isTest
    static void test_negative(){
        Test.startTest();
        List<sbaa__ApprovalRule__c> approvalRulesEmpty = approvalRuleSelector.getApprovalRulesByIds(new List<Id>());
        List<sbaa__ApprovalRule__c> approvalRulesNull = approvalRuleSelector.getApprovalRulesByIds(null);
        Test.stopTest();

        System.assert(approvalRulesEmpty.isEmpty(), 'ApprovalRules list should be empty');
        System.assert(approvalRulesNull.isEmpty(), 'ApprovalRules list should be empty');
    }
}