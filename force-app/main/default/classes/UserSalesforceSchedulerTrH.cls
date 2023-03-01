/************************************************************************************************************************************
Author      :   Salesforce
Description :   This class is to enable users with Salesforce Scheduler Resource PS/License 
                and create/update Service Resources based on Salesforce_Scheduler_User__c field
----------------------------------------------------------------------------------------------------------------------------------
VERSION     DATE                AUTHOR                DETAIL
1           01 Sep 2021         Salesforce            Initial Developement
**************************************************************************************************************************************/
public with sharing class UserSalesforceSchedulerTrH extends SObjectTriggerHandler{
    private List<User> newUsers;
    private Map<Id, User> oldUsersMap;

    private static final String RESOURCE_TYPE_TECHNICIAN = 'T';    
    private final String SALESFORCE_SCHEDULER_PERM_SET_NAME = 'Salesforce_Scheduler_Resource';
    private final String SALESFORCE_SCHEDULER_USER_FIELD_API_NAME = 'Salesforce_Scheduler_User__c';
    @TestVisible
    private static UserSelector userSelector = new UserSelector();

    public UserSalesforceSchedulerTrH() {
        this((List<User>) Trigger.new, (Map<Id, User>) Trigger.oldMap); 
    }

    @TestVisible
    private UserSalesforceSchedulerTrH(List<User> newUsers, Map<Id, User> oldUsersMap) {
        this.newUsers = newUsers; 
        this.oldUsersMap = oldUsersMap;
    }

    public override void afterInsert() {
        manageSalesforceSchedulerUsers();
    }

    public override void afterUpdate(){
        manageSalesforceSchedulerUsers();        
    }

    @TestVisible
    private void manageSalesforceSchedulerUsers(){
        List<Id> filteredUserIds = new List<Id>(); 
        for(User usr: newUsers){
            if((context == TriggerContext.AFTER_INSERT && usr.Salesforce_Scheduler_User__c) || (context == TriggerContext.AFTER_UPDATE && TriggerUtility.isFieldValueChanged(usr, oldUsersMap.get(usr.Id), SALESFORCE_SCHEDULER_USER_FIELD_API_NAME))){
                filteredUserIds.add(usr.Id);
            }
        }
        if(!filteredUserIds.isEmpty()){
            // Add/Remove Salesforce Scheduler Licence based on Salesforce_Scheduler_User__c field
            addOrRemoveSalesforceSchedulerLicense(filteredUserIds);

            // Create/Update Service Resource for the User based on Salesforce_Scheduler_User__c field
            createOrUpdateServiceResources(filteredUserIds);
        }
    }

    @TestVisible
    private void addOrRemoveSalesforceSchedulerLicense(List<Id> userIds){
        Map<Id, PermissionSetAssignment> userWithPermissionSetMap = new Map<Id, PermissionSetAssignment>();
        Id permissionSetId = [SELECT Id 
                              FROM PermissionSet 
                              WHERE Name =: SALESFORCE_SCHEDULER_PERM_SET_NAME 
                              LIMIT 1]?.Id;
        if(permissionSetId == null){
            newUsers[0].addError(System.Label.SalesforceSchedulerLicenseErrorMessage);
        }
        for(PermissionSetAssignment psAssignment : [SELECT Id, PermissionSetId, AssigneeId 
                                                    FROM PermissionSetAssignment
                                                    WHERE AssigneeId IN: userIds
                                                        AND PermissionSetId =:permissionSetId]){
            userWithPermissionSetMap.put(psAssignment.AssigneeId, psAssignment);
        }
        List<PermissionSetAssignment> permissionSetAssignmentsToInsert = new List<PermissionSetAssignment>();
        List<PermissionSetAssignment> permissionSetAssignmentsToDelete = new List<PermissionSetAssignment>();
        for(User usr : userSelector.getUsersById(userIds)){
            if(usr.Salesforce_Scheduler_User__c){
                if(!userWithPermissionSetMap.containsKey(usr.Id)){
                    permissionSetAssignmentsToInsert.add(new PermissionSetAssignment(
                        PermissionSetId = permissionSetId,
                        AssigneeId = usr.Id
                    ));
                }
            } else {
                if(userWithPermissionSetMap.containsKey(usr.Id)){
                    permissionSetAssignmentsToDelete.add(userWithPermissionSetMap.get(usr.Id));
                }
            }
        }
        if(!permissionSetAssignmentsToInsert.isEmpty()){
            insert permissionSetAssignmentsToInsert;
        }
        if(!permissionSetAssignmentsToDelete.isEmpty()){
            delete permissionSetAssignmentsToDelete;
        }
    }

    @future
    public static void createOrUpdateServiceResources(List<Id> userIds){
        List<ServiceResource> serviceResourcesToUpsert = new List<ServiceResource>();
        Map<Id, ServiceResource> userWithServiceResourceMap = new Map<Id, ServiceResource> ();
        for(ServiceResource serviceResourceRecord : [SELECT Id, Name, IsActive, RelatedRecordId  
                                                     FROM ServiceResource 
                                                     WHERE RelatedRecordId IN: userIds]){
            userWithServiceResourceMap.put(serviceResourceRecord.RelatedRecordId, serviceResourceRecord);
        }
        for(User usr : userSelector.getUsersById(userIds)){
            ServiceResource serviceResourceRecord = new ServiceResource();
            if(userWithServiceResourceMap.containsKey(usr.Id)){
                serviceResourceRecord.Id = userWithServiceResourceMap.get(usr.Id).Id;
            }
            serviceResourceRecord.RelatedRecordId = usr.Id;
            serviceResourceRecord.Name = usr.Name;
            serviceResourceRecord.ResourceType = RESOURCE_TYPE_TECHNICIAN;
            serviceResourceRecord.isActive = usr.Salesforce_Scheduler_User__c;
            serviceResourcesToUpsert.add(serviceResourceRecord);
        }
        if(!serviceResourcesToUpsert.isEmpty()){
            upsert serviceResourcesToUpsert;
        }
    }    
}