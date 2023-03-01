@isTest
public with sharing class SObjectChildRecordsMockWrapper {
    Integer size = 0;
    Boolean done = true;
    List<SObject> records;
    public SObjectChildRecordsMockWrapper(list<Sobject> records){
        this.records = records;
        this.size = records.size();
    }
    public static Map<String, Object> addChildRecords(SObject parent, Map<String, List<SObject>> childObjectsMap){
        Map<String, Object> jsonMap = (Map<String,Object>) JSON.deserializeUntyped(JSON.serialize(parent));
        for(String relationshipName : childObjectsMap.keySet()){
            jsonMap.put(relationshipName, new SObjectChildRecordsMockWrapper(childObjectsMap.get(relationshipName)));
        }
        return jsonMap;
    }
}