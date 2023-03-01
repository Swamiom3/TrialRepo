@isTest
public class CPQAddPromosAPIMock implements HttpCalloutMock {
private String tokenResponse = '{"accessToken":"1234","expiresIn":3,"tokenType":"test"}';
private List<String> statusCodes;
private String serviceResponse = ',"currentPrice":{"price":1038},"discounts":[{"termTypeLabel":"6M","termTypeLength":6,'
                                    +'"baseDiscount":0.39,"promotions":[{"name":"curve1","dataPoints":[{"month":1,"value":0.4},'
                                    +'{"month":2,"value":0.3},{"month":3,"value":0.2},{"month":4,"value":0},{"month":5,"value":0},'
                                    +'{"month":6,"value":0}]}]}]}]';
    public CPQAddPromosAPIMock(String inventoryUUID, String statusCode){
        serviceResponse = '[{"uuid":"'+inventoryUUID+'"'+serviceResponse;
        statusCodes = new List<String>{statusCode};
    }   
    public HTTPResponse respond(HTTPRequest request) {
        if(request.getEndpoint() == 'callout:Mulesofte_eAPI'){
            String jsonString = tokenResponse;            
            HTTPResponse response = new HTTPResponse();
            response.setHeader('Content-Type', 'text/json');
            response.setBody(jsonString);
            response.setStatusCode(Integer.valueof(statusCodes[0]));
            return response;
        }else{
            String jsonString = Integer.valueof(statusCodes[0]) == 201 ? '' : serviceResponse;
			HTTPResponse response = new HTTPResponse();
            response.setHeader('Content-Type', 'text/json');
            response.setBody(jsonString);
            response.setStatusCode(Integer.valueof(statusCodes[0]));
            return response;
        }
    }
}