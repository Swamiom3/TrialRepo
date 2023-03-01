/*************************************************************************************************************************************
 Author      :   Oleg Krasko
 Description :   The batch takes all Activities and replaces Location lookup values with Building ones
 --------------------------------------------------------------------------------------------------------------------------------------
 VERSION         DATE            AUTHOR              DETAIL
 1               06/22/2022      Oleg Krasko         Initial Deployment
 **************************************************************************************************************************************/
public with sharing class LocationToBuildingMigrationBatch implements Database.Batchable<SObject>{
    private Boolean isFirstTimeRunning;
    private BuildingSelector buildingSelector;
    private Map<String, String> locationIdToUUID;
    private Map<String, String> buildingUuidToId;
    private LocationToBuildingMigrationBatch.ActivityType activityType;
    @TestVisible
    private final String ERROR_MESSAGE = 'activityType parameter must be populated';
    private final String LOCATION_UUID_API_NAME = 'Location_UUID__c';
    private final String UUID_API_NAME = 'UUID__c';
    private final String ID_API_NAME = 'Id';
    private final String BUILDING_API_NAME = 'Building__c';
    private final String DEL_LOCATION_API_NAME = 'Building_del__c';
    private final String TASK_API_NAME = 'Task';
    private final String EVENT_API_NAME = 'Event';

    public LocationToBuildingMigrationBatch(LocationToBuildingMigrationBatch.ActivityType activityType) {
        if (activityType == null) {
            throw new LocationToBuildingMigrationBatchException(ERROR_MESSAGE);
        }
        if (activityType == LocationToBuildingMigrationBatch.ActivityType.BOTH) {
            this.isFirstTimeRunning = true;
            this.activityType = LocationToBuildingMigrationBatch.ActivityType.TASK;
        } else {
            this.isFirstTimeRunning = false;
            this.activityType = activityType;
        }
    }

    public Database.QueryLocator start(Database.BatchableContext batchContext){
        String query = 'SELECT {1} FROM {0} WHERE {1} != null';
        return Database.getQueryLocator(String.format(query, new List<String>{activityType.name(), DEL_LOCATION_API_NAME}));
    }

    public void execute(Database.BatchableContext batchContext, List<SObject> activities){
        if (activities.isEmpty() != false) {
            return;
        }
        
        Set<Id> locationIds = new Set<Id>();
        collectLocationIds(activities, locationIds);

        locationIdToUUID = new Map<String, String>();
        populateStringToStringMap(locationIdToUUID, ID_API_NAME, LOCATION_UUID_API_NAME, 
                                [SELECT Location_UUID__c FROM Location__c WHERE Id IN :locationIds]);

        buildingUuidToId = new Map<String, String>();
        buildingSelector = new BuildingSelector();
        populateStringToStringMap(buildingUuidToId, UUID_API_NAME, ID_API_NAME, buildingSelector.getBuildingsByUuid(locationIdToUUID.values()));


        List<SObject> sObjectsToUpdate = (List<SObject>) Type.forName('List<' + activityType.name() + '>').newInstance();
        collectSObjectsToUpdate(activities, sObjectsToUpdate);

        if (!sObjectsToUpdate.isEmpty()) {
            update sObjectsToUpdate;
        }
    }

    public void finish(Database.BatchableContext batchContext){
        if (!isFirstTimeRunning) {
            return;
        }
        Database.executeBatch(new LocationToBuildingMigrationBatch(
            LocationToBuildingMigrationBatch.ActivityType.EVENT
        ));
    }

    private void collectLocationIds(List<SObject> sObjectsToIterateOver, Set<Id> locationIds){
        for (SObject loopSObject : sObjectsToIterateOver) {
            locationIds.add((Id) loopSObject.get(DEL_LOCATION_API_NAME));
        }
    }

    private void populateStringToStringMap(Map<String, String> stringToStringMap, String key, String value,
                                                                List<SObject> sObjectsToIterateOver){
        for (SObject loopSObject : sObjectsToIterateOver) {
            stringToStringMap.put((String) loopSObject.get(key), (String) loopSObject.get(value));
        }
    }

    private void collectSObjectsToUpdate(List<SObject> sObjectsToIterateOver, List<SObject> sObjectsToUpdate){
        for (SObject loopSObject : sObjectsToIterateOver) {
            loopSObject.put(BUILDING_API_NAME, buildingUuidToId.get(locationIdToUUID.get((Id) loopSObject.get(DEL_LOCATION_API_NAME))));
            sObjectsToUpdate.add(loopSObject);
        }
    }

    public enum ActivityType {
        TASK,
        EVENT,
        BOTH
    }

    public class LocationToBuildingMigrationBatchException extends Exception{}
}