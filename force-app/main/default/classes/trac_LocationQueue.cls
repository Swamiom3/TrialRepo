/**
 * @description Apex class trac_LocationQueue
 * @author Daniel Labonte, Traction on Demand
 * @date 2020-05-01
 */

public without sharing class trac_LocationQueue extends SObjectDomain {
    public List<Location_Queue__c> locationQueues;

    public trac_LocationQueue() {
        super();
        this.locationQueues = (List<Location_Queue__c>) records;
    }


    public override void onBeforeInsert() {
        insertQueues(this.locationQueues);
    }

    public override void onBeforeUpdate(Map<Id, SObject> existingRecords) {
        updateQueues(this.locationQueues, (Map<Id, Location_Queue__c>) existingRecords);
    }

    public override void onBeforeDelete() {
        deleteQueues(this.locationQueues);
    }


    /**
     * @description Create and insert group records based on the location queue records and update the location queues
     *              records with the new group records ids
     * @param locationQueues new location queue records
     */
    private static void insertQueues(List<Location_Queue__c> locationQueues) {
        Map<String, Location_Queue__c> locationQueueByDevName = new Map<String, Location_Queue__c>();

        List<Group> newQueues = new List<Group>();
        for (Location_Queue__c lq : locationQueues) {
            locationQueueByDevName.put(lq.Queue_Developer_Name__c, lq);
            newQueues.add(new Group(
                    DeveloperName = lq.Queue_Developer_Name__c,
                    Name = lq.Queue_Label__c, Type = 'Queue',
                    DoesSendEmailToMembers = true
            ));
        }
        insert newQueues;

        List<GroupMember> allGroupMembers = new List<GroupMember>();
        try {
            Group defaultMember = getDefaultQueueMember();
            for (Group grp : newQueues) {
                allGroupMembers.add(new GroupMember(
                        GroupId = grp.Id,
                        UserOrGroupId = defaultMember.Id
                ));
            }
        } catch (Exception e) {
            System.debug('ERROR getting default group as member: ' + e.getMessage());
        }

        // create queue sobject records for each group
        List<QueueSobject> newQueueSObjects = new List<QueueSobject>();
        for (Group grp : newQueues) {
            locationQueueByDevName.get(grp.DeveloperName).Queue_Id__c = grp.Id;
            newQueueSObjects.add(new QueueSobject(QueueId = grp.Id, SobjectType = 'Case'));
        }
        insertQueueSObjects(JSON.serialize(newQueueSObjects), JSON.serialize(allGroupMembers));
    }


    /**
     * @description Update group records when the location queues records are changed
     * @param locationQueues changed location queues
     * @param oldMap old version of the location queue records
     */
    private static void updateQueues(List<Location_Queue__c> locationQueues, Map<Id, Location_Queue__c> oldMap) {
        List<Group> queuesToUpdate = new List<Group>();
        for(Location_Queue__c lq : locationQueues) {
            queuesToUpdate.add(new Group(
                    Id = lq.Queue_Id__c,
                    Name = lq.Queue_Label__c
            ));
        }
        update queuesToUpdate;
    }


    /**
     * @description When a location queue is deleted, reparent the cases in the associated queue, delete group members
     *              of the associated queue, and delete said queue
     * @param locationQueues records that are being deleted
     */
    private static void deleteQueues(List<Location_Queue__c> locationQueues) {
        Set<String> queueIds = TLList.collectStrings(locationQueues,Location_Queue__c.Queue_Id__c);

        List<Case> casesWithDeletedQueues = [SELECT Id FROM Case WHERE OwnerId IN :queueIds];
        for(Case cs : casesWithDeletedQueues) {
            cs.OwnerId = UserInfo.getUserId();
        }
        update casesWithDeletedQueues;

        deleteQueuesAndMembers(queueIds);
    }



    /**
     * @description asynchronously insert the queue sobjects for the newly created groups
     * @param queueSObjectsJson string of serialized queue sobject records
     */
    @Future
    public static void insertQueueSObjects(String queueSObjectsJson, String groupMemberJson) {
        if (!String.isEmpty(queueSObjectsJson)) {
            insert (List<QueueSobject>) JSON.deserialize(queueSObjectsJson, List<QueueSobject>.class);
        }
        if (!String.isEmpty(groupMemberJson)) {
            insert (List<GroupMember>) JSON.deserialize(groupMemberJson, List<GroupMember>.class);
        }
    }


    /**
     * @description asynchronously insert the queue sobjects for the newly created groups
     * @param queueSObjectsJson string of serialized queue sobject records
     */
    @Future
    public static void deleteQueuesAndMembers(Set<String> queueIds) {
        delete [SELECT Id FROM GroupMember WHERE GroupId IN :queueIds];
        delete [SELECT Id FROM Group WHERE Id IN :queueIds];
    }


    /**
     * @description Get the default queue member so that emails can send
     * @return group member
     */
    public static Group getDefaultQueueMember() {
        return [SELECT Id FROM Group WHERE DeveloperName = 'Community' AND Type = 'Role'][0];
    }
}