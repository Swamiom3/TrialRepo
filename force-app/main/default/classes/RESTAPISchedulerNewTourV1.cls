/************************************************************************************************************************************
    Author        : Liubomyr Mishchykha
    Description   : Web service dedicated to booking new or rescheduling exisitng tour
    History:
----------------------------------------------------------------------------------------------------------------------------------
    VERSION       DATE          AUTHOR                DETAIL                  ISSUE
    1             1/26/21       Liubomyr Mishchykha   Initial Developement    ST-10000    
**************************************************************************************************************************************/
@RestResource(urlMapping='/scheduling/create_tour')
global with sharing class RESTAPISchedulerNewTourV1 {

    private static RESTAPITourModelsV2.Response response = new RESTAPITourModelsV2.Response();

    @HttpPost
    global static RESTAPITourModelsV2.Response scheduleTour(RESTAPITourModelsV2.Input input) {
        try {
            response.payload = new TourBookingService(input).getTourBookingRequest();
            response.success = true;
            response.message = 'Tour booking payload created successfully';
        } catch (Exception ex) {
            ApexDebugLog.logException(ex, null, 'RESTAPISchedulerNewTourV1', 'scheduleTour');
            response.success = false;
            response.message = ex.getMessage();
        }
        return response;
    }
}