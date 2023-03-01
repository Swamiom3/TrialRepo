/************************************************************************************************************************************
Author      :   Salesforce
Description :   This class is create/modify the Service Resources based on Building Players.
----------------------------------------------------------------------------------------------------------------------------------
VERSION     DATE                AUTHOR                DETAIL
1           26 Aug 2021         Salesforce            Initial Developement
**************************************************************************************************************************************/

public with sharing class BuildingPlayersToServiceResourceTrH extends SObjectTriggerHandler {
    @TestVisible
    private List<Building__c> newBuildings;

    @TestVisible
    private Map<Id, Building__c> oldBuildingsMap;

    @TestVisible
    private Map<Id, Building__c> newBuildingsMap;

    @TestVisible
    private final String RESOURCE_TYPE_TECHNICIAN = 'T';

    @TestVisible
    private final String TERRITORY_TYPE_PRIMARY = 'P';

    @TestVisible
    private final String TERRITORY_TYPE_SECONDARY = 'S';

    @TestVisible
    private final String DEFAULT_TIME_ZONE = 'GMT';

    private Map<String,List<String>> buildingIdToUpdatedFieldAPIs = new Map<String,List<String>>();

    private Map<Id, ServiceResource> userWithServiceResourceMap = new Map<Id, ServiceResource> ();

    private Map<String, String> roleSettings = new Map<String, String>();
    private final String SUFFIX_ROLE = '_ROLE';
    private final String SUFFIX_TIME_SLOT_NEEDED = '_TIME_SLOT_NEEDED';
    private static final String SALESFORCE_SCHEDULER_PERM_SET_NAME = 'Salesforce_Scheduler_Resource';

    public BuildingPlayersToServiceResourceTrH() {
        this((List<Building__c>) Trigger.new, (Map<Id, Building__c>) Trigger.newMap, (Map<Id, Building__c>) Trigger.oldMap);
    }

    @TestVisible
    private BuildingPlayersToServiceResourceTrH(List<Building__c> newBuildings,
                                                Map<Id, Building__c> newBuildingsMap,
                                                Map<Id, Building__c> oldBuildingsMap) {
        this.newBuildings = newBuildings;
        this.newBuildingsMap = newBuildingsMap;
        this.oldBuildingsMap = oldBuildingsMap;
    }

    public override void afterInsert() {
        syncBuildingPlayersToServiceResources();
    }

    public override void afterUpdate() {
        syncBuildingPlayersToServiceResources();
    }

    @TestVisible
    private void syncBuildingPlayersToServiceResources(){
        populateRoleSettingWrapperMap();
        List<Id> buildingLeasingUsersToRemove = new List<Id>();
        List<Id> buildingLeasingUsersToAdd = new List<Id>();
        for(Building__c building: newBuildings){
            List<String> fieldAPINames = getFieldsUpdated(building);
            if(fieldAPINames.isEmpty()){
                continue;
            }
            buildingIdToUpdatedFieldAPIs.put(building.id, fieldAPINames);
            for(String fieldAPIName : fieldAPINames){
                String fieldValue = (String)building.get(fieldAPIName);
                if(String.isNotBlank(fieldValue)){
                    buildingLeasingUsersToAdd.add(fieldValue);
                }
                buildingLeasingUsersToRemove.add((String)oldBuildingsMap?.get(building.Id)?.get(fieldAPIName));
            }
        }

        // If building player is removed then end their Service Territory Membership for the building
        if(!buildingLeasingUsersToRemove.isEmpty()){
            endServiceTerritoryMembership(buildingLeasingUsersToRemove);
        }

        // If a Leasing Manager is changed/added, check their Service Resource and thier Service Territory Membership for the building
        if(!buildingLeasingUsersToAdd.isEmpty()){
            List<ServiceResource> serviceResources = verifyServiceResources(buildingLeasingUsersToAdd);
            if(!serviceResources.isEmpty()){
                createServiceTerritoryMembership(serviceResources);
            }
        }
    }

    @TestVisible
    private List<String> getFieldsUpdated(Building__c building){
        List<String> fieldsUpdated = new List<String>();
        Map<String, Building_Player_Role_Setting__mdt> buildingRoleSettings = Building_Player_Role_Setting__mdt.getAll();
        for(String roleName : buildingRoleSettings.keySet()){
            String fieldAPIName = buildingRoleSettings.get(roleName).label;
            if(oldBuildingsMap == null){
                fieldsUpdated.add(fieldAPIName);
            }else if(TriggerUtility.isFieldValueChanged(building, oldBuildingsMap.get(building.Id), fieldAPIName)){
                fieldsUpdated.add(fieldAPIName);
            }
        }
        return fieldsUpdated;
    }

    @TestVisible
    private void endServiceTerritoryMembership(List<Id> userIds){
        List<ServiceTerritoryMember> serviceTerritoryMembershipToUpdate = new List<ServiceTerritoryMember>();
        for(ServiceTerritoryMember serverritoryMember : getServiceTerritoryMembers(userIds)){
            serverritoryMember.EffectiveEndDate = System.now();
            serviceTerritoryMembershipToUpdate.add(serverritoryMember);
        }
        if(!serviceTerritoryMembershipToUpdate.isEmpty()){
            update serviceTerritoryMembershipToUpdate;
        }
    }

    private List<ServiceTerritoryMember> getServiceTerritoryMembers(List<String> userIds){
        return [SELECT Id, EffectiveStartDate, EffectiveEndDate
                FROM ServiceTerritoryMember
                WHERE EffectiveEndDate = null
                AND ServiceResource.RelatedRecordId IN: userIds
                AND ServiceTerritoryId IN: [SELECT Id
                                            FROM ServiceTerritory
                                            WHERE Building_Id__c IN: newBuildingsMap.keySet()]];
    }

    private List<ServiceResource> verifyServiceResources(List<Id> userIds){
        List<ServiceResource> serviceResources = new List<ServiceResource>();
        List<ServiceResource> serviceResourcesToUpsert = new List<ServiceResource>();
        List<Id> newUserIds = new List<Id>();
        for(ServiceResource serviceResourceRecord : [SELECT Id, Name, IsActive, RelatedRecordId
                                                     FROM ServiceResource
                                                     WHERE RelatedRecordId IN: userIds]){
            userWithServiceResourceMap.put(serviceResourceRecord.RelatedRecordId, serviceResourceRecord);
        }
        for(Building__c building : newBuildings){
            List<String> updatedFieldAPIs = buildingIdToUpdatedFieldAPIs.get(building.Id);
            for(String fieldAPIName : updatedFieldAPIs){
                String configFieldValue = (String)building.get(fieldAPIName);
                if(userWithServiceResourceMap.containsKey(configFieldValue) &&
                   userWithServiceResourceMap.get(configFieldValue).IsActive){
                    serviceResources.add(userWithServiceResourceMap.get(configFieldValue));
                }else{
                    newUserIds.add(configFieldValue);
                }
            }
        }
        for (User usr : [SELECT Id, Name, Salesforce_Scheduler_User__c
                         FROM User
                         WHERE Id IN: newUserIds]){
            ServiceResource serviceResourceRecord = new ServiceResource();
            if (userWithServiceResourceMap.containsKey(usr.Id)) {
                serviceResourceRecord.Id = userWithServiceResourceMap.get(usr.Id).Id;
            }
            serviceResourceRecord.RelatedRecordId = usr.Id;
            serviceResourceRecord.Name = usr.Name;
            serviceResourceRecord.ResourceType = RESOURCE_TYPE_TECHNICIAN;
            serviceResourceRecord.isActive = true;
            serviceResourcesToUpsert.add(serviceResourceRecord);
        }
        if (!serviceResourcesToUpsert.isEmpty()) {
            upsert serviceResourcesToUpsert;
        }
        if (!newUserIds.isEmpty()) {
            addSalesforceSchedulerLicense(newUserIds);
        }
        serviceResources.addAll(serviceResourcesToUpsert);
        return serviceResources;
    }

    @future
    public static void addSalesforceSchedulerLicense(List<Id> userIds) {
        Map<Id, PermissionSetAssignment> userWithPermissionSetMap = new Map<Id, PermissionSetAssignment>();
        Id permissionSetId = [SELECT Id
                              FROM PermissionSet
                              WHERE Name =: SALESFORCE_SCHEDULER_PERM_SET_NAME
                              LIMIT 1]?.Id;
        for (PermissionSetAssignment psAssignment : [SELECT Id, PermissionSetId, AssigneeId
                                                    FROM PermissionSetAssignment
                                                    WHERE AssigneeId IN: userIds
                                                        AND PermissionSetId =:permissionSetId]) {
            userWithPermissionSetMap.put(psAssignment.AssigneeId, psAssignment);
        }
        List<PermissionSetAssignment> permissionSetAssignmentsToInsert = new List<PermissionSetAssignment>();
        for (Id userId : userIds) {
            if (!userWithPermissionSetMap.containsKey(userId)) {
                permissionSetAssignmentsToInsert.add(new PermissionSetAssignment(
                    PermissionSetId = permissionSetId,
                    AssigneeId = userId
                ));
            }
        }
        if(!permissionSetAssignmentsToInsert.isEmpty()){
            insert permissionSetAssignmentsToInsert;
        }
    }

    private void createServiceTerritoryMembership(List<ServiceResource> serviceResources){
        Map<Id, ServiceResource> userWithServiceResourceMap = new Map<Id, ServiceResource>();

        for(ServiceResource serResource: serviceResources){
            userWithServiceResourceMap.put(serResource.RelatedRecordId, serResource);
        }
        Map<Id, ServiceTerritoryMember> serviceResourceToTerrMembers = populateServiceResourceToTerrMembers(serviceResources);
        Map<Id, ServiceTerritory> buildingsToServiceTerritory = populateBuildingsToServiceTerritory();
        ServiceTerritoryMemberSelector serviceTerritoryMemberSelector = new ServiceTerritoryMemberSelector();
        Map<String, ServiceTerritoryMember> stmMap = new Map<String, ServiceTerritoryMember>();
        for (ServiceTerritoryMember stm : serviceTerritoryMemberSelector.getServiceTerritoryMembersForHosts(new List<Id>(buildingsToServiceTerritory.keyset()), new List<Id>(new Map<Id, ServiceResource>(serviceResources).keySet()))) {
            stmMap.put(getServiceTerritoryMemberUniqueKey(stm.ServiceResourceId, stm.ServiceTerritoryId), stm);
        }
        List<ServiceTerritoryMember> serviceResourceMembersToUpsert = new List<ServiceTerritoryMember>();
        Map<String, OperatingHours> buildingToOperatingHours = getBuildingToOperatingHours();
        for(Building__c building: newBuildings){
            List<String> updatedFieldAPIs = buildingIdToUpdatedFieldAPIs.get(building.Id);
            for(String fieldAPIName : updatedFieldAPIs){
                String configFieldValue = (String)building.get(fieldAPIName);
                ServiceResource serviceResourceRecord = userWithServiceResourceMap.get(configFieldValue);
                ServiceTerritoryMember serviceTerritoryMemberRecord = new ServiceTerritoryMember();
                serviceTerritoryMemberRecord.ServiceTerritoryId = buildingsToServiceTerritory.get(building.Id)?.Id;
                if (serviceTerritoryMemberRecord.ServiceTerritoryId != null && stmMap.containsKey(getServiceTerritoryMemberUniqueKey(serviceResourceRecord.Id, serviceTerritoryMemberRecord.ServiceTerritoryId))) {
                    serviceTerritoryMemberRecord.Id = stmMap.get(getServiceTerritoryMemberUniqueKey(serviceResourceRecord.Id, serviceTerritoryMemberRecord.ServiceTerritoryId)).Id;
                }
                serviceTerritoryMemberRecord.ServiceResourceId = serviceResourceRecord?.Id;
                serviceTerritoryMemberRecord.Role = roleSettings.containsKey(fieldAPIName + SUFFIX_ROLE) ? roleSettings.get(fieldAPIName + SUFFIX_ROLE) : null;
                serviceTerritoryMemberRecord.EffectiveStartDate = System.now();
                serviceTerritoryMemberRecord.EffectiveEndDate =  null;
                serviceTerritoryMemberRecord.OperatingHoursId = buildingToOperatingHours?.get(getServiceTerritoryName(configFieldValue, building.Name))?.Id;
                serviceTerritoryMemberRecord.TerritoryType = ((serviceResourceToTerrMembers.isEmpty() || serviceResourceToTerrMembers.get(serviceResourceRecord.Id) == null)? TERRITORY_TYPE_PRIMARY: TERRITORY_TYPE_SECONDARY);
                serviceResourceMembersToUpsert.add(serviceTerritoryMemberRecord);
            }
        }
        dml.add(serviceResourceMembersToUpsert, DmlConsolidator.Operation.FOR_UPSERT);
    }

    private String getServiceTerritoryMemberUniqueKey(Id serviceResourceId, Id serviceTerritoryId){
        return serviceResourceId + '-' + serviceTerritoryId;
    }

    private Map<Id, ServiceTerritoryMember> populateServiceResourceToTerrMembers (List<ServiceResource> serviceResources){
        Map<Id, ServiceTerritoryMember> serviceResourceToTerrMembers = new Map<Id, ServiceTerritoryMember>();
        for(ServiceTerritoryMember serviceTerrMember: [SELECT Id, ServiceTerritoryId, ServiceResourceId, Role, TerritoryType
                                                       FROM ServiceTerritoryMember
                                                       WHERE ServiceResourceId IN: serviceResources
                                                           AND TerritoryType =: TERRITORY_TYPE_PRIMARY
                                                           AND (EffectiveEndDate = null OR EffectiveEndDate >= TODAY)]){
            serviceResourceToTerrMembers.put(serviceTerrMember.ServiceResourceId, serviceTerrMember);
        }
        return serviceResourceToTerrMembers;
    }

    private Map<Id, ServiceTerritory> populateBuildingsToServiceTerritory (){
        Map<Id, ServiceTerritory> buildingsToServiceTerritory = new Map<Id, ServiceTerritory>();
        for(ServiceTerritory servTerritory: [SELECT Id, OperatingHoursId, Building_Id__c
                                             FROM ServiceTerritory
                                             WHERE Building_Id__c IN: newBuildingsMap.keySet()]){
            buildingsToServiceTerritory.put(servTerritory.Building_Id__c, servTerritory);
        }
        return buildingsToServiceTerritory;
    }

    private Map<String, OperatingHours> getBuildingToOperatingHours(){
        List<OperatingHours> opHoursToInsert = new List<OperatingHours>();
        Map<String,List<TimeSlot>> operatingHourToTimeSlots = new Map<String,List<TimeSlot>>();
        for(OperatingHours opHrs : [SELECT Id, Name, Building_Id__c, TimeZone,
                                    (SELECT Id, OperatingHoursId, DayOfWeek, StartTime, EndTime
                                     FROM TimeSlots)
                                    FROM OperatingHours
                                    WHERE Building_Id__c IN: newBuildingsMap.keySet()
                                        AND Host_Id__c = null]){
            List<String> updatedFieldAPIs = buildingIdToUpdatedFieldAPIs.get(opHrs.Building_Id__c);
            for(String fieldAPIName : updatedFieldAPIs){
                String configFieldValue = (String)newBuildingsMap.get(opHrs.Building_Id__c).get(fieldAPIName);
                OperatingHours newOppHrs = opHrs.clone(false, true, false, false);
                newOppHrs.Building_Id__c = opHrs.Building_Id__c;
                newOppHrs.Host_Id__c = userWithServiceResourceMap.get(configFieldValue)?.Id;
                newOppHrs.Name = getServiceTerritoryName(configFieldValue, newBuildingsMap.get(opHrs.Building_Id__c).Name);
                opHoursToInsert.add(newOppHrs);
                if(roleSettings.containsKey(fieldAPIName + SUFFIX_TIME_SLOT_NEEDED) &&
                  roleSettings.get(fieldAPIName + SUFFIX_TIME_SLOT_NEEDED) == 'true'){
                  operatingHourToTimeSlots.put(newOppHrs.Name, opHrs.TimeSlots);
                }
            }
        }
        insert opHoursToInsert;
        insertTimeSlotsForOppHrs(opHoursToInsert, operatingHourToTimeSlots);

        Map<String, OperatingHours> buildingToOperatingHours = new Map<String, OperatingHours>();
        for(OperatingHours opHour : opHoursToInsert){
            buildingToOperatingHours.put(opHour.Name, opHour);
        }
        return buildingToOperatingHours;
    }

    private String getServiceTerritoryName(String userId, String buildingName){
        if(String.isBlank(userId) || String.isBlank(buildingName)){
            return null;
        }
        String serviceTerritoryName;
        if(userWithServiceResourceMap != null && userWithServiceResourceMap.containsKey(userId)){
            serviceTerritoryName = userWithServiceResourceMap.get(userId).Name +' - ';
        }
        serviceTerritoryName += buildingName + ' - Operating Hours';
        return serviceTerritoryName;
    }

    private void insertTimeSlotsForOppHrs(List<OperatingHours> opHoursToInsert, Map<String,List<TimeSlot>> operatingHourToTimeSlots){
        List<TimeSlot> timeSlotsToInsert = new List<TimeSlot>();
        for(OperatingHours oppHours : opHoursToInsert){
            if(!operatingHourToTimeSlots.containsKey(oppHours.Name)){
                continue;
            }
            for(TimeSlot timeSlot : operatingHourToTimeSlots.get(oppHours.Name)){
                TimeSlot newTimeSlot = timeSlot.clone(false, true, false, false);
                newTimeSlot.OperatingHoursId = oppHours.Id;
                timeSlotsToInsert.add(newTimeSlot);
            }
        }
        insert timeSlotsToInsert;
    }

    public void populateRoleSettingWrapperMap() {
        Map<String, Building_Player_Role_Setting__mdt> buildingRoleSettings = Building_Player_Role_Setting__mdt.getAll();
        for (String roleName : buildingRoleSettings.keySet()) {
            String fieldAPIName = buildingRoleSettings.get(roleName).label;
            roleSettings.put(fieldAPIName + SUFFIX_TIME_SLOT_NEEDED, String.valueOf(buildingRoleSettings.get(roleName).Is_Time_Slot_Needed__c).toLowerCase());
            roleSettings.put(fieldAPIName + SUFFIX_ROLE, buildingRoleSettings.get(roleName).Role__c);
        }
    }
}