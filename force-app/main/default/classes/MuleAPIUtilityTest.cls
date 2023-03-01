/************************************************************************************************************************************
Author      :   Salesforce
Description :   This class have testmethods to cover MuleAPIUtility class
----------------------------------------------------------------------------------------------------------------------------------
VERSION     DATE                AUTHOR                  DETAIL
1           02/16/2022          Salesforce              Initial creation
**************************************************************************************************************************************/
@isTest
public class MuleAPIUtilityTest {
    static String endPoint = 'http://example-api.com';

    @isTest
    static void getOAuthJWTTokenPositive(){                
        String responseBody = '{"access_token": "Token","expires_in": 86400,"token_type": "Bearer"}';
        MockHttpResponseHandler mockResponseHandler = new MockHttpResponseHandler();
        MockResponse mockResponse = new MockResponse('POST', responseBody, 200,'application/json');
        mockResponseHandler.addResponse(endPoint, mockResponse);
                
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, mockResponseHandler);
        MuleAPIUtility.getOAuthJWTToken();

        Test.stopTest();
        System.assertEquals('200', String.valueOf(mockResponse.response.getStatusCode()),'200 expected, received invalid response code');        
        System.assertEquals(responseBody, mockResponse.response.getBody(),'Invalid response body, expected: {"access_token": "Token","expires_in": 86400,"token_type": "Bearer"}');
    }
    @isTest
    static void getOAuthJWTTokenNegative(){                
        String responseBody = '{"error": "access_denied","error_description": "Unauthorized"}';
        MockHttpResponseHandler mockResponseHandler = new MockHttpResponseHandler();
        MockResponse mockResponse = new MockResponse('POST', responseBody, 401,'application/json');
        mockResponseHandler.addResponse(endPoint, mockResponse);

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, mockResponseHandler);
        MuleAPIUtility.getOAuthJWTToken();

        Test.stopTest();
        System.assertEquals('401', String.valueOf(mockResponse.response.getStatusCode()),'401 expected, received invalid response code');
        System.assertEquals(responseBody, mockResponse.response.getBody(),'Invalid response body, expected: {"error": "access_denied","error_description": "Unauthorized"}');
    }

    public class MockHttpResponseHandler implements HttpCalloutMock {
        Map<String, ResponseEndpointHolder> responseMap = new Map<String, ResponseEndpointHolder>();
    
        public void addResponse(String endpoint, MockResponse response){
            ResponseEndpointHolder holder;
            if(responseMap.containsKey(endpoint)){
                holder = responseMap.get(endpoint);
            }else{
                holder = new ResponseEndpointHolder();
                responseMap.put(endpoint, holder);
            }
            holder.addMockResponse(response);
        }

        public HTTPResponse respond(HTTPRequest req) {
            ResponseEndpointHolder responseHolder = responseMap.get(endpoint);
            return responseHolder.getMockResponse(req);
        }
    
        private String getBaseUrl(String endpoint){
            Url baseUrl = new URL(endpoint);
            return baseUrl.getHost() + baseUrl.getPath();
        }
    }    

    public class ResponseEndpointHolder{
        protected Map<String, List<MockResponse>> endpointMethodMap = new Map<String, List<MockResponse>>();

        public HTTPResponse getMockResponse(HTTPRequest req){
            String method = req.getMethod();
            List<MockResponse> responses = endpointMethodMap.get(method);
            if(responses == null || responses.size() == 0){
                return null;
            }
            else if(responses.size() == 1){
                return responses[0].getResponse(req);
            }
            else{
                return responses.remove(0).getResponse(req);
            }            
        }

        public void addMockResponse(MockResponse response){
            String method = response.getMethod();
            if(endpointMethodMap.containsKey(method)){
                endpointMethodMap.get(method).add(response);
            }else{
                endpointMethodMap.put(method, new List<MockResponse>{ response });
            }
        }
    }    

    public class MockResponse{
        private String method;
        public String contentType { get; set;}
        public Integer statusCode {get; set;}
        public Map<String, String> headers {get; set;}
        public String body {get; set;}      
        public HttpResponse response;  

        public String getMethod(){
            return method;
        }

        public void setMethod(String value){
            this.method = value;
        }

        public MockResponse(String method, String body, Integer statuscode, String contentType){
            this.method = method;
            this.body = body;
            this.headers = new Map<String, String>();
            this.statusCode = statuscode;
            this.contentType = contentType;
        }

        public HTTPResponse getResponse(HTTPRequest req) {
            response = new HttpResponse();
            response.setHeader('Content-Type', contentType);
            if(this.body != null){
                response.setBody(body);
            }
            response.setStatusCode(statusCode);
            for(String key : headers.keySet()){
                response.setHeader(key, headers.get(key));
            }

            return response;
        }
    }
}