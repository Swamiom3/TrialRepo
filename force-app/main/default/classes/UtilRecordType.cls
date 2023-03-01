/*************************************************************************************************************************************
    Author      :   Rashad Saeed
    Description :   RecordType Utility for testing and general functions
    --------------------------------------------------------------------------------------------------------------------------------------
    VERSION    DATE            AUTHOR            DETAIL
    1          18 Sep, 2018    Rashad Saeed      Initial Deployment
    2          16 Dec, 2012    Pawel Biszczak    Refactor
**************************************************************************************************************************************/
public class UtilRecordType {
    private static Map<String, Map<String, Id>> recordTypeIdsByNamesToObjectsMap = new Map <String, Map<String, Id>>();
    private static Map<String, Map<Id, String>> recordTypeNamesByIdsToObjectsMap = new Map <String, Map<Id, String>>();
    private static Map<String, Map<String, Id>> recordTypeIdsByNamesNotLowerToObjectsMap = new Map <String, Map<String, Id>>();
    private static Map<String, Map<Id, String>> recordLabelsByIdsToObjectsMap = new Map <String, Map<Id, String>>();
    private static Map<String, Map<Id, String>> allRecordTypesDespiteVisibilityByIdsToObjectsMap = new Map <String, Map<Id, String>>();

    public static Map<String, Id> getSobjectActiveRecordTypes(String objectName) {
        manageRTsMaps(objectName);
        return recordTypeIdsByNamesToObjectsMap.get(objectName.toLowerCase()); 
    }

    public static Map<Id, String> getSobjectActiveRecordTypesById(String objectName) {
        manageRTsMaps(objectName);
        return recordTypeNamesByIdsToObjectsMap.get(objectName.toLowerCase());
    }
    
    public static Map<String, Id> getSobjectActiveRecordTypesByLabelNotLower(String objectName) {
        manageRTsMaps(objectName);
        return recordTypeIdsByNamesNotLowerToObjectsMap.get(objectName.toLowerCase());
    }
    
    public static Map<Id, String> getSobjectActiveRecordTypesByLabelNotLowerById(String objectName) {
        manageRTsMaps(objectName);
        return recordLabelsByIdsToObjectsMap.get(objectName.toLowerCase());
    }
    
    private static void manageRTsMaps(String objectName) {
        if(!recordTypeIdsByNamesToObjectsMap.containsKey(objectName.toLowerCase())) {
            addToMaps(objectName);
        }
    }

    public static Map<Id, String> getSobjectAllExistingRecordTypesById(String objectName) {
        manageRTsMaps(objectName);
        return allRecordTypesDespiteVisibilityByIdsToObjectsMap.get(objectName.toLowerCase());
    }

    private static void addToMaps(String objectName) {
        if(allRecordTypesDespiteVisibilityByIdsToObjectsMap.containsKey(objectName.toLowerCase())
           || Schema.getGlobalDescribe().get(objectName) == null) {
            return;
        }
        Schema.DescribeSObjectResult sobjectResult = Schema.getGlobalDescribe().get(objectName).getDescribe();
        List<Schema.RecordTypeInfo> recordTypeInfo = sobjectResult.getRecordTypeInfos();
        Map<String, Id> mapRecordTypeNameId = new Map<String, Id>();
        Map<Id, String> mapRecordTypeIdName = new Map<Id, String>();
        Map<String, Id> mapRecordTypeLabelId = new Map<String, Id>();
        Map<Id, String> mapRecordTypeIdLabel = new Map<Id, String>();
        Map<Id, String> mapRecordTypeToAllExistingIdName = new Map<Id, String>();

        for(Schema.RecordTypeInfo info : recordTypeInfo){
            mapRecordTypeToAllExistingIdName.put(info.getRecordTypeId(), info.getDeveloperName().toLowerCase());
            if (!info.isAvailable() || info.isMaster()) {
                continue;
            }
            mapRecordTypeNameId.put(info.getDeveloperName().toLowerCase(), info.getRecordTypeId());
            mapRecordTypeIdName.put(info.getRecordTypeId(), info.getDeveloperName().toLowerCase());
            mapRecordTypeLabelId.put(info.getName(), info.getRecordTypeId());
            mapRecordTypeIdLabel.put(info.getRecordTypeId(), info.getName());
        }

        recordTypeIdsByNamesToObjectsMap.put(objectName.toLowerCase(), mapRecordTypeNameId);
        recordTypeNamesByIdsToObjectsMap.put(objectName.toLowerCase(), mapRecordTypeIdName);
        recordTypeIdsByNamesNotLowerToObjectsMap.put(objectName.toLowerCase(), mapRecordTypeLabelId);
        recordLabelsByIdsToObjectsMap.put(objectName.toLowerCase(), mapRecordTypeIdLabel);
        allRecordTypesDespiteVisibilityByIdsToObjectsMap.put(objectName.toLowerCase(), mapRecordTypeToAllExistingIdName);
    }
}