/************************************************************************************************************************************
    Author 		: 	Jitesh Adwani
    Description : 	This Class contains Utility Methods which will be used in Triggers
    History		:
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION		DATE				AUTHOR					DETAIL
    1			29 June 2020 		Jitesh Adwani  	        Initial Development	 
**************************************************************************************************************************************/
public with sharing class TriggerUtility {

    public static Boolean isFieldValueChanged(SObject newObject, SObject oldObject, String fieldAPIName){
        return isFieldsValueChanged(newObject, oldObject, new Set<String>{fieldAPIName});
    }

    public static Boolean isFieldsValueChanged(SObject newObject, SObject oldSobject, Set<String> fieldAPINames){
        for (String fieldAPIName : fieldAPINames) {
            if (newObject.get(fieldAPIName) != oldSobject.get(fieldAPIName)) {
               return true; 
            }
        } 
        return false;
    }

    public static void addSobjectValuesToMap(String keyField, Map<Id, List<SObject>> mapValues, SObject record) {
        Id key = (Id) record?.get(keyField);
        if(key == null) {
            return;
        }
        if(mapValues.containsKey(key)) {
            mapValues.get(key).add(record);
        } else {
            mapValues.put(key, new List<SObject>{record});
        }
    }


    public static Boolean isFieldsValueChangedOrNull(SObject newObject, SObject oldSobject, Set<String> fieldAPINames){
        for (String fieldAPIName : fieldAPINames) {
            if (newObject.get(fieldAPIName) != oldSobject.get(fieldAPIName) || newObject.get(fieldAPIName) == null) {
               return true; 
            }
        } 
        return false;
    }

    public static Boolean isFieldsValueNotNullAndChanged(SObject newObject, SObject oldSobject, Set<String> fieldAPINames){
        for (String fieldAPIName : fieldAPINames) {
            if (oldSobject.get(fieldAPIName) != null
                && oldSobject.get(fieldAPIName) != newObject.get(fieldAPIName)) {
                return true;
            }
        }
        return false;
    }
}