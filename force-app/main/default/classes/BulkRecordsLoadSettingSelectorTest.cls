@isTest
private class BulkRecordsLoadSettingSelectorTest {
    @isTest
    static void testGetBulkRecordsLoaSettiingsBySObjectType() {
        Test.startTest();
        List<Bulk_Records_Load_Setting__mdt> bulkRecordsLoadSettings = new BulkRecordsLoadSettingSelector().getBulkRecordsLoaSettiingsBySObjectType('Account');
        Test.stopTest();
        System.assertNotEquals(null, bulkRecordsLoadSettings, 'Configuration metadata records must be returned');
        System.assert(!bulkRecordsLoadSettings.isEmpty(), 'Configuration metadata records must be returned');
    }
}