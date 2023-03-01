/**
* @description apex controller for the queue manager component
* @name trac_QueueManagerController
* @author Daniel Labonte, Traction on Demand
* @date 2019-09-13
*/

public without sharing class trac_QueueManagerController {
    
    private static String USER_ROLE {
        get {
            if(UserInfo.getUserRoleId() != null) {
                UserRole myRole = [SELECT DeveloperName FROM UserRole WHERE Id = :UserInfo.getUserRoleId()];
                return myRole.DeveloperName;
            }
            return '';
        }
    }
    
    private static List<String> QUEUE_TYPES_TO_OMIT {
        get {
            List<String> queueTypes = new List<String>{'BOS'};
                if(USER_ROLE != 'Security') {
                    queueTypes.addAll(Global__c.getOrgDefaults().Security_Only_Queue_Prefixes__c.split(';'));
                }
            return queueTypes;
        }
    }
    
    final private static List<String> QUEUE_DEV_NAMES_TO_OMIT {
        get {
            List<String> queueDevNames = new List<String>{'LEG_Legal'};
                if(USER_ROLE != 'Security') {
                    queueDevNames.addAll(Global__c.getOrgDefaults().Security_Only_Queues__c.split(';'));
                }
            return queueDevNames;
        }
    }
    
    
    
    @AuraEnabled
    public static Boolean isUserAdmin() {
        try {
            return [SELECT Id,Name FROM Profile WHERE Id = :UserInfo.getProfileId()].Name == TLOrgConstants.PROFILE_SYSTEM_ADMIN;
        } catch (Exception e) { return false; }
    }
    
    
    @AuraEnabled
    public static List<Location_Queue_Type__mdt> getLocationQueueTypes() {
        {
            return [SELECT Id, Queue_Name_Prefix__c, Label
                    FROM Location_Queue_Type__mdt
                    WHERE Queue_Name_Prefix__c NOT IN :QUEUE_TYPES_TO_OMIT
                    ORDER BY Queue_Name_Prefix__c
                   ];
        }
    }
    
    
    @AuraEnabled
    public static List<LocationQueueMembership> getCMLocationQueues(String userId) {
        // get my CM queue memberships
        List<GroupMember> myMemberships = [SELECT Id, GroupId, UserOrGroupId FROM GroupMember WHERE UserOrGroupId = :userId];
        Map<String, String> queueIdToMembershipId = new Map<String, String>();
        for (GroupMember gm : myMemberships) {
            queueIdToMembershipId.put(gm.GroupId, gm.Id);
        }
        Set<String> queueIdSet = new Set<String>();
        List<Location_Queue__c> locationQueues;
        /*if(USER_ROLE == 'External_Vendor') {
            locationQueues = [
                SELECT Id,building_Id__c,building_Id__r.Name,building_Id__r.Business_Hours_Id__r.TimeZoneSidKey,Name,Queue_Id__c,Queue_Label__c,Queue_Prefix__c
                FROM Location_Queue__c
                WHERE Queue_Id__c != NULL
                AND Queue_Prefix__c NOT IN :QUEUE_TYPES_TO_OMIT
                ORDER BY building_Id__r.Name ASC];
        } else {*/
            
            locationQueues = [
                SELECT Id,building_Id__c,building_Id__r.Name,building_Id__r.Business_Hours_Id__r.TimeZoneSidKey,Name,Queue_Id__c,Queue_Label__c,Queue_Prefix__c
                FROM Location_Queue__c
                WHERE Queue_Id__c != NULL
                AND Queue_Prefix__c NOT IN :QUEUE_TYPES_TO_OMIT
                ORDER BY building_Id__r.Name ASC
            ];
       // }
        system.debug('locationQueues:   '+locationQueues);
        for (Location_Queue__c locationQueue : locationQueues) {
            if (String.isNotBlank(locationQueue.Queue_Id__c)) {
                queueIdSet.add(locationQueue.Queue_Id__c);
            }
        }
        List<QueueSobject> genericQueues;
        if (USER_ROLE == 'External_Vendor') {
            genericQueues = [
                SELECT Id, Queue.Name, QueueId
                FROM QueueSobject
                WHERE QueueId NOT IN :queueIdSet
                AND SobjectType = 'Case'
                AND Queue.DeveloperName NOT IN :QUEUE_DEV_NAMES_TO_OMIT
                AND (NOT Queue.Name LIKE 'BOS:%')
                ORDER BY Queue.Name ASC
            ];
        } else {
            genericQueues = [
                SELECT Id, Queue.Name, QueueId
                FROM QueueSobject
                WHERE QueueId NOT IN :queueIdSet
                AND SobjectType = 'Case'
                AND Queue.DeveloperName NOT IN :QUEUE_DEV_NAMES_TO_OMIT
                AND (NOT Queue.Name LIKE 'BOS:%')
                ORDER BY Queue.Name ASC
            ];
        }
        system.debug('genericQueues:    '+genericQueues);
        List<LocationQueueMembership> queueMemberships = new List<LocationQueueMembership>();
        for (Location_Queue__c locationQueue : locationQueues) {
            String queueIdString = locationQueue.Queue_Id__c;
            Boolean isMember = false;
            system.debug('isMember: '+isMember);
            if (queueIdToMembershipId.get(locationQueue.Queue_Id__c) != null) {
                queueIdString = locationQueue.Queue_Id__c + ':' + queueIdToMembershipId.get(locationQueue.Queue_Id__c);
                isMember = true;
            }
            queueMemberships.add(new LocationQueueMembership(
                locationQueue.building_Id__c,
                locationQueue.Queue_Label__c,
                locationQueue.Queue_Label__c,
                queueIdString,
                locationQueue.Queue_Prefix__c,
                locationQueue.building_Id__r.Business_Hours_Id__r.TimeZoneSidKey,
                isMember,
                true));
        }
        for (QueueSobject queue : genericQueues) {
            String queueIdString = queue.QueueId;
            Boolean isMember = false;
            if (queueIdToMembershipId.get(queue.QueueId) != null) {
                queueIdString = queue.QueueId + ':' + queueIdToMembershipId.get(queue.QueueId);
                isMember = true;
            }
            queueMemberships.add(new LocationQueueMembership('', queue.Queue.Name, queue.Queue.Name, queueIdString, 'Other', 'Location unavailable', isMember, false));
            
        }
        return queueMemberships;
    }
    
    @AuraEnabled
    public static Boolean insertQueueMember(List<String> queueIds, String userId) {
        if (queueIds.isEmpty()) return true;
        List<GroupMember> groupMembers = new List<GroupMember>();
        for (String s : queueIds) {
            if (s.split(':').size() == 1) {
                groupMembers.add(new GroupMember(
                    GroupId = s.split(':')[0],
                    UserOrGroupId = userId
                ));
            }
        }
        System.debug(groupMembers);
        List<Database.SaveResult> saveResults = Database.insert(groupMembers);
        for (Database.SaveResult sr : saveResults) {
            if (!sr.success) return false;
        }
        return true;
    }
    
    @AuraEnabled
    public static Boolean deleteQueueMember(List<String> queueIds) {
        if (queueIds.isEmpty()) return true;
        List<Id> groupMemberIds = new List<Id>();
        for (String s : queueIds) {
            if (s.split(':').size() == 2) {
                groupMemberIds.add(s.split(':')[1]);
            }
        }
        List<Database.DeleteResult> deleteResults = Database.delete(groupMemberIds);
        for (Database.DeleteResult ur : deleteResults) {
            if (!ur.success) return false;
        }
        return true;
    }
    
    
    public class LocationQueueMembership {
        public String locationId;
        public String locationName;
        public String queueName;
        public String queueId;
        public String prefix;
        public String timeZone;
        public Boolean isMember;
        public Boolean isLocation;
        
        public LocationQueueMembership(String locationId, String locationName, String queueName, String queueId, String prefix, String timeZone, Boolean isMember, Boolean isLocation) {
            this.locationId = locationId;
            this.locationName = locationName;
            this.queueName = queueName;
            this.queueId = queueId;
            this.prefix = prefix;
            this.timeZone = timeZone;
            this.isMember = isMember;
            this.isLocation = isLocation;
        }
        
        @AuraEnabled
        public String getLocationId() { return locationId; }
        
        @AuraEnabled
        public String getLocationName() { return locationName; }
        
        @AuraEnabled
        public String getQueueName() { return queueName; }
        
        @AuraEnabled
        public String getQueueId() { return queueId; }
        
        @AuraEnabled
        public String getPrefix() { return prefix; }
        
        @AuraEnabled
        public String getTimeZone() { return timeZone; }
        
        @AuraEnabled
        public Boolean getIsMember() { return isMember; }
        
        @AuraEnabled
        public Boolean getIsLocation() { return isLocation; }
    }
}