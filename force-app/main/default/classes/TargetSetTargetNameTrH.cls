/************************************************************************************************************************************
Author      :    Krishna Somwanshi
Description :    This trigger has logic to set Target Name Field.
History:
----------------------------------------------------------------------------------------------------------------------------------
VERSION    DATE            AUTHOR               Issue No      DETAIL
1          23 Sept 2021    Krishna Somwanshi    ST-9152       Refactor
**************************************************************************************************************************************/
public with sharing class TargetSetTargetNameTrH extends SObjectTriggerHandler {
    private List<Targets__c> newTargets;
    private Map<Id, Targets__c> oldTargetsMap;
    private Map<Id, String> targetRecordTypesWithNameMap = UtilRecordType.GetSobjectActiveRecordTypesByLabelNotLowerById('Targets__c');
    private Map<String, String> recordTypesNamesUsedInNamingMaps = getTargetRecordTypesForNaming();
    private Map<String, List<String>> recordTypeWithFieldsUsedForNamingMaps = getRecordTypeWithFieldsUsedForNaming();
    private static final Integer TARGET_NAME_LENGTH = 255; 
    private Set<String> parentObjectFields = new Set<String>{'region__c', 'period__c', 'building__c', 'account__c', 'user__c'};
    
    public TargetSetTargetNameTrH() {
        this(
            (List<Targets__c>) Trigger.new,
            (Map<Id, Targets__c>) Trigger.oldMap
        );
    }

    private TargetSetTargetNameTrH(List<Targets__c> newTargets, Map<Id, Targets__c> oldTargetsMap) {
        this.newTargets = newTargets;
        this.oldTargetsMap = oldTargetsMap;
    }
    
    public override void beforeInsert() {
        setTargetName();
    }

    public override void beforeUpdate() {
        setTargetName();
    }

    private void setTargetName() {
        Map<String, Set<Id>> parentObjectsNameToIds  =  new Map<String, Set<Id>>();
        Set<Id> targetIdsToUpdateName = new Set<Id>();
        Map<Id, String> parentRecordIdToName= new Map<Id, String>();
        Boolean isUpdate = trigger.isUpdate;
        filterTargetRecordsToUpdateName(newTargets, oldTargetsMap, targetIdsToUpdateName, parentObjectsNameToIds);
        if((isUpdate == true) || ((isUpdate != true) && targetIdsToUpdateName != null)) {
            parentRecordIdToName = createMapTargetRelatedObjects(parentObjectsNameToIds);
            setTargetsNamingConvention(newTargets, oldTargetsMap, targetIdsToUpdateName, parentRecordIdToName);
        }
    }
    private void filterTargetRecordsToUpdateName(List<Targets__c> newTargets, Map<Id, Targets__c> oldTargetsMap, 
                                                 Set<Id> targetIdsToUpdateName, Map<String, Set<Id>> parentObjectsNameToIds) {
        for(Targets__c target : newTargets) {
            Boolean isTargetNamingRelatedFieldUpdated = false;
            Targets__c oldTarget = oldTargetsMap?.get(target.Id);
            List<String> relatedFieldOfRecordType = recordTypeWithFieldsUsedForNamingMaps.get(
                                                    targetRecordTypesWithNameMap.get(target.RecordTypeId));
            if(relatedFieldOfRecordType.isEmpty()){
                continue;
            }
            if(oldTarget != null){
                isTargetNamingRelatedFieldUpdated = isNamingRelatedFieldUpdated(target, oldTarget, relatedFieldOfRecordType);
                if(isTargetNamingRelatedFieldUpdated){
                    targetIdsToUpdateName.add(target.Id);
                }
            }
            
            if(oldTarget == null || isTargetNamingRelatedFieldUpdated){
                populateMapParentObjectsNameToIds( target, relatedFieldOfRecordType, parentObjectsNameToIds);
            }
        }
    }
    
    private Boolean isNamingRelatedFieldUpdated(Targets__c newTarget, Targets__c oldTarget, List<String> relatedFieldOfRecordType) {
        if(relatedFieldOfRecordType == null && relatedFieldOfRecordType.isEmpty()) {
            return false;
        }else {
            for(String field : relatedFieldOfRecordType) {
                if(TriggerUtility.isFieldValueChanged(newTarget, oldTarget, field)) {
                    return true;
                } 
            }
        }
        return false;
    }
    
    private void populateMapParentObjectsNameToIds(Targets__c target, List<String> relatedFieldOfRecordType, 
                                                   Map<String, Set<Id>> parentObjectsNameToIds) {
        for(String fieldName : relatedFieldOfRecordType) {
            if(fieldName == 'segment__c') {
                continue;
            }
            if(parentObjectsNameToIds.get(fieldName) != null) {
                parentObjectsNameToIds.get(fieldName).add(String.valueOf(target.get(fieldName)));
            }else {
                parentObjectsNameToIds.put(fieldName, new Set<Id>{String.valueOf(target.get(fieldName))}); 
            }
        }
    }

    private Map<Id, String> createMapTargetRelatedObjects(Map<String, Set<Id>> parentObjectsNameToIds) {
        if(parentObjectsNameToIds.isEmpty()) {
            return null;
        }
        Map<Id, String> parentRecordIdToName = new Map<Id, String>();
        List<sObject> targetParents = getTargetParentObjects(parentObjectsNameToIds); 
        for(sObject objsObject : targetParents) {
            parentRecordIdToName.put(String.valueOf(objsObject.get('Id')), String.valueOf(objsObject.get('Name')));
        }
        return parentRecordIdToName;
    }

    private List<sObject> getTargetParentObjects(Map<String, Set<Id>> parentObjectsNameToIds){
        List<sObject> targetParents = new List<sObject>(); 
        targetParents.addAll(getObjectData(parentObjectsNameToIds.get('building__c'), 'building__c'));
        targetParents.addAll(getObjectData(parentObjectsNameToIds.get('region__c'), 'region__c'));
        targetParents.addAll(getObjectData(parentObjectsNameToIds.get('period__c'), 'period__c'));
        targetParents.addAll(getObjectData(parentObjectsNameToIds.get('user__c'), 'user'));
        targetParents.addAll(getObjectData(parentObjectsNameToIds.get('account__c'), 'account'));
        return targetParents;
    }
    
    private List<sObject> getObjectData(Set<Id> setObjectIds, String objectName){
        if(setObjectIds == null || setObjectIds.isEmpty()){
            return new List<sObject>();
        }
        return Database.query('SELECT Id, Name FROM '+ objectName + ' WHERE Id IN:setObjectIds');
    }
   
    private void setTargetsNamingConvention(List<Targets__c> newTargets, Map<Id, sObject> oldTargetsMap, 
                                            Set<Id> targetIdsToUpdateName, Map<Id, String> parentRecordIdToName) {                                         
        for(Targets__c target : newTargets) {
            Targets__c oldtarget = (Targets__c)oldTargetsMap?.get(target.Id);
            if(oldtarget != null && !targetIdsToUpdateName.contains(target.Id)){
                continue;
            }
            String targetName = '';
            String recordType = targetRecordTypesWithNameMap.get(target.RecordTypeId);
            if(recordType != 'Building Goals') {
                targetName += recordTypesNamesUsedInNamingMaps.get(recordType) +'-';
            }
            targetName = getNameByConcatenatingFields(recordType, targetName, target, parentRecordIdToName);
            targetName = targetName.removeEnd('-');
            if(targetName.length() > TARGET_NAME_LENGTH) {
                targetName = targetName.substring(0, TARGET_NAME_LENGTH);
            }
            target.Target_Name__c = targetName;  
         }
    }
    
    private String getNameByConcatenatingFields(String recordType, String targetName, Targets__c target, 
                                                Map<Id, String> parentRecordIdToName) {
        List<String> relatedFieldOfRecordType = recordTypeWithFieldsUsedForNamingMaps.get(
                                                targetRecordTypesWithNameMap.get(target.RecordTypeId));
        for(String field : relatedFieldOfRecordType) {
            if(parentObjectFields.contains(field)) {
                String referenceRecordName = parentRecordIdToName.get(String.valueOf(target.get(field)));  
                if(String.isNotBlank(referenceRecordName)) {
                    targetName += referenceRecordName+'-';
                }
            }else {
                targetName = concatenateFieldsInName(recordType, field, targetName, target);
            }
        }
        return targetName; 
    }
    
    private String concatenateFieldsInName(String recordType, String field, String targetName, Targets__c target) {
        if(recordType == 'Global Sales Forecast' && field == 'segment__c') {
            targetName += concatenateSegmentForGSFRecordType(field, targetName, target);
        }else {
            targetName += getStringValue(target.get(field)) + '-';
        }
        return targetName;
    }
    
    private String concatenateSegmentForGSFRecordType(String field, String targetName, Targets__c target) {
        return (target.get(field) != null ? getStringValue(target.get(field))+'-':'NA-'); 
    }
    
    private static String getStringValue(Object objectData){
        if(objectData != null){
            return String.valueOf(objectData);
        }
        return null;
    }
   
    // As suggested by Maciej Milosz in PR #4130 we have hardcoded in this class (instead of metadata)
    private Map<String, List<String>> getRecordTypeWithFieldsUsedForNaming(){
        Map<String, List<String>> recordTypeWithFieldsUsedForNamingMaps = new Map<String, List<String>>();
        recordTypeWithFieldsUsedForNamingMaps.put('Regional Sales Goals', new List<String>{'region__c', 'period__c'});
        recordTypeWithFieldsUsedForNamingMaps.put('Building Goals', new List<String>{'building__c', 'segment__c', 'period__c'});
        recordTypeWithFieldsUsedForNamingMaps.put('Rep Goals', new List<String>{'user__c', 'period__c'});
        recordTypeWithFieldsUsedForNamingMaps.put('Global Sales Forecast', new List<String>{'region__c', 'segment__c', 'period__c'});
        recordTypeWithFieldsUsedForNamingMaps.put('Global Sales Goal', new List<String>{'period__c'});
        recordTypeWithFieldsUsedForNamingMaps.put('Account Goals', new List<String>{'account__c', 'period__c'});
        return recordTypeWithFieldsUsedForNamingMaps;
    }
    
    private Map<String, String> getTargetRecordTypesForNaming(){
        Map<String, String> recordTypesNamesUsedInNamingMaps = new Map<String, String>();
        recordTypesNamesUsedInNamingMaps.put('Regional Sales Goals', 'Regional Sales Goal');
        recordTypesNamesUsedInNamingMaps.put('Rep Goals', 'Rep Goal');
        recordTypesNamesUsedInNamingMaps.put('Global Sales Forecast', 'Global Sales Forecast');
        recordTypesNamesUsedInNamingMaps.put('Global Sales Goal', 'Global Sales Goal');
        recordTypesNamesUsedInNamingMaps.put('Account Goals', 'Account Goal');
        return recordTypesNamesUsedInNamingMaps;     
    }
}