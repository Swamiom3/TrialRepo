@isTest
public with sharing class BulkRecordsUpdateTest {
    @testSetup
    public static void setup() {
        Test.startTest();
        Profile systemAdmin = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        Map<String, Object> userRecordMap = new Map<String, Object>();
        userRecordMap.put('LastName', 'Last Name 1');
        userRecordMap.put('Username', 'testweworkuser123@test.com');
        userRecordMap.put('Email', 'testuser123@test.com');
        User user1 = TestingUtility.insertUserWithAssert(systemAdmin.Id, userRecordMap, true);
        Map<String, Object> accountRecordsFieldMappings = new Map<String, Object>{'OwnerId' => user1.Id};
        List<Account> accounts = UtilAccount.GetNewAccountsWithFieldMapping(200, accountRecordsFieldMappings, true);


        Map<String, Object> opportunityRecordsFieldMappings = new Map<String, Object>{'OwnerId' => user1.Id};
        List<Opportunity> opportunities = UtilOpportunity.GetNewOpportunityWithFieldMapping(10, accounts[0], opportunityRecordsFieldMappings, true);
        Test.stopTest();
        System.assertEquals(user1.Id, accounts[0].OwnerId, 'Owner of account is incorrect');
        System.assertEquals(user1.Id, opportunities[0].OwnerId, 'Owner of opportunity is incorrect');
    }

    @isTest
    public static void testAccountsUpdateSucceed() {
        String uniqueProcessId = UserInfo.getUserId() + '_' + Datetime.now();
        List<Account> accountsToUpdate = [SELECT Id, OwnerId FROM Account];
        System.assertNotEquals(UserInfo.getUserId(), accountsToUpdate[0].OwnerId, 'Owner of account is incorrect');
        for (Account accountToUpdate : accountsToUpdate) {
            accountToUpdate.OwnerId = UserInfo.getUserId();
        }
        CsvLoader loader = BulkRecordsCsvLoaderController.getLoader('Account');
        Test.startTest();
        BulkRecordsUpdate bru = new BulkRecordsUpdate(accountsToUpdate, uniqueProcessId, loader.getTriggerHandlers(), loader);
        Id batchId = Database.executeBatch(bru);
        Test.stopTest();
        AsyncApexJob job = [SELECT NumberOfErrors, TotalJobItems FROM AsyncApexJob WHERE Id = :batchId];
        System.assertNotEquals(null, job, 'Batch job must not be null');
        System.assertEquals(0, job.NumberOfErrors, 'There should be no errors for this job');
        System.assertEquals(1, job.TotalJobItems, 'There should be single batch in this job');
        System.assertEquals(UserInfo.getUserId(), [SELECT OwnerId FROM Account][0].OwnerId, 'Owner of account is incorrect');
    }

    @isTest
    public static void testOpportunitiesUpdateSucceed() {
        String uniqueProcessId = UserInfo.getUserId() + '_' + Datetime.now();
        List<Opportunity> opportunitiesToUpdate = [SELECT Id, OwnerId FROM Opportunity];
        System.assertNotEquals(UserInfo.getUserId(), opportunitiesToUpdate[0].OwnerId, 'Owner of opportunity is incorrect');
        for (Opportunity opportunityToUpdate : opportunitiesToUpdate) {
            opportunityToUpdate.OwnerId = UserInfo.getUserId();
        }
        CsvLoader loader = BulkRecordsCsvLoaderController.getLoader('Opportunity');
        Test.startTest();
        BulkRecordsUpdate bru = new BulkRecordsUpdate(opportunitiesToUpdate, uniqueProcessId, loader.getTriggerHandlers(), loader);
        Id batchId = Database.executeBatch(bru);
        Test.stopTest();
        AsyncApexJob job = [SELECT NumberOfErrors, TotalJobItems FROM AsyncApexJob WHERE Id = :batchId];
        System.assertNotEquals(null, job, 'Batch job must not be null');
        System.assertEquals(0, job.NumberOfErrors, 'There should be no errors for this job');
        System.assertEquals(1, job.TotalJobItems, 'There should be single batch in this job');
        System.assertEquals(UserInfo.getUserId(), [SELECT OwnerId FROM Opportunity][0].OwnerId, 'Owner of opportunity is incorrect');
    }
}