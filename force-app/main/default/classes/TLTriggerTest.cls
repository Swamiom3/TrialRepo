/**
 * Tests for TLTrigger
 * @author Grant Adamson, Traction on Demand
 * @date 2017-05-01
 * @group TLTrigger
 */
@IsTest
private class TLTriggerTest {
    private static List<Account> records;
    private static Map<Id, Account> existingRecords;

    static {
        records = new List<Account>{
                new Account(Id = fflib_IDGenerator.generate(Account.SObjectType), Name = 'test1', Website='www.test1.test'),
                new Account(Id = fflib_IDGenerator.generate(Account.SObjectType), Name = 'test2', Website='www.test2.test')
        };

        existingRecords = new Map<Id, Account>{
                records[0].Id => new Account(Id = records[0].Id, Name = 'test1', Website='www.testing1.test'),
                records[1].Id => new Account(Id = records[1].Id, Name = 'oldtest2', Website='www.testing2.test')
        };
    }

    @IsTest
    private static void filterByFieldCriteria() {
        Test.startTest();

        final List<Account> results = TLTrigger.filterByFieldCriterium(records, Account.Name, 'test1');

        Test.stopTest();


        System.assertEquals(1, results.size(), 'One record should be returned');
        System.assertEquals(records[0], results[0],
                'The record returned should be the one with the field matching the specified criteria');
    }

    @IsTest
    private static void filterByFieldChangedSObjectField() {
        Test.startTest();

        final List<Account> results = TLTrigger.filterByFieldChanged(records, existingRecords, Account.Name);

        Test.stopTest();


        System.assertEquals(1, results.size(), 'One record should be returned');
        System.assertEquals(records[1], results[0],
                'The record returned should be the one with a field change for the specified field');
    }

    @IsTest
    private static void filterByFieldChangedString() {
        Test.startTest();

        final List<Account> results = TLTrigger.filterByFieldChanged(records, existingRecords, 'Name');

        Test.stopTest();


        System.assertEquals(1, results.size(), 'One record should be returned');
        System.assertEquals(records[1], results[0],
                'The record returned should be the one with a field change for the specified field');
    }

    @IsTest
    private static void checkRecordProcess() {
        Test.startTest();

        for (Account account : records) {
            TLTrigger.addRecordProcess(account.Id, 'checkRecordProcess');
        }

        Test.stopTest();


        for (Account account : records) {
            System.assertEquals(true, TLTrigger.wasRecordProcessed(account.Id, 'checkRecordProcess'), 'Record should be processed');
        }

    }

    @IsTest
    private static void testIsFieldChanged() {
        Boolean isChanged = false;

        Test.startTest();
        isChanged = TLTrigger.isFieldChanged(records[1],Account.Name,existingRecords);
        Test.stopTest();

        System.assert(isChanged,'TLTrigger.isFieldChanged did not detect the change in the name field');
    }

    @IsTest
    private static void testFilterByFieldCriteria() {
        final String ACCOUNT_NAME = 'test1';
        Test.startTest();
        List<Account> filteredCriteriaAccounts = (List<Account>) TLTrigger.filterByFieldCriteria(records,Account.Name,new List<Object>{ACCOUNT_NAME});
        Test.stopTest();

        for(Account a : filteredCriteriaAccounts) {
            System.assertEquals(a.Name,ACCOUNT_NAME,'The record was not properly filtered based on the field value');
        }
    }

    @IsTest
    private static void testFilterByMapFieldToValue() {
        final String ACCOUNT_NAME = 'test1';
        Test.startTest();
        List<Account> filteredCriteriaAccounts = (List<Account>) TLTrigger.filterByMapFieldToValue(records,new Map<SObjectField,Object>{Account.Name => ACCOUNT_NAME});
        Test.stopTest();

        for(Account a : filteredCriteriaAccounts) {
            System.assertEquals(a.Name,ACCOUNT_NAME,'The record was not properly filtered based on the field value');
        }
    }

    @IsTest
    private static void testFilterByFieldsChanged() {
        Test.startTest();
        List<Account> filteredAccounts = TLTrigger.filterByFieldsChanged(records,existingRecords,new List<SObjectField>{Account.Name,Account.Website},true);
        Test.stopTest();

        System.assert(filteredAccounts.size() > 0,'No records were filtered');
    }
}