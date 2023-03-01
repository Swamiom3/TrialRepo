/*************************************************************************************************************************************
    Author      :   Pawel Biszczak
    Description :   This class is providing testing utilities using Mocks
    --------------------------------------------------------------------------------------------------------------------------------------
    VERSION         DATE            AUTHOR            DETAIL
    1               7 Apr, 2021     Pawel Biszczak    Initial Deployment
**************************************************************************************************************************************/
@isTest
public with sharing class MockTestingUtility {

    public static List<SObject> getRecords(Map<String, Object> recordsData) {
        return getRecords(recordsData, false, new Map<String, String>());
    }

    public static List<SObject> getRecords(Map<String, Object> recordsData, Boolean isFakeIds) {
        return getRecords(recordsData, isFakeIds, new Map<String, String>());
    }

    public static List<SObject> getRecords(Map<String, Object> recordsData, Boolean isFakeIds, Map<String, String> fieldValues) {
        String objectName = String.valueOf(recordsData.get('objectName')).toLowerCase();
        Integer numberOfRecords = Integer.valueOf(recordsData.get('numberOfRecords'));
        SObjectFactory factory = new SObjectFactory(objectName);
        return factory.getFakeObjectList(numberOfRecords, fieldValues, isFakeIds);
    }


    public class SObjectFactory {
        String objectName;
        Integer fakeRecordNumber;

        public SObjectFactory(String objectName){
            this.objectName = objectName;
            this.fakeRecordNumber = 0;
        }

        public List<SObject> getFakeObjectList(Integer numberOfRecords, Map<String, String> fieldValues, Boolean isFakeIds) {
            if(numberOfRecords <= 0) {
                return new List<SObject>();
            }

            List<SObject> records = new List<SObject>();
            for(Integer i = 0; i < numberOfRecords; i++) {
                SObject recordElement = new SObjectBuilder(objectName, fakeRecordNumber++).
                        withFakeId(isFakeIds).
                        withFakeFieldValues(fieldValues).
                        getSObject();
                records.add(recordElement);
            }

            return records;
        }
    }

    public class SObjectBuilder {
        SObjectType objectType;
        SObject objectElement;
        Integer uniqueRecordNumber;

        public SObjectBuilder(String objectName){
            objectType = Schema.getGlobalDescribe().get(objectName);
            objectElement = objectType.newSObject();
        }

        public SObjectBuilder(String objectName, Integer uniqueRecordNumber){
            this(objectName);
            this.uniqueRecordNumber = uniqueRecordNumber;
        }

        public SObjectBuilder withFakeFieldValues(Map<String, String> fieldValues){
            if(fieldValues == null || fieldValues.isEmpty()) {
                return this;
            }
            for (String fieldName : fieldValues.keySet()) {
                putField(fieldName, fieldValues.get(fieldName) + uniqueRecordNumber);
            }
            return this;
        }

        public SObjectBuilder withFakeId(Boolean isFakeIds){
            if(!isFakeIds) {
                return this;
            }
            objectElement.Id = getFakeId();
            return this;
        }

        public String getFakeId(){
            String result = String.valueOf(uniqueRecordNumber);
            return objectType.getDescribe().getKeyPrefix() + '0'.repeat(12-result.length())
                    + result;
        }

        public void putField(String fieldName, String fieldValue){
            objectElement.put(fieldName, fieldValue);
        }

        public SObject getSObject(){
            return objectElement;
        }
    }
}