@isTest
public with sharing class DmlConsolidatorDisableTriggersTest {
    @isTest
    static void testConsolidatorDisableTriggers() {
        MetadataDrivenTriggerHandler.disableExecution();
        List<Account> accounts = UtilAccount.GetNewAccounts(5, true);
        List<Opportunity> opportunities = UtilOpportunity.getNewOpportunity(6, accounts[0], true);
        System.assertEquals(opportunities[2].AccountId, accounts[0].Id, 'Opportunity is not assigned to correct account');
        opportunities[2].AccountId = accounts[2].Id;
        SObjectTriggerHandler.clearLoopCount();
        Test.startTest();
        DmlConsolidatorDisableTriggers.getInstance()
                                      .add(new List<Account>{new Account(Name = 'test 1')}, DmlConsolidator.Operation.FOR_INSERT)
                                      .add(new List<SObject>{opportunities[2]}, DmlConsolidator.Operation.FOR_UPDATE)
                                      .add(new List<SObject>{accounts[3], accounts[4]}, DmlConsolidator.Operation.FOR_DELETE)
                                      .run();
        Test.stopTest();
        System.assertEquals(4, [SELECT count() FROM Account], 'Number of accounts in the system is not correct');
        System.assertEquals(accounts[2].Id, [SELECT AccountId FROM Opportunity WHERE Id = :opportunities[2].Id].AccountId, 'Opportunity is not updated to correct account');
        System.assert([SELECT Id FROM Account WHERE Id = :accounts[4].Id].isEmpty(), 'Account should be deleted');
        System.assert(SObjectTriggerHandler.loopCountMap.isEmpty(), 'Trigger handlers should not be executed');
    }
}