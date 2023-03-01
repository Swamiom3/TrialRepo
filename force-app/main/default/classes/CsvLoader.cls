/************************************************************************************************************************************
    Author      :   Liubomyr Mishchykha
    Description :   Abstract class to contain logic for updating records based on CSV file upload.
                    Should be extended for each SObject type supported by CSV loader module
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION     DATE                AUTHOR                  DETAIL
    1           Aug 26, 2020        Liubomyr Mishchykha     Initial version
**************************************************************************************************************************************/
public abstract inherited sharing class CsvLoader {

    public abstract List<TriggerHandler> getTriggerHandlers();

    public virtual List<SObject> filterRecords(List<SObject> records) {
        return records;
    }

    public void disableTriggerHandlers(List<TriggerHandler> triggerHandlers) {
        for (TriggerHandler triggerHandler : triggerHandlers) {
            this.disableMetadataTriggerHandlerNew(triggerHandler);
        }
    }

    private void disableMetadataTriggerHandlerNew(TriggerHandler triggerHandler) {
        SObjectTriggerHandler.bypass(triggerHandler.name);
    }

    public class TriggerHandler {
        @AuraEnabled
        public String name {get; set;}
        @AuraEnabled
        public String description {get; set;}
        @AuraEnabled
        public String sObjectType {get; set;}
        @AuraEnabled
        public String funcEventTime {get; set;}
        @AuraEnabled
        public String funcEventType {get; set;}

        public TriggerHandler() {}

        public TriggerHandler(String name, String description, String sObjectType, String funcEventTime, String funcEventType) {
            this.name = name;
            this.description = description;
            this.sObjectType = sObjectType;
            this.funcEventTime = funcEventTime;
            this.funcEventType = funcEventType;
        }
    }
}