/************************************************************************************************************************************
    Author      :   Liubomyr Mishchykha
    Description :   Class to consolidate single DMLs and execute them in batch with CRUD, FLS and sharing settings enforced
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION     DATE                AUTHOR                  DETAIL
    1           Apr 15, 2021        Liubomyr Mishchykha     Initial version
**************************************************************************************************************************************/
public with sharing class DmlConsolidatorSecurityEnforced extends DmlConsolidator {

    private static DmlConsolidatorSecurityEnforced instance;

    private DmlConsolidatorSecurityEnforced() {}

    public static DmlConsolidatorSecurityEnforced getInstance() {
        if (instance == null) {
            instance = new DmlConsolidatorSecurityEnforced();
        }
        return instance;
    }

    protected override void doInsert(List<SObject> records) {
        insert Security.stripInaccessible(AccessType.CREATABLE, records).getRecords();
    }

    protected override void doUpdate(List<SObject> records) {
        update Security.stripInaccessible(AccessType.UPDATABLE, records).getRecords();
    }

    protected override void doDelete(List<SObject> records) {
        delete records;
    }
}