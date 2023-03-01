/************************************************************************************************************************************
    Author        : Stepan Vardzal
    Description   : Web service dedicated to get available time slots for tour booking
    History:
----------------------------------------------------------------------------------------------------------------------------------
    VERSION       DATE          AUTHOR                DETAIL                  ISSUE
    1             2/03/21       Stepan Vardzal        Initial Developement    ST-9985
**************************************************************************************************************************************/
@RestResource(urlMapping='/scheduling/get_available_timeslots')
global with sharing class RESTAPISchedulerTimeSlotsV1 {

    private static final String SUCCESS_RESPONSE_MESSAGE = 'Available time slots retrieved successfully';
    private static TimeSlotsResponse response = new TimeSlotsResponse();

    @HttpPost 
    global static TimeSlotsResponse getSlots(RESTAPITourModelsV2.GetTimeSlotsRequest body) {
        try {
            response.timeSlots = new AvailableTimeSlotService(body).setWorkType()
                                                                    .getAvailableResource()
                                                                    .getServiceResourceIds()
                                                                    .getAppointmentSlots()
                                                                    .getAvailableSlots();
            response.success = true;
            response.message = SUCCESS_RESPONSE_MESSAGE;
        } catch (Exception ex) {
            if (ex.getMessage() != AvailableTimeSlotService.ERROR_RESPONSE_MESSAGE_NO_AVAILABLE_RESOURCES) {
                ApexDebugLog.logException(ex, null, 'RESTAPISchedulerTimeSlotsV1', 'getSlots');
            }
            response.success = false;
            response.message = ex.getMessage();
        }
        return response;
    }
        
    global class TimeSlotsResponse {
        @TestVisible
        private List<RESTAPITourModelsV2.AvailableTimeSlot> timeSlots;
        @TestVisible
        private Boolean success;
        @TestVisible
        private String message;
    }
}