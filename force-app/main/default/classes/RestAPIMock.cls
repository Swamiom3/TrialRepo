@isTest
public class RestAPIMock implements HttpCalloutMock {   
    private String buildingID;
    private List<String> statusCodes;
    private String tokenResponse = '{"accessToken":"1234","expiresIn":3,"tokenType":"test"}';
    private String serviceResponse = '[{"uuid":"1234","buildingUuid":"1234","name":"test","description":"test",'
                                               +'"price":{"currencyValue":"USD","price":"123"},"fees":[{"uuid":"5689",'
                                               +'"buildingUuid":"1234","name":"setup","description":"setuptest",'
                                               +'"price":{"currencyValue":"USD","price":"123"}}]}]';
    public RestAPIMock(String buildId, String statusCode){
        buildingID =  buildId;
        statusCodes = new List<String>{statusCode};
    }
    public HTTPResponse respond(HTTPRequest request) {        
        if(request.getEndpoint().endsWith('buildingUuid='+ buildingID)){
            String jsonString = serviceResponse;            
            HTTPResponse response = new HTTPResponse();
            response.setHeader('Content-Type', 'text/json');
            response.setBody(jsonString);
            response.setStatusCode(Integer.valueof(statusCodes[0]));
            return response;
        }else if(request.getEndpoint().endsWith('API')){
            String jsonString = tokenResponse;            
            HTTPResponse response = new HTTPResponse();
            response.setHeader('Content-Type', 'text/json');
            response.setBody(jsonString);
            response.setStatusCode(Integer.valueof(statusCodes[0]));
            return response;
        }else{
            return null;
        }
    }
}