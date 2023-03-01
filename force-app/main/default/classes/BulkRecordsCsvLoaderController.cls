/************************************************************************************************************************************
    Author      :   Liubomyr Mishchykha
    Description :   Contains logic to communicate with bulk records csv loader module
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION     DATE                AUTHOR                  DETAIL
    1           Aug 26, 2020        Liubomyr Mishchykha     Initial version
**************************************************************************************************************************************/
public with sharing class BulkRecordsCsvLoaderController {   
    
    private static final String EVENT_LOAD_TYPE_BULK_CSV = 'Bulk CSV Upload';
    private static final String BATCH_JOB_FAILED_TO_START = 'BATCH_JOB_FAILED_TO_START';

    @AuraEnabled(cacheable=true)
    public static List<CsvLoader.TriggerHandler> getTriggerHandlersToDisable(String sObjectApiName) {
        return String.isNotBlank(sObjectApiName) ? getLoader(sObjectApiName).getTriggerHandlers() : null;
    }

    @AuraEnabled
    public static void updateRecords(List<SObject> recordsToUpdate, String uniqueProcessId, List<CsvLoader.TriggerHandler> triggersToBypass) {
        String sObjectApiName = recordsToUpdate[0].getSObjectType().getDescribe().getName();
        try {
            Database.executeBatch(new BulkRecordsUpdate(recordsToUpdate, uniqueProcessId, triggersToBypass, getLoader(sObjectApiName)), 50);
        } catch (Exception ex) {
            EventBus.publish(new Records_Load__e(
                Unique_Process_Id__c = uniqueProcessId,
                Load_Type__c = EVENT_LOAD_TYPE_BULK_CSV, 
                Message_Type__c = 'BATCH_JOB_FAILED_TO_START',
                Information_Payload__c = ex.getMessage()
            ));  
        }
    }

    @AuraEnabled(cacheable=true)
    public static Constants getConstants() {
        return new Constants();
    }

    @AuraEnabled(cacheable=true)
    public static List<String> getFieldsToUpdate(String sObjectApiName) {
        if (String.isBlank(sObjectApiName)) {
            return new List<String>();
        }
        List<String> fieldsToUpdate = new List<String>();
        List<Bulk_Records_Load_Setting__mdt> bulkRecordLoadSettings = new BulkRecordsLoadSettingSelector().getBulkRecordsLoaSettiingsBySObjectType(sObjectApiName);
        for (Bulk_Records_Load_Setting__mdt setting : bulkRecordLoadSettings) {
            fieldsToUpdate.add(setting.Field__c);
        }
        return fieldsToUpdate;
    }

    @TestVisible
    private static CsvLoader getLoader(String sObjectApiName) {
        switch on sObjectApiName {
            when 'Account' {
                return new CsvLoaderAccount();
            }
            when 'Opportunity' {
                return new CsvLoaderOpportunity();
            }
        }
        throw new BulkLoaderInvalidSObjectException('SObject type is invalid or not currently supported'); 
    }

    public class Constants {
        @AuraEnabled
        public final String LOG_SEPARATOR = ' ======= ';
        @AuraEnabled
        public final String PLATFORM_EVENT_CHANNEL = '/event/Records_Load__e';
        @AuraEnabled
        public final String EVENT_LOAD_TYPE = EVENT_LOAD_TYPE_BULK_CSV;
        @AuraEnabled
        public final String BATCH_PROCESSED_EVENT_MESSAGE_TYPE = 'BATCH_PROCESSED';
        @AuraEnabled
        public final String BATCH_PROCESSING_ERROR_EVENT_MESSAGE_TYPE = 'BATCH_PROCESSING_ERROR';
        @AuraEnabled
        public final String BATCH_JOB_COMPLETED_EVENT_MESSAGE_TYPE = 'BATCH_JOB_COMPLETED';
        @AuraEnabled
        public final String BATCH_JOB_FAILED_TO_START_MESSAGE_TYPE = BATCH_JOB_FAILED_TO_START;
    }

    public class BulkLoaderInvalidSObjectException extends Exception {}
}