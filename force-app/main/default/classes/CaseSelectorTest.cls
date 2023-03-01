@isTest
private class CaseSelectorTest {
    private static CaseSelector caseSelector = new CaseSelector();
    private static final Id REA_REC_TYPE_ID = Schema.SObjectType.Case.getRecordTypeInfosByName().get('REA').getRecordTypeId();
    
    @testSetup
    static void makeData() {
        Account acc = TestingUtility.createAccount('Acc', true);
        Contact con = TestingUtility.createContact(acc.Id, 'Doe', false);
        Opportunity testOpportunity = TestingUtility.createOpportunity(acc.Id, false);
            
        insert new Case(Subject = 'Test Case 1', RecordTypeId = REA_REC_TYPE_ID, Opportunity__c = testOpportunity.Id);
    }

    @isTest
    static void getCasesByIdTest() {
        Map<Id, Case> casesMap = new Map<Id,Case>([SELECT Id FROM Case]);
        Test.startTest();
        List<Case> cases = caseSelector.getCasesById(new List<Id>(casesMap.keySet()));
        Test.stopTest();
        System.assertEquals(1, casesMap.size(), 'Should return 1 Case record.');
        System.assertEquals(1, cases.size(), 'Should return 1 Case record.');
    }

    @isTest
    static void getCasesByOpportunityIdTest() {
        Id opportunityId = [SELECT Id FROM Opportunity LIMIT 1]?.Id;
        Map<Id, Case> casesMap = new Map<Id,Case>([SELECT Id FROM Case WHERE Opportunity__c = :opportunityId]);
        Test.startTest();
        List<Case> cases = caseSelector.getCasesByOpportunityId(new Set<Id>{opportunityId});
        Test.stopTest();
        System.assertEquals(1, casesMap.size(), 'Should return 1 Case record.');
        System.assertEquals(1, cases.size(), 'Should return 1 Case record.');
    }
}