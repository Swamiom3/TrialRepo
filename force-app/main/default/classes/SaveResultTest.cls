@isTest
public with sharing class SaveResultTest {

    @isTest
    static void testUnusedProprties() {
        SaveResult srClass = new SaveResult();
        srClass.IsCreated = true;
        srClass.SFObject = (sObject) new Account();
        srClass.DataObject = (Object) new Account();
    }

    @isTest
    static void testException() {
        Test.startTest();
        SaveResult srClass = new SaveResult(new TestException('TestException message'));
        Test.stopTest();
        System.assertEquals(false, srClass.IsSuccess);
        System.assertEquals('TestException message', srClass.Message);
    }

    @isTest
    static void testOneRecordInsert() {
        Database.SaveResult result = Database.insert(new Account(Name = 'TestAcc'));
        Test.startTest();
        SaveResult srClass = new SaveResult(result);
        Test.stopTest();
        System.assertEquals(true, srClass.IsSuccess);
        System.assertEquals(result.getId(), srClass.Id);
    }

    @isTest
    static void testOneRecordUpsert() {
        Account testAccount = UtilAccount.GetNewAccounts(1, true)[0];
        testAccount.Name = 'New_Name';
        Database.UpsertResult result = Database.upsert(testAccount);
        Test.startTest();
        SaveResult srClass = new SaveResult(result);
        Test.stopTest();
        System.assertEquals(true, srClass.IsSuccess);
        System.assertEquals(result.getId(), srClass.Id);
    }

    @isTest
    static void testFewRecordsInsert() {
        List<Account> testAccounts = UtilAccount.GetNewAccounts(2, false);
        Database.SaveResult[] results = Database.insert(testAccounts);
        Test.startTest();
        SaveResult srClass = new SaveResult(results);
        Test.stopTest();
        System.assertEquals(true, srClass.IsSuccess);
    }

    @isTest
    static void testFewRecordsInsert_negative() {
        List<Account> testAccounts = new List<Account>{new Account(), new Account()};
        Database.SaveResult[] results = Database.insert(testAccounts, false);
        Test.startTest();
        SaveResult srClass = new SaveResult(results);
        Test.stopTest();
        System.assertEquals(false, srClass.IsSuccess);
        System.assert(srClass.Message.contains('Required fields are missing'));

    }

    @isTest
    static void testFewRecordsUpsert() {
        List<Account> testAccounts = UtilAccount.GetNewAccounts(2, true);
        testAccounts.add(new Account(Name = 'Tets3'));
        testAccounts[0].Name = 'New Name';
        Database.UpsertResult[] results = Database.upsert(testAccounts);
        Test.startTest();
        SaveResult srClass = new SaveResult(results);
        Test.stopTest();
        System.assertEquals(true, srClass.IsSuccess);
    }

    @isTest
    static void testFewRecordsUpsert_negative() {
        List<Account> testAccounts = new List<Account>{new Account(), new Account()};
        Database.UpsertResult[] results = Database.upsert(testAccounts, false);
        Test.startTest();
        SaveResult srClass = new SaveResult(results);
        Test.stopTest();
        System.assertEquals(false, srClass.IsSuccess);
        System.assert(srClass.Message.contains('Required fields are missing'));
    }

    @isTest
    static void testFewRecordsDelete() {
        SObjectTriggerHandler.disableExecution();
        List<Account> testAccounts = UtilAccount.GetNewAccounts(2, true);
        Database.DeleteResult[] results = Database.delete(testAccounts);
        Test.startTest();
        SaveResult srClass = new SaveResult(results);
        Test.stopTest();
        System.assertEquals(true, srClass.IsSuccess);
    }

    class TestException extends Exception {}
}