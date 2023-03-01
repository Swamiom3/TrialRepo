/**********************************************************************************************************
    Author        :  Ashish Sharma
    Description   :  This trigger updates the Gap field.
    Issue No.     :  ST-7390
    History       :
-----------------------------------------------------------------------------------------------------------
    VERSION        DATE          AUTHOR           DETAIL
      1         15-Jan-2021    Ashish Sharma      Refactor and move to new framework
**********************************************************************************************************/
public with sharing class UserAttributeUpdateGapFieldTrH extends SObjectTriggerHandler {
    @TestVisible
    private List<User_Attribute__c> newUserAttributes;
    @TestVisible
    private Map<Id, User_Attribute__c> newUserAttributesMap;
    @TestVisible
    private Map<Id, User_Attribute__c> oldUserAttributesMap;
    private Boolean isUpdate;
    private final static Id USER_HISTORY_ID = (Id) WeworkEngine.getObjectRecordTypeId('User_Attribute__c', 'User History');
    private final static Set<String> FIELDS_CHANGED = new Set<String>{'As_of_Date__c', 'End_Date__c'};
    
    public UserAttributeUpdateGapFieldTrH() {
        this((List<User_Attribute__c>) Trigger.new, 
             (Map<Id, User_Attribute__c>) Trigger.newMap, 
             (Map<Id, User_Attribute__c>) Trigger.oldMap);
    }
    
    @TestVisible
    private UserAttributeUpdateGapFieldTrH(List<User_Attribute__c> newUserAttributes, 
                                           Map<Id, User_Attribute__c> newUserAttributesMap, 
                                           Map<Id, User_Attribute__c> oldUserAttributesMap) {
        this.newUserAttributes = newUserAttributes;
        this.newUserAttributesMap = newUserAttributesMap;
        this.oldUserAttributesMap = oldUserAttributesMap;
        isUpdate = (context == TriggerContext.BEFORE_UPDATE);
    }
    
    public override void beforeInsert() {
        updateGapFlag();
    }
    
    public override void beforeUpdate() {
        updateGapFlag();
    }
    
    private void updateGapFlag() {
        Set<Id> userIds = new Set<Id>();
        Map<Id, List<User_Attribute__c>> userToUAs;
        Map<Id, List<User_Attribute__c>> newUserToUAs = new Map<Id, List<User_Attribute__c>>();
        for (User_Attribute__c newUA : newUserAttributes) {
            User_Attribute__c oldUA = oldUserAttributesMap?.get(newUA.Id);
            if (oldUA != null && !TriggerUtility.isFieldsValueChanged(newUA, oldUA, FIELDS_CHANGED)) {
                continue;
            }
            userIds.add(newUA.User__c);
            setGapField(newUA, newUserToUAs.get(newUA.User__c));
            TriggerUtility.addSobjectValuesToMap('User__c', newUserToUAs, newUA);            
        }
        
        if (userIds.isEmpty()) {
            return; 
        }
        
        userToUAs = getUserToUAsMap(userIds);        
        if(userToUAs.isEmpty()) {
            return;
        }
        
        for (User_Attribute__c newUA : newUserAttributes) {
            setGapField(newUA, userToUAs.get(newUA.User__c));
        }
    }
    
    private Map<Id, List<User_Attribute__c>> getUserToUAsMap(Set<Id> userIds) {
        Map<Id, List<User_Attribute__c>> userToUAs = new Map<Id, List<User_Attribute__c>>();
        for (User_Attribute__c userAttr : getUserAttributes(userIds)) {
            User_Attribute__c uaInNewMap = newUserAttributesMap?.get(userAttr.Id);
            TriggerUtility.addSobjectValuesToMap('User__c', userToUAs, uaInNewMap != null ? uaInNewMap : userAttr);
        }
        return userToUAs;
    }
    
    private List<User_Attribute__c> getUserAttributes(Set<Id> userIds) {
        return [SELECT Id, As_of_Date__c, End_Date__c, User__c, RecordTypeId, Gap__c
                FROM User_Attribute__c 
                WHERE User__c IN :userIds AND RecordTypeId =: USER_HISTORY_ID 
                ORDER BY As_of_Date__c, End_Date__c DESC];
    }
    
    private void setGapField(User_Attribute__c newUA, List<User_Attribute__c> attributes) {
        if (attributes == null || attributes.isEmpty()) {
            return;
        }
        newUA.Gap__c = true;
        for (User_Attribute__c userAttrOther : attributes) {
            if (isUpdate && userAttrOther.Id == newUA.Id) {
                continue;
            }
            if (isAfterGapPresent(newUA, userAttrOther) && isBeforeGapPresent(newUA, userAttrOther)) {
                newUA.Gap__c = false;
                break;
            }
        }
    }
    
    private Boolean isAfterGapPresent(User_Attribute__c newUA, User_Attribute__c userAttrOther) {
        return newUA.End_Date__c >= System.today() || newUA.End_Date__c == null 
                   || (newUA.End_Date__c != null && newUA.End_Date__c + 1 == userAttrOther.As_of_Date__c);
    }
    
    private Boolean isBeforeGapPresent(User_Attribute__c newUA, User_Attribute__c userAttrOther) {
        return newUA.As_of_Date__c != null && newUA.As_of_Date__c - 1 == userAttrOther.End_Date__c;
    }
}