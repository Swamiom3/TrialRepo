/**
 * @description Apex class LocationWrapper
 * @author Daniel Labonte, Traction on Demand
 * @date 2020-05-04
 */

public without sharing class trac_LocationWrapper {
    public Location__c location;
    public Location__c oldLocation;
    public Map<String, Location_Queue__c> prefixToQueue = new Map<String, Location_Queue__c>();
    public List<Location_Queue_Type__mdt> queueTypesToAdd = new List<Location_Queue_Type__mdt>();
    public List<Location_Queue__c> roqueQueues = new List<Location_Queue__c>();

    public static Map<String, List<Location_Queue_Type__mdt>> queueTypesByRtId = getQueueTypes();


    public trac_LocationWrapper(Location__c location, Location__c oldLocation) {
        this.location = location;
        this.oldLocation = oldLocation;
    }


    public trac_LocationWrapper setAllQueues(List<Location_Queue__c> locationQueues, String recordTypeId) {

        Map<String, Location_Queue__c> lqMap = new Map<String, Location_Queue__c>();
        for (Location_Queue__c lq : locationQueues) {
            lqMap.put(lq.Queue_Prefix__c, lq);
        }
        if (queueTypesByRtId.get(recordTypeId) != null) {
            for (Location_Queue_Type__mdt mdt : queueTypesByRtId.get(recordTypeId)) {
                if (lqMap.get(mdt.Queue_Name_Prefix__c) != null) {
                    prefixToQueue.put(mdt.Queue_Name_Prefix__c, lqMap.remove(mdt.Queue_Name_Prefix__c));
                } else {
                    queueTypesToAdd.add(mdt);
                }
            }
        }

        roqueQueues.addAll(lqMap.values());


        return this;
    }


    private static Map<String, List<Location_Queue_Type__mdt>> getQueueTypes() {
        Map<String, List<Location_Queue_Type__mdt>> mapOfQueueTypes = new Map<String, List<Location_Queue_Type__mdt>>();
        for (Location_Queue_Type__mdt mdt : [SELECT Case_Location_Id__c, DeveloperName, Id, Label, Location_Record_Type__c, Queue_Name_Prefix__c FROM Location_Queue_Type__mdt]) {
            String rtId = Schema.SObjectType.Location__c.getRecordTypeInfosByName().get(mdt.Location_Record_Type__c).getRecordTypeId();
            List<Location_Queue_Type__mdt> tempTypes = new List<Location_Queue_Type__mdt>{
                    mdt
            };
            if (mapOfQueueTypes.get(rtId) != null) {
                tempTypes.addAll(mapOfQueueTypes.get(rtId));
            }
            mapOfQueueTypes.put(rtId, tempTypes);
        }
        return mapOfQueueTypes;
    }
}