/**
 * Utility methods for manipulating SObjects
 * @author Grant Adamson, Traction on Demand
 * @date 2017-08-01
 * @modified Jeremy Horan, Traction on Demand - 2018-11-07
 * @group TLSObj
 */
public class TLSObj {
    private static final String INVALID_RT_FOR_SOBJ_MSG = 'Invalid record type name "{0}" for SObject type "{1}"';

    /**
     * Given a source object, destination object, and a map of Destination to Source SObjectField, copy the values from
     * the source object to the destination. NOTE: Does not perform type checking; field types must be compatible
     * @param srcObj    Source SObject
     * @param destObj   Destination SObject
     * @param fieldMap  Map of SObjectField => SObjectField. SOURCE field is the key, DESTINATION field is the value
     */
    public static void copyUsingMapping(SObject srcObj, SObject destObj, Map<SObjectField, SObjectField> fieldMap) {
        SObjectField destField;
        for(SObjectField srcField : fieldMap.keySet()) {
            destField = fieldMap.get(srcField);

            destObj.put(destField, srcObj.get(srcField));
        }
    }

    /**
     * Given a source object, destination object, and a map of Destination to Source SObjectField, compare the values
     * from the source object to the destination.
     *
     * @param srcObj    Source SObject
     * @param destObj   Destination SObject
     * @param fieldMap  Map of SObjectField => SObjectField. SOURCE field is the key, DESTINATION field is the value
     *
     * @return  Returns TRUE if all fields match, otherwise FALSE
     */
    public static Boolean isEqualUsingMapping(SObject srcObj, SObject destObj,
            Map<SObjectField, SObjectField> fieldMap) {

        SObjectField destField;
        for(SObjectField srcField : fieldMap.keySet()) {
            destField = fieldMap.get(srcField);

            if(srcObj.get(srcField) != destObj.get(destField)) {
                return false;
            }
        }

        return true;
    }

    /**
     * Given an SObjectType and a Record Type name, return the Id corresponding to the record type
     * Invalid RT names will throw an exception
     * @param   sobjType    The SObject Type to retrieve the record type Id for
     * @param   rtName      The name of the Record Type
     * @return              The Id of the Record Type
     * @deprecated Use of getRecordTypeIdForDeveloperName is preferred
     */
    public static Id getRecordTypeIdForName(SObjectType sobjType, String rtName) {
        RecordTypeInfo rtInfo = sobjType.getDescribe().getRecordTypeInfosByName().get(rtName);

        if (rtInfo == null) {
            throw new TLSObjException(rtName, sobjType);
        }

        return rtInfo.getRecordTypeId();
    }

    /**
     * Given an SObjectType and a Record Type Developer name, return the Id corresponding to the record type
     * Invalid RT names will throw an exception
     * @param   sobjType    The SObject Type to retrieve the record type Id for
     * @param   rtName      The developer name of the Record Type
     * @return              The Id of the Record Type
     */
    public static Id getRecordTypeIdForDeveloperName(SObjectType sobjType, String developerName) {
        RecordTypeInfo rtInfo = sobjType.getDescribe().getRecordTypeInfosByDeveloperName().get(developerName);

        if (rtInfo == null) {
            throw new TLSObjException(developerName, sobjType);
        }

        return rtInfo.getRecordTypeId();
    }

    /**
     * @param source The source record
     * @param destination The destination record
     * @param sourceToDestinationMapping The [source field] to [destination field] map to copy from source to destination
     */
    public static void copyFieldValues(SObject source, SObject destination,
            Map<String, SObjectField> sourceToDestinationMapping) {

        for (String sourceField : sourceToDestinationMapping.keySet()) {
            destination.put(sourceToDestinationMapping.get(sourceField), TLShared.getFieldValue(source, sourceField));
        }
    }

    /**
	 * Get field value for the given record (works across parent relationships like Contact.Account.Name)
	 * @param obj The record
	 * @param field The field
	 * @return the field value or null if given field is invalid
	 */
    public static Object getFieldValue(SObject obj, String field) {
        if (obj == null) {
            return null;
        }

        return TLShared.getFieldValue(obj, field);
    }

    /**
     * Get the SObjectType value for the String name of an SObject. This uses the Type system rather than
     * getGlobalDescribe, which means it is MUCH faster
     *
     * @param name String value of an SObjectType
     *
     * @return SObjectType value that corresponds to the type name provided, or null if the name is not valid
     */
    public static SObjectType getSObjectTypeForName(String name) {
        try {
            return ((SObject)Type.forName(name).newInstance()).getSObjectType();
        } catch (Exception e) {
            return null;
        }
    }

    /**
     * Get the SObjectField value from an SObject + Field name combination
     *
     * @param sObjectType Type of object the field name is from
     * @param name Name of the field as a string
     *
     * @return SObjectField instance representing the field information provided
     */
    public static SObjectField getSObjectFieldForName(SObjectType sObjectType, String name) {
        return sObjectType.getDescribe().fields.getMap().get(name);
    }

    /**
     * Get the RecordTypeId from the provided SObject. If the SObject does not have record types, return null
     *
     * @param sobj SObject to parse
     *
     * @return Record Type Id, or null if the SObject does not have record types
     */
    public static Id getRecordTypeId(SObject sobj) {
        Id result;

        try {
            result = (Id)sobj.get('RecordTypeId');
        } catch (Exception e) { // Prevent exceptions if the SObject does not have record types
            return null;
        }

        return result;
    }

    private class TLSObjException extends Exception {

        private TLSObjException(String rtName, SObjectType sobjType) {
            setMessage(String.format(INVALID_RT_FOR_SOBJ_MSG, new String[]{ rtName, String.valueOf(sobjType) }));
        }
    }

}