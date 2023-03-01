/************************************************************************************************************************************
    Author      :   Liubomyr Mishchykha
    Description :   Class to consolidate single DMLs and execute them in batch with trigger logic disabled
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION     DATE                AUTHOR                  DETAIL
    1           Apr 15, 2021        Liubomyr Mishchykha     Initial version
**************************************************************************************************************************************/
public inherited sharing class DmlConsolidatorDisableTriggers extends DmlConsolidator {

    private static DmlConsolidatorDisableTriggers instance;

    private DmlConsolidatorDisableTriggers() {}

    public static DmlConsolidatorDisableTriggers getInstance() {
        if (instance == null) {
            instance = new DmlConsolidatorDisableTriggers();
        }
        return instance;
    }

    protected override void doInsert(List<SObject> records) {
        SObjectTriggerHandler.disableExecution();
        insert records;
        SObjectTriggerHandler.enableExecution();
    }

    protected override void doUpdate(List<SObject> records) {
        SObjectTriggerHandler.disableExecution();
        update records;
        SObjectTriggerHandler.enableExecution();
    }

    protected override void doDelete(List<SObject> records) {
        SObjectTriggerHandler.disableExecution();
        delete records;
        SObjectTriggerHandler.enableExecution();
    }
}