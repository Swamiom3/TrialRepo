/***********************************************************************************************************************
    Author        :  Ashish Sharma
    Description   :  Helper class to update user attribute on opportunity team members
    Issue No.     :  ST-6640
    History       :
------------------------------------------------------------------------------------------------------------------------
    VERSION        DATE          AUTHOR           DETAIL
      1         27-Aug-2020    Ashish Sharma      ST-6640
***********************************************************************************************************************/
public inherited sharing class OppTeamMemberUpdateUserAttributeHelper {
   @TestVisible private static Set<Id> setOppTeamMemberUserIds;
   @TestVisible private List<String> oppTeamRolesToUpdateUserAttribute;
   @TestVisible private static Map<Id, List<OpportunityTeamMember>> userIdToTeamMembers;
    
    public OppTeamMemberUpdateUserAttributeHelper() {
        userIdToTeamMembers = new Map<Id, List<OpportunityTeamMember>>();
        oppTeamRolesToUpdateUserAttribute = Label.OppTeamRoles_to_Update_UserAttribute.toLowerCase().split(',');
    }
    
     public void updateUserAttribute(List<OpportunityTeamMember> opportunityTeamMembers, Boolean isFromBatch) {
        if(opportunityTeamMembers == null || opportunityTeamMembers.isEmpty()) {
            return;
        }
        for(OpportunityTeamMember teamMember : opportunityTeamMembers) {
            storeValidTeamMembers(teamMember, isFromBatch);
        }
        
        if(userIdToTeamMembers.isEmpty()) {
            return;
        }
        
        if(setOppTeamMemberUserIds != null && setOppTeamMemberUserIds.containsAll(userIdToTeamMembers.keySet())) {
            return;
        }
        
        setOppTeamMemberUserIds = new Set<Id>(userIdToTeamMembers.keySet());
        Map<Id, List<User_Attribute__c>> userIdToUserAttributes = getUserIdToUserAttributesMap();                
        if(userIdToUserAttributes.isEmpty()) {
            return;
        }
    }
    
    @TestVisible 
    private Id getUserAttribute(Date oppTeamMemberAssignedDate, List<User_Attribute__c> userAttributes) {
        for(User_Attribute__c userAttribute : userAttributes) {
            if (oppTeamMemberAssignedDate >= userAttribute.As_of_Date__c 
                    && (userAttribute.End_Date__c == null || oppTeamMemberAssignedDate <= userAttribute.End_Date__c)) {
                return userAttribute.Id;
            }
        }
        return null;
    }
    
    @TestVisible 
    private void storeValidTeamMembers(OpportunityTeamMember newTeamMember, Boolean isFromBatch) {
        if(String.isBlank(newTeamMember.TeamMemberRole)  
           || !oppTeamRolesToUpdateUserAttribute.contains(newTeamMember.TeamMemberRole.toLowerCase())){
               return;
           }
        if((newTeamMember.User_Attribute__c == null || isFromBatch)) {
            if(!userIdToTeamMembers.containskey(newTeamMember.UserId)){
                userIdToTeamMembers.put(newTeamMember.UserId,  new List<OpportunityTeamMember>());                    
            } 
            userIdToTeamMembers.get(newTeamMember.UserId).add(newTeamMember);
        }
    }
    
    @TestVisible 
    private Map<Id, List<User_Attribute__c>> getUserIdToUserAttributesMap() {
        final String USER_HISTORY_RECORDTYPE = 'User History';
        Id userHistoryRecordTypeId = Schema.SObjectType.User_Attribute__c.getRecordTypeInfosByName().get(USER_HISTORY_RECORDTYPE).getRecordTypeId();
        Map<Id, List<User_Attribute__c>> userIdToUserAttributes = new Map<Id, List<User_Attribute__c>>();
        for(User_Attribute__c userAttribute : [SELECT Id, User__c, As_of_Date__c, End_Date__c 
                                               FROM User_Attribute__c 
                                               WHERE RecordTypeId =:userHistoryRecordTypeId AND User__c IN :userIdToTeamMembers.keySet()
                                               ORDER BY End_Date__c DESC NULLS LAST]) {
                                                   setUserIdToUserAttributes(userAttribute, userIdToUserAttributes);
                                               }
        return userIdToUserAttributes;
    }
    
    @TestVisible 
    private void setUserIdToUserAttributes(User_Attribute__c userAttribute, Map<Id, List<User_Attribute__c>> userIdToUserAttributes) {
        if(userIdToUserAttributes.containskey(userAttribute.User__c)) {
            userIdToUserAttributes.get(userAttribute.User__c).add(userAttribute);
        } else {
            userIdToUserAttributes.put(userAttribute.User__c, new List<User_Attribute__c>{userAttribute});
        }
    }
}