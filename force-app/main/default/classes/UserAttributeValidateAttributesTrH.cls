/**********************************************************************************************************
    Author        :  Ashish Sharma
    Description   :  This trigger validates the User Attributes.
    Issue No.     :  ST-7390
    History       :
-----------------------------------------------------------------------------------------------------------
    VERSION        DATE          AUTHOR           DETAIL
      1         15-Jan-2021    Ashish Sharma      Refactor and move to new framework
**********************************************************************************************************/
public with sharing class UserAttributeValidateAttributesTrH extends SObjectTriggerHandler {
    @TestVisible
    private List<User_Attribute__c> newUserAttributes;
    @TestVisible
    private Map<Id, User_Attribute__c> newUserAttributesMap;
    @TestVisible
    private Map<Id, User_Attribute__c> oldUserAttributesMap;
    private Boolean isUpdate;
    private final static Id USER_HISTORY_ID = (Id) WeworkEngine.getObjectRecordTypeId('User_Attribute__c', 'User History');
    private final static Set<String> FIELDS_CHANGED = new Set<String>{'As_of_Date__c', 'End_Date__c', 'User__c'};
    
    public UserAttributeValidateAttributesTrH() {
        this((List<User_Attribute__c>) Trigger.new, 
             (Map<Id, User_Attribute__c>) Trigger.newMap, 
             (Map<Id, User_Attribute__c>) Trigger.oldMap);
    }
    
    @TestVisible
    private UserAttributeValidateAttributesTrH(List<User_Attribute__c> newUserAttributes, 
                                               Map<Id, User_Attribute__c> newUserAttributesMap,
                                               Map<Id, User_Attribute__c> oldUserAttributesMap) {
        this.newUserAttributes = newUserAttributes;
        this.newUserAttributesMap = newUserAttributesMap;
        this.oldUserAttributesMap = oldUserAttributesMap;
        isUpdate = (context == TriggerContext.BEFORE_UPDATE);
    }
    
    public override void beforeInsert() {
        validateAttributes();
    }
    
    public override void beforeUpdate() {
        validateAttributes();
    }
    
    private void validateAttributes() {
        List<User_Attribute__c> validAttributes = new List<User_Attribute__c>();
        Map<Id, List<User_Attribute__c>> userToUAs = new Map<Id, List<User_Attribute__c>>();
        Set<Id> userIds = new Set<Id>();        
        for (User_Attribute__c newUA : newUserAttributes) {
            User_Attribute__c oldUA = oldUserAttributesMap?.get(newUA.Id);
            if (oldUA != null && !TriggerUtility.isFieldsValueChanged(newUA, oldUA, FIELDS_CHANGED)) {
                continue;
            }
            if (newUA.User__c == null) {
                newUA.addError(Label.User_Att_User_Required);
                continue;
            } else if (newUA.As_of_Date__c == null) {
               newUA.addError(Label.User_Att_As_of_Date);
                continue;
            } else if (newUA.As_of_Date__c > System.today()) {
                newUA.addError(Label.User_Att_As_of_Date_Future);
                continue;
            }
            validAttributes.add(newUA);
            userIds.add(newUA.User__c);
            checkOverlaps(newUA, userToUAs.get(newUA.User__c));
            TriggerUtility.addSobjectValuesToMap('User__c', userToUAs, newUA);            
        }
        if (!validAttributes.isEmpty()) {
            identifyOverlapsForValidUAs(validAttributes, userIds);
        }
    }
    
    private void identifyOverlapsForValidUAs(List<User_Attribute__c> userAttributes, Set<Id> userIds) {
        Map<Id, List<User_Attribute__c>> userToUAs = new Map<Id, List<User_Attribute__c>>();
        for (User_Attribute__c userAttr : getUserAttributes(userIds)) {
            User_Attribute__c uaInNewMap = newUserAttributesMap?.get(userAttr.Id);
            TriggerUtility.addSobjectValuesToMap('User__c', userToUAs, uaInNewMap != null ? uaInNewMap : userAttr);
        }
        
        for (User_Attribute__c newUA : userAttributes) {
            if (UserUtility.getUserActive(newUA.User__c)) {
                newUA.User_Name__c = UserUtility.getUserById(newUA.User__c).Name;
            }
            if (newUA.RecordTypeId != USER_HISTORY_ID) {
                continue;
            }
            checkOverlaps(newUA, userToUAs.get(newUA.User__c));
        }
    }
    
    private void checkOverlaps(User_Attribute__c newUA, List<User_Attribute__c> userAttributes) {
        if (userAttributes == null || userAttributes.isEmpty()) {
           return;
        }
        for (User_Attribute__c userAttr : userAttributes) {
            if (isUpdate && newUA.Id == userAttr.Id) {
                continue;
            }
            if (isAsOfDateOverlapping(newUA, userAttr) || isAsOfDateBeforeOtherAttrDates(newUA, userAttr)
                    || isEndDateOverlapping(newUA, userAttr)) {                     
                newUA.addError(Label.User_Att_Overlap + ' Override record Id is = ' + userAttr.Id);
            }
        }
    }
    
    private List<User_Attribute__c> getUserAttributes(Set<Id> userIds) {
        return [SELECT Id, As_of_Date__c, End_Date__c, User__c, RecordTypeId
                FROM User_Attribute__c
                WHERE User__c IN :userIds AND RecordTypeId =: USER_HISTORY_ID 
                ORDER BY As_of_Date__c, End_Date__c DESC];
    }
    
    private Boolean isAsOfDateOverlapping(User_Attribute__c newUA, User_Attribute__c userAttr) {
        return newUA.As_of_Date__c >= userAttr.As_of_Date__c 
                   && (userAttr.End_Date__c == null || newUA.As_of_Date__c <= userAttr.End_Date__c);
    }
    
    private Boolean isEndDateOverlapping(User_Attribute__c newUA, User_Attribute__c userAttr) {
        return newUA.End_Date__c != null &&  newUA.End_Date__c >= userAttr.As_of_Date__c
                   && (userAttr.End_Date__c == null || newUA.End_Date__c <= userAttr.End_Date__c);
    }
    
    private Boolean isAsOfDateBeforeOtherAttrDates(User_Attribute__c newUA, User_Attribute__c userAttr) {
        return newUA.As_of_Date__c <= userAttr.As_of_Date__c 
                   && (newUA.End_Date__c == null || userAttr.As_of_Date__c <= newUA.End_Date__c);
    }
}