/************************************************************************************************************************************
    Author      :   Liubomyr Mishchykha
    Description :   Class to consolidate single DMLs and execute them in partial success mode
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION     DATE                AUTHOR                  DETAIL
    1           Apr 15, 2021        Liubomyr Mishchykha     Initial version
**************************************************************************************************************************************/
public inherited sharing class DmlConsolidatorPartialSuccess extends DmlConsolidator {

    private static DmlConsolidatorPartialSuccess instance;

    private DmlConsolidatorPartialSuccess() {}

    public static DmlConsolidatorPartialSuccess getInstance() {
        if (instance == null) {
            instance = new DmlConsolidatorPartialSuccess();
        }
        return instance;
    }

    protected override void doInsert(List<SObject> records) {
        Database.insert(records, false);
    }

    protected override void doUpdate(List<SObject> records) {
        Database.update(records, false);
    }

    protected override void doDelete(List<SObject> records) {
        Database.delete(records, false);
    }
}