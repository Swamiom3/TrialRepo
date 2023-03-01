/**
 * Utility methods for trigger processing
 * @author Grant Adamson, Traction on Demand
 * @date 2017-05-01
 * @group TLTrigger
 */
public class TLTrigger {

    private static Map<Id, Set<String>> processesByRecordIds = new Map<Id, Set<String>>();

    /**
     *  @description Checks if a record has already gone through the process provided in execution context
     *  @author      Jeremy Horan, Traction on Demand.
     *  @date        10/19/2018
     *  @param       recordId    Record Id to check
     *  @param       processName Process to check
     */
    public static Boolean wasRecordProcessed(Id recordId, String processName) {
        Boolean wasProcessed = false;

        if (processesByRecordIds.containsKey(recordId)
                && processesByRecordIds.get(recordId).contains(processName)) {
            wasProcessed = true;
        }

        return wasProcessed;
    }

    /**
     *  @description Adds a process that has been run on the record in execution context
     *  @author      Jeremy Horan, Traction on Demand.
     *  @date        10/19/2018
     *  @param       recordId    Record Id to add
     *  @param       processName Process to add
     */
    public static void addRecordProcess(Id recordId, String processName) {
        if (!processesByRecordIds.containsKey(recordId)) {
            processesByRecordIds.put(recordId, new Set<String>());
        }
        processesByRecordIds.get(recordId).add(processName);
    }

    /**
     * Determine whether a field has changed based on a given record and the old map from the trigger
     * @param sobj   SObject from a trigger
     * @param field  SObjectField to check
     * @param oldMap Previous data from the old records
     * @return       Boolean if the given field was changed
     */
    public static Boolean isFieldChanged(SObject sobj, SObjectField field, Map<Id,SObject> oldMap) {
        return oldMap.get(sobj.Id).get(field) != sobj.get(field);
    }
    /**
     * Given a list of SObjects, a field, and a value, return only the records
     * where the field value matches the input value
     * @param records List of SObject from Trigger.new or equivalent
     * @param field   SObjectField to compare values on
     * @param value   Data to compare with the data in the field
     * @return        Filtered list of SObjects
     */
    public static List<SObject> filterByFieldCriterium(List<SObject> records, SObjectField field, Object value) {
        final List<SObject> filteredList = new List<SObject>();

        for(SObject sobj : records) {
            if(sobj.get(field) == value) {
                filteredList.add(sobj);
            }
        }

        return filteredList;
    }

    /**
     * Given a field and value, filter all records that have that matching field and value
     * @param records List of SObject from Trigger.new or equivalent
     * @param field   SObjectField to compare values on
     * @param value   Data to filter on the field
     * @return        List of records that match the filter criteria
     */
    public static List<SObject> filterByFieldCriteria(List<SObject> records, SObjectField field, List<Object> value) {
        final List<SObject> filteredList = new List<SObject>();

        for(SObject sobj : records) {
            if(value.contains(sobj.get(field))) {
                filteredList.add(sobj);
            }
        }

        return filteredList;
    }

    /**
     * Given a map of fields to values, filter all records that have matching fields to values
     * @param records      List of SObject from Trigger.new or equivalent
     * @param fieldToValue Map of SObjectField to value
     * @return             List of records that match the filter criteria
     */
    public static List<SObject> filterByMapFieldToValue(List<SObject> records, Map<SObjectField,Object> fieldToValue) {
        final List<SObject> filteredList = new List<SObject>();

        for(SObject sobj : records) {
            Boolean include = fieldToValue.keySet().size() > 0;
            for(SObjectField field : fieldToValue.keySet()) {
                if(sobj.get(field) != fieldToValue.get(field)) {
                    include = false;
                    break;
                }
            }
            if(include) filteredList.add(sobj);
        }
        return filteredList;
    }

    /**
     * Given a list of records, filter records based on a list of fields changed
     * @param records         List of SObject from Trigger.new or equivalent
     * @param existingRecords Map of Id to SObject, from Trigger.oldMap or equivalent
     * @param fields          List of SObjectFields
     * @param matchAny        Boolean whether to match all parameter fields changed or any changed
     * @return                List of matching records
     */
    public static List<SObject> filterByFieldsChanged(
            List<SObject> records,
            Map<Id, SObject> existingRecords,
            List<SObjectField>fields,
            Boolean matchAny) {

        List<SObject> changedRecords = new List<SObject>();
        Boolean allFieldsFilter;
        for(SObject sobj : records) {
            allFieldsFilter = false;
            for(SObjectField field : fields) {
                allFieldsFilter = isFieldChanged(sobj,field,existingRecords);
                if(allFieldsFilter == matchAny) { break; }
            }
            if(allFieldsFilter) {
                changedRecords.add(sobj);
            }
        }
        return changedRecords;
    }

    /**
     * Given a list of SObjects, their corresponding "oldMap" values, and a field, return only the records where
     * the field value is different
     * @param   records         List of SObject from Trigger.new or equivalent
     * @param   existingRecords Map of Id to SObject, from Trigger.oldMap or equivalent
     * @param   field           SObjectField to compare values on
     * @return                  Filtered list of SObjects
     */
    public static List<SObject> filterByFieldChanged(List<SObject> records, Map<Id, SObject> existingRecords,
            SObjectField field) {

        return filterByFieldChangedInternal(records, existingRecords, field);
    }

    /**
     * Given a list of SObjects, their corresponding "oldMap" values, and a field, return only the records where
     * the field value is different
     * @param   records         List of SObject from Trigger.new or equivalent
     * @param   existingRecords Map of Id to SObject, from Trigger.oldMap or equivalent
     * @param   field           SObjectField to compare values on
     * @return                  Filtered list of SObjects
     */
    public static List<SObject> filterByFieldChanged(List<SObject> records, Map<Id, SObject> existingRecords,
            String field) {

        return filterByFieldChangedInternal(records, existingRecords, field);
    }

    private static List<SObject> filterByFieldChangedInternal(List<SObject> records, Map<Id, SObject> existingRecords,
            Object field) {

        final List<SObject> filteredList = new List<SObject>();

        SObject existing;
        for(SObject sobj : records) {
            existing = existingRecords.get(sobj.Id);

            if(isFieldChanged(sobj, existing, field)) {
                filteredList.add(sobj);
            }
        }

        return filteredList;
    }

    private static Boolean isFieldChanged(SObject sobj, SObject existing, Object field) {
        return TLShared.getFieldValue(sobj, field) != TLShared.getFieldValue(existing, field);
    }
}