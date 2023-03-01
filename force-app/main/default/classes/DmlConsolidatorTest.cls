@isTest
public with sharing class DmlConsolidatorTest {
    @isTest
    static void testUpsertRecordsCorrectDistribution() {
        DmlConsolidatorDefault consolidator = DmlConsolidatorDefault.getInstance();
        List<Account> accounts = new List<Account> {
            new Account(Id = TestUtility.getFakeId(Account.SObjectType), Name = 'test 1'),
            new Account(Id = TestUtility.getFakeId(Account.SObjectType), Name = 'test 2'),
            new Account(Name = 'test 3')
        };
        Test.startTest();
        consolidator.add(accounts, DmlConsolidator.Operation.FOR_UPSERT);
        Test.stopTest();
        System.assertEquals(1, consolidator.recordsToInsert.size(), 'Only one record should be registered for insertion');
        System.assertEquals(2, consolidator.recordsToUpdate.size(), 'Only two records should be registered for update');
    }

    @isTest
    static void testClearDmlLists() {
        DmlConsolidatorDefault consolidator = DmlConsolidatorDefault.getInstance();
        consolidator.add(new List<Account> {new Account(Name = 'test 1')}, DmlConsolidator.Operation.FOR_INSERT);
        List<Account> accounts = new List<Account> {
            new Account(Id = TestUtility.getFakeId(Account.SObjectType), Name = 'test 2'),
            new Account(Id = TestUtility.getFakeId(Account.SObjectType), Name = 'test 3')
        };
        consolidator.add(accounts, DmlConsolidator.Operation.FOR_UPDATE);
        consolidator.add(new List<Account> {new Account(Id = TestUtility.getFakeId(Account.SObjectType), Name = 'test 4')}, DmlConsolidator.Operation.FOR_DELETE);
        System.assertEquals(1, consolidator.recordsToInsert.size(), 'Only one record should be registered for insertion');
        System.assertEquals(2, consolidator.recordsToUpdate.size(), 'Only two records should be registered for update');
        System.assertEquals(1, consolidator.recordsToDelete.size(), 'Only one record should be registered for deletion');
        Test.startTest();
        consolidator.clear();
        Test.stopTest();
        System.assert(consolidator.recordsToInsert.isEmpty(), 'Insertion records list must be cleared');
        System.assert(consolidator.recordsToUpdate.isEmpty(), 'Update records list must be cleared');
        System.assert(consolidator.recordsToDelete.isEmpty(), 'Deletion records list must be cleared');
    }

    @isTest
    static void testAddRecordsForUpdateNoDuplicates() {
        DmlConsolidatorDefault consolidator = DmlConsolidatorDefault.getInstance();
        Account accountToUpdate = new Account(Id = TestUtility.getFakeId(Account.SObjectType), Name = 'test 1');
        consolidator.add(new List<Account> {accountToUpdate}, DmlConsolidator.Operation.FOR_UPDATE);
        Account clonedAccount = accountToUpdate.clone(true, true);
        clonedAccount.Name = 'test 2';
        System.assertEquals(accountToUpdate.Id, clonedAccount.Id, 'Ids don\'t match, not valid data for this unit test');
        Test.startTest();
        consolidator.add(new List<Account> {clonedAccount}, DmlConsolidator.Operation.FOR_UPDATE);
        Test.stopTest();
        System.assertEquals(1, consolidator.recordsToUpdate.size(), 'List of records for update should contain only 1 record');
        System.assertEquals('test 2', consolidator.recordsToUpdate.values()[0].get('Name'), 'Account name is not set to proper value');
    }

    @isTest
    static void testAddRecordsForUpdateNoDuplicatesSanitizeRelationships() {
        DmlConsolidatorDefault consolidator = DmlConsolidatorDefault.getInstance();
        Account accountToUpdate = new Account(Id = TestUtility.getFakeId(Account.SObjectType), Name = 'test 1');
        consolidator.add(new List<Account> {accountToUpdate}, DmlConsolidator.Operation.FOR_UPDATE);
        Account clonedAccount = (Account) JSON.deserialize('{"Id": "' + accountToUpdate.Id
                                                                + '", "Name": "test 2", "Primary_Member__r": {"Name": "Contact Name"}}',
                                                            Account.class);
        System.assertNotEquals(null, clonedAccount.Primary_Member__r, 'Primary member must be populated');
        System.assertEquals(accountToUpdate.Id, clonedAccount.Id, 'Ids don\'t match, not valid data for this unit test');
        Test.startTest();
        try {
            consolidator.add(new List<Account> {clonedAccount}, DmlConsolidator.Operation.FOR_UPDATE);
        } catch (Exception ex) {
            System.assert(false, 'Exception should not be thrown');
        }
        Test.stopTest();
        System.assertEquals(1, consolidator.recordsToUpdate.size(), 'List of records for update should contain only 1 record');
        System.assertEquals('test 2', consolidator.recordsToUpdate.values()[0].get('Name'), 'Account name is not set to proper value');
        System.assertEquals(null, consolidator.recordsToUpdate.values()[0].getSObject('Primary_Member__r'), 'Primary member must be sanitized');
    }

    @isTest
    static void testSplitRecords() {
        List<SObject> multipleSObjectTypes = new List<SObject> {
            new Account(Name = 'test 1'),
            new Opportunity(Name = 'test 2'),
            new Contact(LastName = 'test 3'),
            new Lead(LastName = 'test 4'),
            new Journey__c(Name = 'test 5'),
            new ServiceAppointment(),
            new Case(Subject = 'test 6'),
            new Cluster__c(Name = 'test 7'),
            new Building__c(Name = 'test 8'),
            new Campaign(Name = 'test 9'),
            new OpportunityLineItem(OpportunityId = TestUtility.getFakeId(Opportunity.SObjectType)),
            new OpportunityTeamMember(OpportunityId = TestUtility.getFakeId(Opportunity.SObjectType)),
            new Account(Name = 'test 10'),
            new Account(Name = 'test 11')
        };
        Test.startTest();
        List<List<SObject>> recordsSplitByTenSObjectTypes = DmlConsolidatorDefault.getInstance().splitRecords(multipleSObjectTypes);
        Test.stopTest();
        System.assertEquals(2, recordsSplitByTenSObjectTypes.size(), 'Records list should be split into 2 separate lists');
        System.assertEquals(12, recordsSplitByTenSObjectTypes[0].size(), 'Records list should contain records of 10 unique SObject types');
        System.assertEquals(2, recordsSplitByTenSObjectTypes[1].size(), 'Records list should contain records of 2 unique SObject types');
    }

    @isTest
    static void testConsolidator() {
        MetadataDrivenTriggerHandler.disableExecution();
        List<Account> accounts = UtilAccount.GetNewAccounts(5, true);
        List<Opportunity> opportunities = UtilOpportunity.getNewOpportunity(6, accounts[0], true);
        System.assertEquals(opportunities[2].AccountId, accounts[0].Id, 'Opportunity is not assigned to correct account');
        opportunities[2].AccountId = accounts[2].Id;
        Test.startTest();
        DmlConsolidatorDefault.getInstance()
                                .add(new List<Account> {new Account(Name = 'test 1')}, DmlConsolidator.Operation.FOR_INSERT)
                                .add(new List<SObject> {opportunities[2]}, DmlConsolidator.Operation.FOR_UPDATE)
                                .add(new List<SObject> {accounts[3], accounts[4]}, DmlConsolidator.Operation.FOR_DELETE)
                                .run();
        Test.stopTest();
        System.assertEquals(4, [SELECT count() FROM Account], 'Number of accounts in the system is not correct');
        System.assertEquals(accounts[2].Id, [SELECT AccountId FROM Opportunity WHERE Id = :opportunities[2].Id].AccountId, 'Opportunity is not updated to correct account');
        System.assert([SELECT Id FROM Account WHERE Id = :accounts[4].Id].isEmpty(), 'Account should be deleted');
    }
}