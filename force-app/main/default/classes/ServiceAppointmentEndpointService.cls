/************************************************************************************************************************************
    Author        : Liubomyr Mishchykha
    Description   : Service class used to construct payload for scheduling service appointments via endpoint
    History:
----------------------------------------------------------------------------------------------------------------------------------
    VERSION       DATE          AUTHOR                DETAIL                  ISSUE
    1             1/26/21       Liubomyr Mishchykha   Initial Developement    ST-10000    
**************************************************************************************************************************************/
public with sharing class ServiceAppointmentEndpointService {

    @TestVisible
    private ScheduleServiceAppointmentRequest ssar;

    public ServiceAppointmentEndpointService() {
        ssar = new ScheduleServiceAppointmentRequest();
        ssar.serviceAppointment = new ServiceAppointmentFields();
        ssar.serviceAppointment.extendedFields = new List<ExtendedField>();
        ssar.assignedResources = new List<AssignedResource>();
    }

    public ServiceAppointmentEndpointService setSAField(String name, String value) {
        if (String.isBlank(name) || String.isBlank(value)) {
            return this;
        }
        ExtendedField field = new ExtendedField();
        field.name = name;
        field.value = value;
        ssar.serviceAppointment.extendedFields.add(field);
        return this;
    }

    public ServiceAppointmentEndpointService setSAParentId(String parentId) {
        if (String.isNotBlank(ssar.serviceAppointmentId)) {
            return this;
        }
        ssar.serviceAppointment.parentRecordId = parentId;
        return this;
    }

    public ServiceAppointmentEndpointService setServiceResource(Id resourceId) {
        AssignedResource resource = new AssignedResource();
        resource.serviceResourceId = resourceId;
        resource.isPrimaryResource = true;
        resource.isRequiredResource = true;
        ssar.assignedResources.add(resource);
        return this;
    }

    public ServiceAppointmentEndpointService setServiceAppointmentId(Id serviceAppointmentId) {
        if (String.isBlank(serviceAppointmentId)) {
            return this;
        }
        ssar.serviceAppointmentId = serviceAppointmentId;
        return this;
    }

    public class ScheduleServiceAppointmentRequest {
        public Id serviceAppointmentId;
        public ServiceAppointmentFields serviceAppointment;
        public List<AssignedResource> assignedResources;
    }

    public class ServiceAppointmentFields {
        public String additionalInformation;
        public String appointmentType;
        public String accountId;
        public String contactId;
        public String comments;
        public String parentRecordId;
        public String serviceTerritoryId;
        public String serviceResourceId;
        public String street;
        public String city;
        public String country;
        public String manufacturer;
        public String postalCode;
        public String schedStartTime;
        public String schedEndTime;
        public String description;
        public String subject;
        public String phone;
        public String email;
        public String workTypeGroupId;
        public String workTypeId;
        public String schedulingPolicyId; 
        public List<ExtendedField> extendedFields;
    }

    public class ExtendedField {
        public String name;
        public String value;
    }

    public class AssignedResource {
        public Boolean isPrimaryResource;
        public Boolean isRequiredResource;
        public Id serviceResourceId;
        public List<ExtendedField> extendedFields;
    }

    public String preparePayload() {
        return JSON.serialize(ssar, true);
    }
}