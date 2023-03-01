/************************************************************************************************************************************
    Author      :   Chandra Teja 
    Description :   This class has mock response for rev star API response used in RevstarUtilsTest and 
                    BatchToUpdateRevstarPriceOnOppLITest and SchedBatchToRetryUpdateRevstarPriceTest classes.
    History     :
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION     DATE                AUTHOR                  DETAIL
    1           12 June 2020        Chandra Teja        Initial Developement
**************************************************************************************************************************************/
global class MockHttpResponeGeneratorForRevstarAPI implements HttpCalloutMock{
    global HTTPResponse respond(HTTPRequest req) {         
       HttpResponse res = new HttpResponse();
       res.setHeader('Content-Type', 'application/json');
       res.setBody('{"status" : 200, "price" : 450, "priceType" : "MIN", "currency" : "EUR"}');
       res.setStatusCode(200);
       return res;
    }
}