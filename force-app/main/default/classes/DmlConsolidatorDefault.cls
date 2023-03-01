/************************************************************************************************************************************
    Author      :   Liubomyr Mishchykha
    Description :   Class to consolidate single DMLs and execute them in batch
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION     DATE                AUTHOR                  DETAIL
    1           Apr 15, 2021        Liubomyr Mishchykha     Initial version
**************************************************************************************************************************************/
public inherited sharing class DmlConsolidatorDefault extends DmlConsolidator {

    private static DmlConsolidatorDefault instance;

    private DmlConsolidatorDefault() {}

    public static DmlConsolidatorDefault getInstance() {
        if (instance == null) {
            instance = new DmlConsolidatorDefault();
        }
        return instance;
    }

    protected override void doInsert(List<SObject> records) {
        insert records;
    }

    protected override void doUpdate(List<SObject> records) {
        update records;
    }

    protected override void doDelete(List<SObject> records) {
        delete records;
    }
}