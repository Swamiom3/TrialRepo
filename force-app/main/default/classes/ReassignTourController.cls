/*************************************************************************************************************************************
 Author      :   Salesforce
 Description :   This is a controller class for Reassigning Tours
 --------------------------------------------------------------------------------------------------------------------------------------
 VERSION         DATE            AUTHOR              DETAIL
 1               14 Oct 2021     Salesforce       Initial Deployment
 **************************************************************************************************************************************/
public with sharing class ReassignTourController {
    @AuraEnabled
    public static String reassignServiceResource(Id buildingId, Id serviceAppointmentId, Id userId) {
        Savepoint sp = Database.setSavepoint();
        try {
            ServiceTerritoryMemberSelector serviceTerritoryMemberSelector = new ServiceTerritoryMemberSelector();
            ServiceResource resourceRecord = ReassignTourHelper.createOrUpdateServiceResources(new List<Id> { userId })[0];
            ReassignTourHelper.addSalesforceSchedulerLicense(new Set<Id> { userId });
            List<ServiceTerritoryMember> serviceTerritoryMembers = serviceTerritoryMemberSelector.getServiceTerritoryMembers(new List<Id> { buildingId }, new List<Id> { userId });
            if (serviceTerritoryMembers.isEmpty()) {
                ReassignTourHelper.createServiceTerritoryMembership(resourceRecord, buildingId);
            }
            // Update Tour record
            updateServiceAppointment(serviceAppointmentId, userId);
            
            // Update Tour Assignment to Service Resource record
            updateAssignedResource(serviceAppointmentId, resourceRecord.Id);
            return 'success';
        } catch (Exception e) {
            Database.rollback(sp);
            ApexDebugLog.logException(e, '', 'ReassignServiceResourceController', 'reassignServiceResource');
            throw new AuraHandledException(e.getMessage());
        }
    }

    private static void updateServiceAppointment(Id serviceAppointmentId, Id userId) {
        ServiceAppointment serviceAppointmentRecord = new ServiceAppointment(Id = serviceAppointmentId, OwnerId = userId);
        update serviceAppointmentRecord;
    }

    private static void updateAssignedResource(Id serviceAppointmentId, Id serviceResourceId) {
        List<AssignedResource> assignedResourcesToUpdate = new List<AssignedResource>();
        for(AssignedResource aResource: [SELECT Id, ServiceResourceId 
                                         FROM AssignedResource 
                                         WHERE ServiceAppointmentId =:serviceAppointmentId ]){
            aResource.ServiceResourceId = serviceResourceId;
            assignedResourcesToUpdate.add(aResource);
        }
        if(!assignedResourcesToUpdate.isEmpty()){
            update assignedResourcesToUpdate;
        }
    }
}