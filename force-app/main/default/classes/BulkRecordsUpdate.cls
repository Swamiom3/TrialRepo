/************************************************************************************************************************************
    Author      :   Liubomyr Mishchykha
    Description :   Used to update records uploaded by the user with disabling specific trigger handlers
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION     DATE                AUTHOR                  DETAIL
    1           Aug 26, 2020        Liubomyr Mishchykha     Initial version
**************************************************************************************************************************************/
public with sharing class BulkRecordsUpdate implements Database.Batchable<SObject>, Database.RaisesPlatformEvents {

    private final String EVENT_LOAD_TYPE_BULK_CSV = 'Bulk CSV Upload';
    private List<SObject> recordsToUpdate;
    private final String uniqueProcessId;
    private final List<CsvLoader.TriggerHandler> triggerHandlersToDisable;
    private CsvLoader loader;
    public BulkRecordsUpdate(List<SObject> recordsToUpdate, String uniqueProcessId, List<CsvLoader.TriggerHandler> triggerHandlersToDisable, CsvLoader loader) {
        this.recordsToUpdate = loader.filterRecords(recordsToUpdate);
        this.uniqueProcessId = uniqueProcessId;
        this.triggerHandlersToDisable = triggerHandlersToDisable;
        this.loader = loader;
    }

    public Iterable<SObject> start(Database.BatchableContext bc) {
        return this.recordsToUpdate;
    }

    public void execute(Database.BatchableContext bc, List<SObject> recordsToUpdate) {
        try {
            this.loader.disableTriggerHandlers(this.triggerHandlersToDisable);
            List<UpdateRecordResult> updateRecordResults = new List<UpdateRecordResult>();
            List<Database.SaveResult> databaseUpdateResults = Database.update(recordsToUpdate, false);
            for (Integer i = 0; i < databaseUpdateResults.size(); i++) {
                Database.SaveResult databaseUpdateResult = databaseUpdateResults.get(i);
                UpdateRecordResult updateRecordResult = new UpdateRecordResult();
                updateRecordResult.success = databaseUpdateResult.isSuccess();
                if (databaseUpdateResult.isSuccess()) {
                    updateRecordResult.id = databaseUpdateResult.getId();
                } else {
                    updateRecordResult.id = recordsToUpdate.get(i).Id;
                    updateRecordResult.errorMessage = databaseUpdateResult.getErrors()[0].getMessage();
                }
                updateRecordResults.add(updateRecordResult);
            }
            this.fireRecordsLoadPlatformEvent('BATCH_PROCESSED', JSON.serialize(updateRecordResults));
        } catch (Exception ex){
            this.fireRecordsLoadPlatformEvent('BATCH_PROCESSING_ERROR', ex.getMessage());
        }
    }

    public void finish(Database.BatchableContext bc) {
        AsyncApexJob job = [SELECT Id, TotalJobItems, NumberOfErrors FROM AsyncApexJob WHERE Id = :bc.getJobId()];
        this.fireRecordsLoadPlatformEvent('BATCH_JOB_COMPLETED', String.format('Job {0} is finished. Total number of batches processed: {1}. Number of failed batches: {2}', new List<Object>{ job.Id, job.TotalJobItems, job.NumberOfErrors }));  
    }

    private void fireRecordsLoadPlatformEvent(String messageType, String payload) {
        EventBus.publish(new Records_Load__e(
            Unique_Process_Id__c = this.uniqueProcessId,
            Load_Type__c = EVENT_LOAD_TYPE_BULK_CSV, 
            Message_Type__c = messageType,
            Information_Payload__c = payload.abbreviate(Records_Load__e.Information_Payload__c.getDescribe().getLength())
        ));  
    }

    private class UpdateRecordResult {
        public Boolean success;
        public String id;
        public String errorMessage;
    }
}