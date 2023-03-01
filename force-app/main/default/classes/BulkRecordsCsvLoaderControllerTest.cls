@isTest
public with sharing class BulkRecordsCsvLoaderControllerTest {

    @isTest
    public static void testGetTriggerHandlersToDisable() {
        Test.startTest();
        List<CsvLoader.TriggerHandler> opportunityTriggerHandlers = BulkRecordsCsvLoaderController.getTriggerHandlersToDisable('Opportunity');
        Test.stopTest();
        System.assertNotEquals(null, opportunityTriggerHandlers);
        System.assert(opportunityTriggerHandlers.size() > 0, 'List of opportunity trigger handlers to disable must not be empty');
    }

    @isTest
    public static void testBatchJobTriggerredSuccessfully() {
        String uniqueProcessId = UserInfo.getUserId() + '_' + Datetime.now();
        Profile systemAdmin = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        Map<String, Object> userRecordMap = new Map<String, Object>();
        userRecordMap.put('LastName', 'Last Name 1');
        userRecordMap.put('Username', 'testweworkuser123@test.com');
        userRecordMap.put('Email', 'testuser123@test.com');
        User user1 = TestingUtility.insertUserWithAssert(systemAdmin.Id, userRecordMap, true);
        Map<String, Object> accountRecordsFieldMappings = new Map<String, Object>{'OwnerId' => user1.Id};
        List<Account> accountsToUpdate = UtilAccount.GetNewAccountsWithFieldMapping(40, accountRecordsFieldMappings, true);


        try {
            for (Account accountToUpdate : accountsToUpdate) {
                accountToUpdate.OwnerId = UserInfo.getUserId();
            }
            CsvLoader loader = BulkRecordsCsvLoaderController.getLoader('Account');
            System.assert(loader instanceof CsvLoaderAccount);
            Test.startTest();
            BulkRecordsCsvLoaderController.updateRecords(accountsToUpdate, uniqueProcessId, loader.getTriggerHandlers());
            Test.stopTest();
            AsyncApexJob job = [SELECT Id, Status, TotalJobItems From AsyncApexJob WHERE ApexClass.Name = 'BulkRecordsUpdate'];
            System.assertNotEquals(null, job, 'Batch job wasn\'t triggered');
            System.assertEquals(1, job.TotalJobItems, 'There should be single batch in the job');
        } catch (Exception ex) {
            System.assert(false, 'Job is supposed to start successfully');
        }
    }

    @isTest
    public static void testBatchJobFailedDueToInvalidSObjectType() {
        String uniqueProcessId = UserInfo.getUserId() + '_' + Datetime.now();
        List<Map<String,Object>> ListOfMapFields = new List<Map<String,Object>>();
        for (Integer i = 0; i < 10; i++) {
            Map <String, Object> mapCaseFields = new Map <String, Object>();
            ListOfMapFields.add(mapCaseFields);
        }
        List<Geography__c> geographiesToUpdate =  UtilGeneral.createTestRecords(Geography__c.sObjectType, ListOfMapFields, true);
        try {
            for (Geography__c geo : geographiesToUpdate) {
                geo.OwnerId = UserInfo.getUserId();
            }
            CsvLoader loader = BulkRecordsCsvLoaderController.getLoader('Geography__c');
            Test.startTest();
            BulkRecordsCsvLoaderController.updateRecords(geographiesToUpdate, uniqueProcessId, loader.getTriggerHandlers());
            Test.stopTest();
            System.assert(false, 'Execution is not supposed to reach this point');
        } catch (BulkRecordsCsvLoaderController.BulkLoaderInvalidSObjectException ex) {
            System.assertEquals('SObject type is invalid or not currently supported', ex.getMessage(), 'Wrong error message in caught exception');
        } catch (Exception ex) {
            System.assert(false, 'Wrong exception type thrown');
        }
    }

    @isTest
    public static void testGetConstants() {
        System.assertEquals(' ======= ', BulkRecordsCsvLoaderController.getConstants().LOG_SEPARATOR, 'Wrong LOG_SEPARATOR constant value');
        System.assertEquals('/event/Records_Load__e', BulkRecordsCsvLoaderController.getConstants().PLATFORM_EVENT_CHANNEL, 'Wrong PLATFORM_EVENT_CHANNEL constant value');
        System.assertEquals('Bulk CSV Upload', BulkRecordsCsvLoaderController.getConstants().EVENT_LOAD_TYPE, 'Wrong EVENT_LOAD_TYPE constant value');
        System.assertEquals('BATCH_PROCESSED', BulkRecordsCsvLoaderController.getConstants().BATCH_PROCESSED_EVENT_MESSAGE_TYPE, 'Wrong BATCH_PROCESSED_EVENT_MESSAGE_TYPE constant value');
        System.assertEquals('BATCH_PROCESSING_ERROR', BulkRecordsCsvLoaderController.getConstants().BATCH_PROCESSING_ERROR_EVENT_MESSAGE_TYPE, 'Wrong BATCH_PROCESSING_ERROR_EVENT_MESSAGE_TYPE constant value');
        System.assertEquals('BATCH_JOB_COMPLETED', BulkRecordsCsvLoaderController.getConstants().BATCH_JOB_COMPLETED_EVENT_MESSAGE_TYPE, 'Wrong BATCH_JOB_COMPLETED_EVENT_MESSAGE_TYPE constant value');
    }

    @isTest
    public static void testGetFieldsToUpdate() {
        Test.startTest();
        List<String> fieldsToUpdate = BulkRecordsCsvLoaderController.getFieldsToUpdate('Account');
        Test.stopTest();
        System.assertNotEquals(null, fieldsToUpdate, 'List of Account fields to update must not be null');
        System.assertEquals([SELECT count() FROM Bulk_Records_Load_Setting__mdt WHERE Active__c = true AND SObject_Type__c = 'Account'], fieldsToUpdate.size(), 'List of Account fields to update was not retrieved correctly');
    }
}