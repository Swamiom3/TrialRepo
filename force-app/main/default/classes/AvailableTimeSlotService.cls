/************************************************************************************************************************************
    Author        : Stepan Vardzal
    Description   : Business logic to get available time slots for tour booking that is used from different entry points.
    Test Classes  : AvailableTimeSlotServiceTest, RESTAPISchedulerTimeSlotsV1Test
    History:
----------------------------------------------------------------------------------------------------------------------------------
    VERSION       DATE          AUTHOR                DETAIL                  ISSUE
    1             2/03/21       Stepan Vardzal        Initial Developement    ST-9985
**************************************************************************************************************************************/
public with sharing class AvailableTimeSlotService {

    private RESTAPITourModelsV2.GetTimeSlotsRequest body;
    private lxscheduler.WorkType workType;
    @TestVisible
    private Building__c building;
    private DateTime startTime;
    private DateTime endTime;
    private List<GetAppointmentSlotsOutput> slots;
    @TestVisible
    private List<GetAppointmentCandidatesOutput> appointmentCandidates;
    @TestVisible
    private List<String> resourceIds;
    @TestVisible
    private List<RESTAPITourModelsV2.AvailableTimeSlot> availableSlots;
    private BuildingSelector buildingSelector = new BuildingSelector();
    private ServiceTerritorySelector serviceTerritorySelector = new ServiceTerritorySelector();
    private NonOperatingHoursSelector nonOperatingHoursSelector = new NonOperatingHoursSelector();

    @TestVisible
    private static final String SUCCESS_RESPONSE_MESSAGE = 'Available time slots retrieved successfully';
    @TestVisible
    private static final String ERROR_RESPONSE_MESSAGE_BUILDING_NOT_TOURABLE = 'The building is not tourable';
    public static final String ERROR_RESPONSE_MESSAGE_NO_AVAILABLE_RESOURCES = 'There are no available resources';
    @TestVisible
    private static final String ERROR_RESPONSE_MESSAGE_NO_BUILDING_FOUND = 'No building found';
    @TestVisible
    private static final String ERROR_RESPONSE_MESSAGE_NO_WORK_TYPE_FOUND = 'There is no established Tour Schedule of such Tour Format for the building with UUID {0}';

    public AvailableTimeSlotService(RESTAPITourModelsV2.GetTimeSlotsRequest body) {
        this.body = body;
        building = getBuilding();
        startTime = (DateTime) JSON.deserialize('"' + DateUtilities.getTimeWithTimeZone(body.start_time, building.Time_Zone__c) + '"', DateTime.class);
        endTime = (DateTime) JSON.deserialize('"' + DateUtilities.getTimeWithTimeZone(body.end_time, building.Time_Zone__c) + '"', DateTime.class);
    }

    @TestVisible
    private AvailableTimeSlotService() {}

    private Building__c getBuilding() {
        List<Building__c> selectedBuildings = buildingSelector.getBuildingsByUuidWithTourSchedules(body.building_id);
        if (selectedBuildings.isEmpty()) {
            throw new AvailableTimeSlotException(ERROR_RESPONSE_MESSAGE_NO_BUILDING_FOUND);
        }
        return selectedBuildings[0];
    }

    @TestVisible
    private String getWorkTypeId() {
        String workTypeId = SalesforceSchedulerUtility.getBuildingTourFormatWorkTypeId(building.Id, body.tour_format);
        if (workTypeId == null) {
            throw new AvailableTimeSlotException(String.format(ERROR_RESPONSE_MESSAGE_NO_WORK_TYPE_FOUND, new List<String>{ body.building_id }));
        }
        return workTypeId;
    }

    public AvailableTimeSlotService setWorkType() {
        workType = new lxscheduler.WorkTypeBuilder()
            .setId(getWorkTypeId())
            .build();
        return this;
    }

    private ServiceTerritory getActiveServiceTerritory() {
        List<ServiceTerritory> selectedServiceTerritory = serviceTerritorySelector.getActiveServiceTerritoryByBuildingUUID(new List<String> { body.building_id });
        if (selectedServiceTerritory.isEmpty()) {
            throw new AvailableTimeSlotException(ERROR_RESPONSE_MESSAGE_BUILDING_NOT_TOURABLE);
        }
        return selectedServiceTerritory[0];
    }

    public AvailableTimeSlotService getAvailableResource() {
        lxscheduler.GetAppointmentCandidatesInput input = new lxscheduler.GetAppointmentCandidatesInputBuilder()
            .setWorkType(workType)
            .setTerritoryIds(new List<String> { getActiveServiceTerritory()?.Id })
            .setStartTime(startTime.format(GlobalConstants.DATE_FORMAT_GMT, building.Time_Zone__c))
            .setEndTime(endTime.format(GlobalConstants.DATE_FORMAT_GMT, building.Time_Zone__c))
            .setApiVersion(Double.valueOf('53.0'))
            .build();
        appointmentCandidates = (List<GetAppointmentCandidatesOutput>) (JSON.deserialize(lxscheduler.SchedulerResources.getAppointmentCandidates(input),
                                                                        List<GetAppointmentCandidatesOutput>.class));
        return this;
    }

    public AvailableTimeSlotService getServiceResourceIds() {
        Set<String> resources = new Set<String>();
        if (appointmentCandidates.isEmpty()) {
            throw new AvailableTimeSlotException(ERROR_RESPONSE_MESSAGE_NO_AVAILABLE_RESOURCES);
        }
        for (GetAppointmentCandidatesOutput appointmentCandidate : appointmentCandidates) {
            resources.addAll(appointmentCandidate.resources);
        }
        resourceIds = new List<String>(resources);
    return this;
    }

    public AvailableTimeSlotService getAppointmentSlots() {
        lxscheduler.GetAppointmentSlotsInputBuilder builder = new lxscheduler.GetAppointmentSlotsInputBuilder()
            .setWorkType(workType)
            .setTerritoryIds(new List<String>{ getActiveServiceTerritory()?.Id })
            .setStartTime(startTime.format(GlobalConstants.DATE_FORMAT_GMT, building.Time_Zone__c))
            .setEndTime(endTime.format(GlobalConstants.DATE_FORMAT_GMT, building.Time_Zone__c))
            .setApiVersion(Double.valueOf('53.0'));
        if (resourceIds.size() > 1) {
            builder.setPrimaryResourceId(resourceIds.remove(0));
        }
        lxscheduler.GetAppointmentSlotsInput input = builder.setRequiredResourceIds(resourceIds)
                                                            .build();
        slots = (List<GetAppointmentSlotsOutput>) (JSON.deserialize(lxscheduler.SchedulerResources.getAppointmentSlots(input), List<GetAppointmentSlotsOutput>.class));
        return this;
    }

    public List<Non_Operating_Hours__c> getNonOperatingHours() {
        return nonOperatingHoursSelector.getNonOperatingHoursByBuildingIdsAndPeriod(new List<Id> { building.Id }, 'One-Off', startTime, endTime);
    }

    public List<RESTAPITourModelsV2.AvailableTimeSlot> getAvailableSlots() {
        return removeNonOperatingHoursFromSlots(slots, getNonOperatingHours(), building.Time_Zone__c, resourceIds);
    }

    @TestVisible
    private static List<RESTAPITourModelsV2.AvailableTimeSlot> removeNonOperatingHoursFromSlots(List<GetAppointmentSlotsOutput> slots,
                                                                                                 List<Non_Operating_Hours__c> nonOperatingHours, String buildingTimeZone, List<String> resourceIds) {
        List<RESTAPITourModelsV2.AvailableTimeSlot> availableSlots = new List<RESTAPITourModelsV2.AvailableTimeSlot>();
        for (GetAppointmentSlotsOutput slot : slots) {
            Boolean slotAvailable = true;
            for (Non_Operating_Hours__c noh : nonOperatingHours) {
                if (slotIntersectsWithNonOperatingHours(slot, noh)) {
                    slotAvailable = false;
                    break;
                }
            }
            if (slotAvailable) {
                RESTAPITourModelsV2.AvailableTimeSlot availableSlot = new RESTAPITourModelsV2.AvailableTimeSlot();
                availableSlot.territoryId = slot.territoryId;
                availableSlot.serviceResourceId = resourceIds[0];
                availableSlot.remainingAppointments = slot.remainingAppointments;
                availableSlot.startTime = slot.startTime.format(GlobalConstants.DATE_FORMAT_GMT, buildingTimeZone);
                availableSlot.endTime = slot.endTime.format(GlobalConstants.DATE_FORMAT_GMT, buildingTimeZone);
                availableSlots.add(availableSlot);
            }
        }
        return availableSlots;
    }

    private static Boolean slotIntersectsWithNonOperatingHours(GetAppointmentSlotsOutput slot, Non_Operating_Hours__c noh) {
        return slot.startTime < noh.End_Time__c && slot.endTime > noh.Start_Time__c;
    }

    @TestVisible
    private class GetAppointmentSlotsOutput {
        @TestVisible
        Id territoryId;
        @TestVisible
        Integer remainingAppointments;
        @TestVisible
        DateTime startTime;
        @TestVisible
        DateTime endTime;
    }

    @TestVisible
    private class GetAppointmentCandidatesOutput {
        @TestVisible
        Id territoryId;
        @TestVisible
        List<String> resources;
        @TestVisible
        DateTime startTime;
        @TestVisible
        DateTime endTime;
    } 
    
    public class AvailableTimeSlotException extends Exception {}
}