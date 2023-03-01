/*************************************************************************************************************************************
    Author      :   Oleg Krasko
    Description :   This class covers ApprovCondRestoringBackConditionsMetTrH
    --------------------------------------------------------------------------------------------------------------------------------------
    VERSION    DATE           AUTHOR             DETAIL
    1          16 Mar, 2022   Oleg Krasko        Initial Deployment
**************************************************************************************************************************************/
@isTest
private class ApprovCondRestoringBackCondMetTrHTest {
    @isTest
    static void test_positive(){
        List<sbaa__ApprovalCondition__c> approvalConditions = prepareData('Custom');
        User userToTest = UtilUser.createUser(
            [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id,
            true
        );
        assignCircleCiPermSet(userToTest);

        Test.startTest();
        System.runAs(userToTest){
            insert approvalConditions;
        }
        Test.stopTest();
        
        System.assertEquals(
            'Custom', [SELECT sbaa__ConditionsMet__c FROM sbaa__ApprovalRule__c].sbaa__ConditionsMet__c, 
            'sbaa__ConditionsMet__c should equal "Custom"'
        );
    }

    @isTest
    static void test_negative(){
        List<sbaa__ApprovalCondition__c> approvalConditions = prepareData('All');
        List<sbaa__ApprovalCondition__c> approvalConditionsCustom = prepareData('Custom');
        User userToTest = UtilUser.createUser(
            [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id,
            true
        );

        Test.startTest();
        System.runAs(userToTest){
            insert approvalConditionsCustom;
            assignCircleCiPermSet(userToTest);
            insert approvalConditions;
        }
        Test.stopTest();

        for (sbaa__ApprovalRule__c approvRule : [SELECT sbaa__ConditionsMet__c FROM sbaa__ApprovalRule__c]) {
            System.assertEquals(
                'All', approvRule.sbaa__ConditionsMet__c, 
                'sbaa__ConditionsMet__c should equal "All"'
            );
        }
    }

    static List<sbaa__ApprovalCondition__c> prepareData(String conditionsMet){
        sbaa__ApprovalRule__c approvalRule = new sbaa__ApprovalRule__c(
            Name = 'test approval rule name',
            sbaa__ConditionsMet__c = conditionsMet,
            sbaa__AdvancedCondition__c = '1 and 2',
            sbaa__TargetObject__c = 'Opportunity'
        );
        insert approvalRule;

        System.assertEquals(
            'All', [SELECT sbaa__ConditionsMet__c FROM sbaa__ApprovalRule__c WHERE Id = :approvalRule.Id].sbaa__ConditionsMet__c, 
            'sbaa__ConditionsMet__c should equal "All"'
        );

         return new List<sbaa__ApprovalCondition__c>{
            new sbaa__ApprovalCondition__c(
                sbaa__TestedField__c = 'blng__TotalAmount__c',
                sbaa__Operator__c = 'less or equals',
                sbaa__FilterValue__c = '1000',
                sbaa__Index__c = 1,
                sbaa__ApprovalRule__c = approvalRule.Id
            ),
            new sbaa__ApprovalCondition__c(
                sbaa__TestedField__c = 'blng__DebitNoteSourceAction__c',
                sbaa__Operator__c = 'equals',
                sbaa__FilterValue__c = 'Manual',
                sbaa__Index__c = 2,
                sbaa__ApprovalRule__c = approvalRule.Id
            )
        };
    }

    static void assignCircleCiPermSet(User inputUser){
        User runAsUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs(runAsUser){
            insert new PermissionSetAssignment(
                AssigneeId = inputUser.Id,
                PermissionSetId = [SELECT Id 
                                    FROM PermissionSet 
                                    WHERE Name = :new ApprovCondRestoringBackConditionsMetTrH().CIRCLE_CI_PERMISSION_SET_NAME].Id
            );
        }
    }
}