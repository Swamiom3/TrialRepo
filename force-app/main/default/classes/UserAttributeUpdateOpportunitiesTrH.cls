/**********************************************************************************************************
    Author        :  Ashish Sharma
    Description   :  This trigger updates the related Opportunities.
    Issue No.     :  ST-7390
    History       :
-----------------------------------------------------------------------------------------------------------
    VERSION        DATE          AUTHOR           DETAIL
      1         15-Jan-2021    Ashish Sharma      Refactor and move to new framework
**********************************************************************************************************/
public with sharing class UserAttributeUpdateOpportunitiesTrH extends SObjectTriggerHandler {
    @TestVisible
    private List<User_Attribute__c> newUserAttributes;
    @TestVisible
    private Map<Id, User_Attribute__c> oldUserAttributesMap;
    private final static Id USER_HISTORY_ID = (Id) WeworkEngine.getObjectRecordTypeId('User_Attribute__c', 'User History');
    private final static Set<String> FIELDS_CHANGED = new Set<String>{'As_of_Date__c', 'End_Date__c'};
    
    public UserAttributeUpdateOpportunitiesTrH() {
        this((List<User_Attribute__c>) Trigger.new, (Map<Id, User_Attribute__c>) Trigger.oldMap);
    }
    
    @TestVisible
    private UserAttributeUpdateOpportunitiesTrH(List<User_Attribute__c> newUserAttributes, Map<Id, User_Attribute__c> oldUserAttributesMap) {
        this.newUserAttributes = newUserAttributes;
        this.oldUserAttributesMap = oldUserAttributesMap;
    }
	
    public override void afterInsert() {
        updateOpportunity();
    }
    
    public override void afterUpdate() {
        updateOpportunity();
    }
    
    private void updateOpportunity() {
        Set<Id> userIds = new Set<Id>();
        List<Opportunity> oppsToUpdate;
        Map<Id, List<User_Attribute__c>> userToUAs;
        for (User_Attribute__c newUA : newUserAttributes) {
            User_Attribute__c oldUA = oldUserAttributesMap?.get(newUA.Id);
            if(oldUA != null && !TriggerUtility.isFieldsValueChanged(newUA, oldUA, FIELDS_CHANGED)) {
                continue;
            }
            userIds.add(newUA.User__C);
        }

        if (userIds.isEmpty()) {
            return;
        }
        
        userToUAs = new Map<Id, List<User_Attribute__c>>();        
        for (User_Attribute__c userAttr : getUserAttributes(userIds)) {
            TriggerUtility.addSobjectValuesToMap('User__c', userToUAs, userAttr);
        }
		
        if(userToUAs.isEmpty()) {
            return;    
        }
        
        oppsToUpdate = new List<Opportunity>();
        for (Opportunity opp: [SELECT Id, Owner_Assigned_Date__c, User_Attribute__c, OwnerId 
                               FROM Opportunity
                               WHERE OwnerId IN :userIds AND Owner_Assigned_Date__c != null]) {
            for (User_Attribute__c userAttr: userToUAs.get(opp.OwnerId)) {
                if (opp.Owner_Assigned_Date__c >= userAttr.As_of_Date__c
                        && (userAttr.End_Date__c == null || opp.Owner_Assigned_Date__c <= userAttr.End_Date__c)) {
                    opp.User_Attribute__c = userAttr.Id;
                    oppsToUpdate.add(opp);
                    break;
                }
            }
        }
        if (oppsToUpdate.isEmpty()) {
            return;
        }
        if (oppsToUpdate.size() > 10) {
            MetadataSetting__mdt setting = Settings.getMetadataSettingByDevName('Opportunity_Update_Threshold');
            Integer threshold = setting?.Data__c != null ? Integer.valueOf(setting.Data__c) : 40;
            Database.executeBatch(new BatchToUpdateOrInsertSObjects(oppsToUpdate), threshold);
        } else {
            Database.update(oppsToUpdate, false);
        }
    }
    
    private List<User_Attribute__c> getUserAttributes(Set<Id> userIds) {
        return [SELECT Id, As_of_Date__c, End_Date__c, User__c, RecordTypeId
                FROM User_Attribute__c 
                WHERE User__c IN: userIds AND RecordTypeId =: USER_HISTORY_ID
                ORDER BY End_Date__c DESC NULLS LAST];
    }
}