/**********************************************************************************************************
    Author        :  Ashish Sharma
    Description   :  This trigger updates the users associated with the UAs.
    Issue No.     :  ST-7390
    History       :
-----------------------------------------------------------------------------------------------------------
    VERSION        DATE          AUTHOR           DETAIL
      1         15-Jan-2021    Ashish Sharma      Refactor and move to new framework
      2         24 Feb, 2021   Pawel Biszczak     Changing visibility to without sharing in scope of ST-7802
**********************************************************************************************************/
public without sharing class UserAttributeUpdateUsersTrH extends SObjectTriggerHandler {
    @TestVisible
    private List<User_Attribute__c> newUserAttributes;
    @TestVisible
    private Map<Id, User_Attribute__c> oldUserAttributesMap;
    private final static Id USER_HISTORY_ID = (Id) WeworkEngine.getObjectRecordTypeId('User_Attribute__c', 'User History');
    private final static Set<String> FIELDS_CHANGED = new Set<String> {
            'Sales_Function__c', 'Region__c', 'Portfolio__c',
            'Sales_Team__c', 'Manager__c', 'Territory__c'
    };
    
    public UserAttributeUpdateUsersTrH() {
        this((List<User_Attribute__c>) Trigger.new, (Map<Id, User_Attribute__c>) Trigger.oldMap);
    }
    
    @TestVisible
    private UserAttributeUpdateUsersTrH(List<User_Attribute__c> newUserAttributes, Map<Id, User_Attribute__c> oldUserAttributesMap) {
        this.newUserAttributes = newUserAttributes;
        this.oldUserAttributesMap = oldUserAttributesMap;
    }
    
    public override void afterInsert() {
        updateUser();
    }
    
    public override void afterUpdate() {
        updateUser();
    }
    
    private void updateUser() {
        Map<Id, User_Attribute__c> validUAs = new Map<Id, User_Attribute__c>();        
        Set<Id> portfolioIds = new Set<Id>();
        List<User> usersToUpdate = new List<User>();
        Map<Id, Market__c> portfolios;
        Map<String, Map<String, String>> mappings = getMappings();
        
        for (User_Attribute__c newUA : newUserAttributes) {
            User_Attribute__c oldUA;
            if (newUA.RecordTypeId != USER_HISTORY_ID
                   || (newUA.End_Date__c != null && newUA.End_Date__c < System.today())) {
                continue;
            }
            oldUA = oldUserAttributesMap?.get(newUA.Id);
            if(oldUA != null && !TriggerUtility.isFieldsValueChanged(newUA, oldUA, FIELDS_CHANGED)) {
                continue;
            }
            validUAs.put(newUA.User__C, newUA);
            if (newUA.Portfolio__c != null) {
                portfolioIds.add(newUA.Portfolio__c);
            }
        }
        if (validUAs.isEmpty()) {
            return; 
        }
        
        if (!portfolioIds.isEmpty()) {
            portfolios = getPorfolios(portfolioIds);
        }
        
        for (Id userId : validUAs.keySet()) {
            User user = new User(Id = userId);
            User_Attribute__c newUA = validUAs.get(userId);
            user.Sales_Role__c = newUA.Sales_Function__c;
            user.Region__c = newUA.Region__c;
            user.ManagerId = newUA.Manager__c;
            user.Sales_Team__c = newUA.Sales_Team__c;
            user.Territory__c = newUA.Territory__c;
            
            if (portfolios?.get(newUA.Portfolio__c) != null) {
                user.Portfolio__c = portfolios.get(newUA.Portfolio__c).Name;
            } else {
                user.Portfolio__c = null;
            }
            for (String uaField: mappings.keySet()) {
                User_Attribute__c oldUA = oldUserAttributesMap?.get(newUA.Id);
                if (oldUA != null && !TriggerUtility.isFieldValueChanged(newUA, oldUA, uaField)) {
                    continue;
                }
                for (String userKey: mappings.get(uaField).keyset()) {
                    Object result = String.isNotBlank((String) newUA.get(uaField))
                                    ? UserUtility.getUserById((String) newUA.get(uaField))?.get(userKey)
                                    : null;
                    user.put(mappings.get(uaField).get(userKey), result);
                }
            }
            usersToUpdate.add(user);
        }
        
        if (usersToUpdate.isEmpty()) {
            return;
        }
        
        Database.update(usersToUpdate, false);
        UserUtility.refreshUsers();
    }
    
    private Map<String, Map<String, String>> getMappings() {
        MetadataSetting__mdt setting = Settings.getMetadataSettingByDevName('UserAttributesUserToUserMapping');        
        if (setting != null && String.isNotBlank(setting.Data__c)) {
            return (Map<String, Map<String, String>>)JSON.deserialize(setting.Data__c, Map<String, Map<String, String>> .class);
        }
        return new Map<String, Map<String, String>>();
    }
    
    private Map<Id, Market__c> getPorfolios(Set<Id> portfolioIds) {
        return new Map<Id, Market__c>([SELECT Id, Name 
                                       FROM Market__c 
                                       WHERE Id IN: portfolioIds AND No_Longer_in_Use__c <> TRUE]);
    }
}