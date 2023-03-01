/*************************************************************************************************************************************
 Author      :   Salesforce
 Description :   This is a service class for Reassigning Tours
 --------------------------------------------------------------------------------------------------------------------------------------
 VERSION         DATE            AUTHOR              DETAIL
 1               14 Oct 2021     Salesforce       Initial Deployment
 **************************************************************************************************************************************/
public with sharing class ReassignTourHelper {
    @TestVisible
    private static final String RESOURCE_TYPE_TECHNICIAN = 'T';
    private static final String ROLE_REASSIGNED_HOST = 'Reassigned Host';
    private static final String SALESFORCE_SCHEDULER_PERM_SET_NAME = 'Salesforce_Scheduler_Resource';
    @TestVisible
    private static final String TERRITORY_TYPE_PRIMARY = 'P';
    @TestVisible
    private static final String TERRITORY_TYPE_SECONDARY = 'S';

    public static void createServiceTerritoryMembership(ServiceResource serviceResource, Id buildingId) {
        Map<Id, ServiceTerritoryMember> serviceResourceToTerrMembers = getServiceResourceToTerrMembers(new List<ServiceResource> { serviceResource });
        Map<Id, ServiceTerritory> buildingsToServiceTerritory = getBuildingsToServiceTerritory(new List<Id> { buildingId });
        Map<String, OperatingHours> buildingToOperatingHours = prepareHostOperatingHours(buildingId, serviceResource, false);
        ServiceTerritoryMember serviceTerritoryMemberRecord = new ServiceTerritoryMember();
        serviceTerritoryMemberRecord.ServiceTerritoryId = buildingsToServiceTerritory.get(buildingId)?.Id;
        serviceTerritoryMemberRecord.ServiceResourceId = serviceResource.Id;
        serviceTerritoryMemberRecord.Role = ROLE_REASSIGNED_HOST;
        serviceTerritoryMemberRecord.EffectiveStartDate = System.now();
        serviceTerritoryMemberRecord.EffectiveEndDate =  null;
        serviceTerritoryMemberRecord.OperatingHoursId = buildingToOperatingHours?.get(getServiceTerritoryName(serviceResource.Name, buildingsToServiceTerritory.get(buildingId)?.Name))?.Id;
        serviceTerritoryMemberRecord.TerritoryType = ((serviceResourceToTerrMembers.isEmpty() || serviceResourceToTerrMembers.get(serviceResource.Id) == null)? TERRITORY_TYPE_PRIMARY: TERRITORY_TYPE_SECONDARY);
        insert serviceTerritoryMemberRecord;
    }

    public static Map<Id, ServiceResource> getUserWithServiceResource(List<Id> userIds) {
        Map<Id, ServiceResource> userIdToServiceResource = new Map<Id, ServiceResource>();
        ServiceResourceSelector serviceResourceSelector = new ServiceResourceSelector();
        for(ServiceResource serviceResourceRecord : serviceResourceSelector.getServiceResourcesByUserIds(userIds)){
            userIdToServiceResource.put(serviceResourceRecord.RelatedRecordId, serviceResourceRecord);
        }
        return userIdToServiceResource;
    }

    public static List<ServiceResource> createOrUpdateServiceResources(List<Id> userIds) {
        List<ServiceResource> serviceResources = new List<ServiceResource>();
        List<ServiceResource> serviceResourcesToUpsert = new List<ServiceResource>();
        UserSelector userSelector = new UserSelector();
        Map<Id, ServiceResource> userIdToServiceResource =  getUserWithServiceResource(userIds);
        for (User usr : userSelector.getUsersById(userIds)){
            if (userIdToServiceResource.containsKey(usr.Id) && userIdToServiceResource.get(usr.Id).isActive) {
                serviceResources.add(userIdToServiceResource.get(usr.Id));
                continue;
            }
            ServiceResource serviceResourceRecord = new ServiceResource();
            if (userIdToServiceResource.containsKey(usr.Id)) {
                serviceResourceRecord.Id = userIdToServiceResource.get(usr.Id).Id;
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
        serviceResources.addAll(serviceResourcesToUpsert);
        return serviceResources;
    }

    @future
    public static void addSalesforceSchedulerLicense(Set<Id> userIds) {
        Set<Id> usersWithPermission = new Set<Id>();
        Id permissionSetId = [SELECT Id
                              FROM PermissionSet
                              WHERE Name =: SALESFORCE_SCHEDULER_PERM_SET_NAME
                              LIMIT 1]?.Id;
        for (PermissionSetAssignment psAssignment : [SELECT Id, PermissionSetId, AssigneeId
                                                    FROM PermissionSetAssignment
                                                    WHERE AssigneeId IN: userIds
                                                        AND PermissionSetId =:permissionSetId]) {
            usersWithPermission.add(psAssignment.AssigneeId);
        }
        List<PermissionSetAssignment> permissionSetAssignmentsToInsert = new List<PermissionSetAssignment>();
        userIds.removeAll(usersWithPermission);
        for (Id userId : userIds) {
            permissionSetAssignmentsToInsert.add(new PermissionSetAssignment(
                PermissionSetId = permissionSetId,
                AssigneeId = userId
            ));
        }
        if(!permissionSetAssignmentsToInsert.isEmpty()){
            insert permissionSetAssignmentsToInsert;
        }
    }

    private static Map<String, OperatingHours> prepareHostOperatingHours(Id buildingId, ServiceResource serviceResource, Boolean isTimeSlotNeeded) {
        List<OperatingHours> opHoursToInsert = new List<OperatingHours>();
        Map<String,List<TimeSlot>> operatingHourToTimeSlots = new Map<String,List<TimeSlot>>();
        OperatingHoursSelector operatingHoursSelector = new OperatingHoursSelector();
        for(OperatingHours opHrs : operatingHoursSelector.getBuildingOperatingHours(buildingId)) {
                OperatingHours newOppHrs = opHrs.clone(false, true, false, false);
                newOppHrs.Building_Id__c = opHrs.Building_Id__c;
                newOppHrs.Host_Id__c = serviceResource.Id;
                newOppHrs.Name = getServiceTerritoryName(serviceResource.Name, opHrs.Building_Id__r.Name);
                opHoursToInsert.add(newOppHrs);
                if (isTimeSlotNeeded) {
                  operatingHourToTimeSlots.put(newOppHrs.Name, opHrs.TimeSlots);
                }
        }
        insert opHoursToInsert;
        if (isTimeSlotNeeded) {
            insertTimeSlotsForOppHrs(opHoursToInsert, operatingHourToTimeSlots);
        }
        Map<String, OperatingHours> buildingToOperatingHours = new Map<String, OperatingHours>();
        for(OperatingHours opHour : opHoursToInsert){
            buildingToOperatingHours.put(opHour.Name, opHour);
        }
        return buildingToOperatingHours;
    }

    private static String getServiceTerritoryName(String userName, String buildingName){
        if(String.isBlank(userName) || String.isBlank(buildingName)){
            return null;
        }
        return userName + ' ' + buildingName + ' - Operating Hours';
    }

    private static void insertTimeSlotsForOppHrs(List<OperatingHours> opHoursToInsert, Map<String,List<TimeSlot>> operatingHourToTimeSlots){
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

    private static Map<Id, ServiceTerritory> getBuildingsToServiceTerritory (List<Id> buildingIds){
        Map<Id, ServiceTerritory> buildingsToServiceTerritory = new Map<Id, ServiceTerritory>();
        for(ServiceTerritory servTerritory: [SELECT Id, Name, OperatingHoursId, Building_Id__c
                                             FROM ServiceTerritory
                                             WHERE Building_Id__c IN :buildingIds]){
            buildingsToServiceTerritory.put(servTerritory.Building_Id__c, servTerritory);
        }
        return buildingsToServiceTerritory;
    }

    private static Map<Id, ServiceTerritoryMember> getServiceResourceToTerrMembers (List<ServiceResource> serviceResources){
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
}