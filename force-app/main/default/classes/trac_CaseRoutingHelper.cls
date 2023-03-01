/**
 * @description helper io methods for the trac_CaseRouting class
 * @name trac_CaseRoutingHelper
 * @author Daniel Labonte, Traction on Demand
 * @date 2019-09-02
 */

public with sharing class trac_CaseRoutingHelper {
    public static final Map<String,SObjectField> CASE_FIELDS = Schema.SObjectType.Case.fields.getMap();


    /**
     * @description creates a map of routing models used to the case field that determines the id of the locations used for routing
     * @return map of routing model to case field
     */
    public static Map<String,String> createRoutingFieldMap() {
        List<Location_Queue_Type__mdt> queueTypes =  [SELECT Location_Record_Type__c, Case_Location_Id__c FROM Location_Queue_Type__mdt];
        Map<String,String> resultMap = new Map<String, String>();
        for(Location_Queue_Type__mdt queueType : queueTypes) {
            resultMap.put(queueType.Location_Record_Type__c,queueType.Case_Location_Id__c.toLowerCase());
        }
        return resultMap;
    }


    /**
     * @description creates a set of strings of all fields required to check for the routing rules in the system
     * @param isInsert boolean to get rules that run on trigger insert context
     * @return set of fields
     */
    public static Set<String> getRoutingField() {
        List<Case_Routing_Line_Item__mdt> routingCriteria = [
                SELECT Field__c, Value__c, Case_Routing__r.Run_On_Escalate__c
                FROM Case_Routing_Line_Item__mdt
                WHERE Is_Active__c = TRUE
                AND Case_Routing__r.Is_Active__c = TRUE];
        Set<String> allFields = TLList.collectStrings(routingCriteria,'Field__c');
        return TLList.toLowerCaseSet(allFields);
    }


    /**
     * @description converts a relationship field to the correct sobject type name
     * @param field relationship field
     * @return name of the sobject type
     */
    public static String getSObectFromField(String field) {
        String fieldName = relationshipToField(field);
        //TODO some fields such as OnwerId can be multple sobjects currently just getting first sobject
        Schema.SObjectType sobjectType = CASE_FIELDS.get(fieldName).getDescribe().getReferenceTo()[0];
        return String.valueOf(sobjectType);
    }


    public static String relationshipToField(String relationship) {
        return !relationship.contains('__r') ? relationship + 'Id' : relationship.replace('__r', '__c');
    }



    /**
     * @description in a map, finds the key of the matched value
     * @param inputMap string to string map
     * @param value value to match in the maps values
     * @return key of the matched value
     */
    public static String find(Map<String,String> inputMap, String value) {
        for(String obj : inputMap.keySet()) {
            if(inputMap.get(obj) == value) {
                return obj;
            }
        } return null;
    }


    /**
     * @description converts a case record into a map of field to value. Additional fields can be added in.
     * @param cs case record
     * @param additionalFields map of field to value
     * @return map of the case fields to values
     */
    public static Map<String,String> mockRecord(Case cs, Map<String, String> additionalFields) {
        Map<String, Object> queriedFieldValues = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(cs));
        Map<String, String> mockedRecord = mockField('', queriedFieldValues);
        for (String key : additionalFields.keySet()) {
            mockedRecord.put(key.toLowerCase(), additionalFields.get(key));
        }
        return mockedRecord;
    }


    /**
     * @description builds the fields for the mocked case record as a map of string field to string value
     * @param relatedField name of the field or relationship
     * @param queriedFieldValues the value in the field
     * @return map of the field or relationship to value
     */
    public static Map<String, String> mockField(String relatedField, Map<String, Object> queriedFieldValues) {
        Map<String, String> returnMap = new Map<String, String>();
        for (String queriedFieldName : queriedFieldValues.keySet()) {
            Object queriedFieldValue = queriedFieldValues.get(queriedFieldName);
            if(queriedFieldValue instanceof Map<String, Object>) {
                mockField(queriedFieldName + '.', (Map<String, Object>) queriedFieldValue);
            } else {
                returnMap.put(relatedField.toLowerCase() + queriedFieldName.toLowerCase(), String.valueOf(queriedFieldValue));
            }
        }
        return returnMap;
    }


    /**
     * @description sorts a map based of value
     * @param inMap map to be sorted
     * @return sorted map
     */
    public static List<String> orderListByMapValues(Map<String,Integer> inMap) {
        Map<Integer , List<String>>  reverseMap =  new Map<Integer , List<String>>();

        List<String> tempList = new List<String>();
        for(String k : inMap.keySet()) {
            if(reverseMap.containsKey(inMap.get(k))) {
                tempList = reverseMap.get(inMap.get(k));
            } else {
                tempList = new List<String>();
            }
            tempList.add(k);
            reverseMap.put(inMap.get(k) , tempList);
        }

        List<String> aList = new List<String>();
        aList.addAll(inMap.keySet());
        List<Integer> value= new List<Integer>();
        for(String s : aList) {
            value.add(inMap.get(s));
        }
        value.sort();

        List<Integer> descValue = new List<Integer>();
        for(Integer i=value.size()-1; i>=0;i--) {
            descValue.add(value.get(i));
        }

        List<String> sortedKeys = new List<String>();
        for(Integer d : descValue) {
            sortedKeys.addAll(reverseMap.get(d));
        }

        return sortedKeys;
    }
}