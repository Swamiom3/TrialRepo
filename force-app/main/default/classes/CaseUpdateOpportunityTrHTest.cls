@isTest
public class CaseUpdateOpportunityTrHTest {
    @TestSetup
    static void initData() {
        User adminUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];
        List<Account> accounts = UtilAccount.GetNewAccounts(2, true);
        List<Opportunity> opportunities = new List<Opportunity>();
        opportunities.addAll(UtilOpportunity.GetNewOpportunity(1, accounts[0], false));
        opportunities.addAll(UtilOpportunity.GetNewOpportunity(1, accounts[1], false)); 
        TestingUtility.insertListWithAssert(opportunities);
        Id reaCaseRecordTypeId = (Id) WeworkEngine.getObjectRecordTypeId('Case', 'REA');
        List<Case> cases = new List<Case>();
        cases.add(UtilCase.createCaseRelatedToOpp(opportunities[0].Id, adminUser.Id, reaCaseRecordTypeId, false));
        cases.add(UtilCase.createCaseRelatedToOpp(opportunities[1].Id, adminUser.Id, reaCaseRecordTypeId, false));
        cases[0].Actual_Guardrail_Margin__c = 5.2;
        cases[1].Actual_Guardrail_Margin__c = 45.2;

        Test.startTest();
        TestingUtility.insertListWithAssert(cases);
        Test.stopTest();   
    }
    
    @isTest
    private static void verifyUpdateOppFeildOnCaseClosedWon() {
        List<Case> cases = [SELECT Id, Status, Actual_Guardrail_Margin__c FROM Case LIMIT 2];
        List<Opportunity> opportunities = [SELECT Id, Actual_Deal_Margin__c FROM Opportunity LIMIT 2];
        System.assertEquals(null, opportunities[0].Actual_Deal_Margin__c);
        System.assertEquals(null, opportunities[1].Actual_Deal_Margin__c);
        cases[0].Status = 'Closed Won';
        cases[1].Status = 'Closed Lost';

        Test.startTest();
        TestingUtility.updateListWithAssert(cases);
        Test.stopTest();

        List<Opportunity> opportunitiesAfter = [SELECT Id, Actual_Deal_Margin__c FROM Opportunity LIMIT 2];
        System.assertEquals(cases[0].Actual_Guardrail_Margin__c, opportunitiesAfter[0].Actual_Deal_Margin__c);
        System.assertNotEquals(cases[1].Actual_Guardrail_Margin__c, opportunitiesAfter[1].Actual_Deal_Margin__c);
    }
}