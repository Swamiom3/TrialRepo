/**
 * @description Location class for the Location trigger
 * @name trac_Location
 * @author Daniel Labonte, Traction on Demand
 * @date 2019-07-30
 */

public without sharing class trac_Location extends SObjectDomain {
    public static Map<Id, Map<String, Location_Queue__c>> locationQueuesByLocationId = new Map<Id, Map<String, Location_Queue__c>>();

    public List<Location__c> locations;

    public Map<String, trac_LocationWrapper> locationWrap = new Map<String, trac_LocationWrapper>();

    Integer idx = 0;

    public trac_Location() {
        super();
        this.locations = (List<Location__c>) records;

        // records have ids
        if(Trigger.isAfter || (Trigger.isBefore && Trigger.isDelete)) {
            Map<Id,List<Location_Queue__c>> locationQueueMap = new Map<Id, List<Location_Queue__c>>();
            for (Location_Queue__c lq : [SELECT Id,Location__c,Name,Queue_Developer_Name__c,Queue_Id__c,Queue_Label__c,Queue_Prefix__c FROM Location_Queue__c WHERE Location__c IN :(new Map<Id,Location__c>(this.locations)).keySet()]) {
                List<Location_Queue__c> tempLqs = new List<Location_Queue__c>{lq};
                if (locationQueueMap.get(lq.Location__c) != null) {
                    tempLqs.addAll(locationQueueMap.get(lq.Location__c));
                }
                locationQueueMap.put(lq.Location__c,tempLqs);
            }

            System.debug(JSON.serializePretty(locationQueueMap));

            for (Location__c location : this.locations) {
                Location__c oldLocation = Trigger.isUpdate ? (Location__c) Trigger.oldMap.get(location.Id) : location;
                List<Location_Queue__c> lqs = locationQueueMap.get(location.Id) != null ? locationQueueMap.get(location.Id) : new List<Location_Queue__c>();
                trac_LocationWrapper wrap = new trac_LocationWrapper(location,oldLocation)
                        .setAllQueues(lqs, location.RecordTypeId);

                locationWrap.put(location.Id,wrap);
            }
        }

    }


    public override void onBeforeInsert() {
        try { // all before insert methods go here
            trac_LocationHandler.populateHierarchy(locations);
        } catch (LocationException e) {
            locations[0].addError(e.getMessage());
        }
    }

    public override void onBeforeUpdate(Map<Id, SObject> existingRecords) {
        try { // all before update methods go here
            trac_LocationHandler.populateHierarchy(locations, (Map<Id, Location__c>) existingRecords);
        } catch (LocationException e) {
            locations[0].addError(e.getTypeName());
        }
    }

    public override void onAfterInsert() {
        System.debug(JSON.serialize(locationWrap));
        try { // all after insert methods go here
            trac_LocationHandler.processAllQueueDml(locationWrap);
        } catch (LocationException e) {
            locations[0].addError(e.getMessage());
        }
    }

    public override void onAfterUpdate(Map<Id, SObject> existingRecords) {
        try { // all after update methods go here
            trac_LocationHandler.processAllQueueDml(locationWrap);
        } catch (LocationException e) {
            locations[0].addError(e.getMessage());
        }
    }

    public override void onBeforeDelete() {
        delete [SELECT Id FROM Location_Queue__c WHERE Location__c IN :(new Map<Id,Location__c>(this.locations).keySet())];
    }


    public class LocationException extends Exception {}







}