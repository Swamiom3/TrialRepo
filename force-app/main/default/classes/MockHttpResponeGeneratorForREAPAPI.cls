/************************************************************************************************************************************
    Author      :   Vaishnavi Khandar
    Description :   This class has mock response for REAP Integration API response used in REAPIntegrationUtilsTest and 
                    BatchToUpdateREAPDetailsOnBuildingLeaseTest and ScheduledBatchForREAPIntergrationTest classes.
    History     :
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION     DATE                AUTHOR                  DETAIL
    1           18 November 2020    Vaishnavi Khandar       Initial Developement
**************************************************************************************************************************************/
global class MockHttpResponeGeneratorForREAPAPI implements HttpCalloutMock{
    global HTTPResponse respond(HTTPRequest req) { 
       String jsonData='{"properties":[{"location_uuid":"4112a913-cffb-413e-816d-5cc7f268257b","property_uuid":"c7d12e59c05f3726305bcab8ef0a8c94","measure_unit":"Per SM","leases":[{"lease_uuid":"f7390f20277dd6c334c44b2fcc95c6a1","possession_date":"2017-12-15","type":"Net Pass Through","lease_expiration_date":"2033-11-30","date_of_lease_agreement":"2017-12-13","lease_commencement_date":"2018-07-01","lease_original_commencement_date":"2018-07-01","lease_financial_securites":[{"type":"Guarantee","amount":13600644.182528,"next_burndown_date":"2022-07-01","next_burndown_amount":10514874.2546504,"lease_financial_security_uuid":"977b6f1acbcf7a9fc983623b3beb28c5"},{"type":"Letter of Credit","amount":3103155.0,"next_burndown_date":"2021-11-16","next_burndown_amount":2068770.0}],"areas":[{"area_uuid":"e0035b2aeda044c9491d73971be295cd","area_description":"Fls 4-5","rsf":51661.34},{"area_uuid":"3684044603279aa2be0eb0fe760c761a","area_description":"Fls 1-3","rsf":65724.37}]}]},{"location_uuid":"3f53a320-8251-0130-f786-123138068411","property_uuid":"06deaba4bf175187315a6cb9f1d14188","measure_unit":"Per SM","leases":[{"lease_uuid":"84384081308495865618889b7bad5fa1","possession_date":"2010-03-10","type":"Net Pass Through","lease_expiration_date":"2020-08-31","date_of_lease_agreement":"2018-12-01","lease_commencement_date":"2015-05-01","lease_original_commencement_date":"2010-07-01","lease_financial_securites":[],"areas":[]}]}]}';
       HttpResponse res = new HttpResponse();
       res.setHeader('Content-Type', 'application/json');
       res.setBody(jsonData);
       res.setStatusCode(200);
       return res;
    }
}