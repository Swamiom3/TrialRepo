/************************************************************************************************************************************
    Author      :   Liubomyr Mishchykha
    Description :   Abstract class that contains logic to consolidate and run in batch single DML statements
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION     DATE                AUTHOR                  DETAIL
    1           Apr 15, 2021        Liubomyr Mishchykha     Initial version
**************************************************************************************************************************************/
public inherited sharing abstract class DmlConsolidator {

    @TestVisible
    protected List<SObject> recordsToInsert;
    @TestVisible
    protected Map<Id, SObject> recordsToUpdate;
    @TestVisible
    protected Map<Id, SObject> recordsToDelete;

    private static Map<SObjectType, Map<String, SObjectField>> objectTypesToFields = new Map<SObjectType, Map<String, SObjectField>>();

    protected DmlConsolidator() {
        recordsToInsert = new List<SObject>();
        recordsToUpdate = new Map<Id, SObject>();
        recordsToDelete = new Map<Id, SObject>();
    }

    public void run() {
        runDmls();
        clear();
    }

    protected abstract void doInsert(List<SObject> records);
    protected abstract void doUpdate(List<SObject> records);
    protected abstract void doDelete(List<SObject> records);

    public void clear() {
        recordsToInsert.clear();
        recordsToUpdate.clear();
        recordsToDelete.clear();
    }

    private void runDmls() {
        if (!recordsToInsert.isEmpty()) {
            List<SObject> records = recordsToInsert.clone();
            records.sort();
            recordsToInsert.clear();
            try {
                doInsert(records);
            } catch (TypeException ex) {
                for (List<SObject> subList : splitRecords(records)) {
                    doInsert(subList);
                }
            }
        }
        if (!recordsToUpdate.isEmpty()) {
            List<SObject> records = recordsToUpdate.clone().values();
            records.sort();
            recordsToUpdate.clear();
            try {
                doUpdate(records);
            } catch (TypeException ex) {
                for (List<SObject> subList : splitRecords(records)) {
                    doUpdate(subList);
                }
            }
        }
        if (!recordsToDelete.isEmpty()) {
            List<SObject> records = recordsToDelete.clone().values();
            records.sort();
            recordsToDelete.clear();
            try {
                doDelete(records);
            } catch (TypeException ex) {
                for (List<SObject> subList : splitRecords(records)) {
                    doDelete(subList);
                }
            }
        }
    }

    public virtual DmlConsolidator add(List<SObject> records, Operation type) {
        switch on type {
            when FOR_INSERT {
                recordsToInsert.addAll(records);
                return this;
            }
            when FOR_UPDATE {
                addRecordsForUpdate(records);
                return this;
            }
            when FOR_UPSERT {
                addRecordsForUpsert(records);
                return this;
            }
            when FOR_DELETE {
                recordsToDelete.putAll(records);
                return this;
            }
        }
        return this;
    }

    private void addRecordsForUpdate(List<SObject> records) {
        for (SObject record : records) {
            if (recordsToUpdate.containsKey(record.Id)) {
                SObject cachedRecord = recordsToUpdate.get(record.Id);
                SObjectType type = record.getSObjectType();
                if (!objectTypesToFields.containsKey(type)) {
                    objectTypesToFields.put(type, type.getDescribe().fields.getMap());
                }
                Map<String, SObjectField> fieldsMap = objectTypesToFields.get(type);
                Map<String, Object> updatedFields = record.getPopulatedFieldsAsMap();
                for (String updatedFieldName : updatedFields.keySet()) {
                    if (fieldsMap.containsKey(updatedFieldName)) {
                        cachedRecord.put(updatedFieldName, updatedFields.get(updatedFieldName));
                    }
                }
            } else {
                recordsToUpdate.put(record.Id, record);
            }
        }
    }

    private void addRecordsForUpsert(List<SObject> records) {
        for (SObject record : records) {
            if (record.Id != null) {
                addRecordsForUpdate(new List<SObject> {record});
            } else {
                recordsToInsert.add(record);
            }
        }
    }

    @TestVisible
    private List<List<SObject>> splitRecords(List<SObject> records) {
        Map<SObjectType, List<SObject>> recordsBySObjectType = new Map<SObjectType, List<SObject>>();
        for (SObject record : records) {
            SObjectType type = record.getSObjectType();
            if (recordsBySObjectType.containsKey(type)) {
                recordsBySObjectType.get(type).add(record);
            } else {
                recordsBySObjectType.put(type, new List<SObject>{record});
            }
        }
        List<List<SObject>> sortedRecords = recordsBySObjectType.values();
        List<List<SObject>> splitRecordLists = new List<List<SObject>>();
        for (Integer i = 0; i < sortedRecords.size(); i++) {
            if (Math.mod(i, 10) == 0) {
                splitRecordLists.add(new List<SObject>());
            }
            splitRecordLists[splitRecordLists.size() - 1].addAll(sortedRecords[i]);
        }
        return splitRecordLists;
    }

    public enum Operation {
        FOR_INSERT, FOR_UPDATE, FOR_UPSERT, FOR_DELETE
    }
}