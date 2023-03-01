@isTest
public class RESTAPITest {

    public class RESTAPI_ForTest extends RESTAPI {}

    @isTest
    public static void testDoPostWithMockSuccessful() {
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        req.requestURI = '/api/2/Person';  //set existing url for existing service
        req.httpMethod = 'POST';
        req.params.put('mock', 'true');
        req.params.put('mocksuccess', 'true');
        RestContext.request = req;
        RestContext.response= res;
        Test.startTest();
        RESTAPI_ForTest.doPost();		
        Test.stopTest();
        RESTAPIResult results = (RESTAPIResult) JSON.deserialize(res.responseBody.toString(), RESTAPIResult.class);
        if(Type.forName('RESTAPIPersonV2') != null) {
            System.assertEquals(true, results.success, 'Response should be succesfull');
        }
    }

    @isTest
    public static void testDoPost() {
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        req.requestURI = '/api/2/Person';  //set existing url for existing service
        req.httpMethod = 'POST';
        req.params.put('mock', 'false');
        RestContext.request = req;
        RestContext.response= res;
        Test.startTest();
        RESTAPI_ForTest.doPost();		
        Test.stopTest();
        RESTAPIResult results = (RESTAPIResult) JSON.deserialize(res.responseBody.toString(), RESTAPIResult.class);
        if(Type.forName('RESTAPIPersonV2') != null) {
            System.assertEquals(false, results.success, 'Response should be fail as service is not yet implmented');
        }
    }


    @isTest
    public static void testDoPostWithMockFailure() {
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        req.requestURI = '/api/2/Person';  //set existing url for existing service
        req.httpMethod = 'POST';
        req.params.put('mock', 'true');
        req.params.put('mocksuccess', 'false');
        RestContext.request = req;
        RestContext.response= res;
        Test.startTest();
        RESTAPI_ForTest.doPost();		
        Test.stopTest();
        RESTAPIResult results = (RESTAPIResult) JSON.deserialize(res.responseBody.toString(), RESTAPIResult.class);
        if(Type.forName('RESTAPIPersonV2') != null) {
            System.assertEquals(false, results.success, 'Response should be succesfull');
        }
    }

    @isTest
    public static void testDoGet() {
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        req.requestURI = '/api/2/Person';  //set existing url for existing service
        req.httpMethod = 'Get';
        RestContext.request = req;
        RestContext.response= res;
        Test.startTest();
        RESTAPI_ForTest.doGet();		
        Test.stopTest();
        RESTAPIResult results = (RESTAPIResult) JSON.deserialize(res.responseBody.toString(), RESTAPIResult.class);
        if(Type.forName('RESTAPIPersonV2') != null) {
            System.assertEquals(false, results.success, 'Response should be fail as service is not yet implmented');
        }
    }

    @isTest
    public static void testRESTAPIModel() {
        RESTAPIModel api = new RESTAPIModel();
        RESTAPIResult results =  (RESTAPIResult)api.getMockModel(null);
        System.assertEquals(false, results.success, 'service is not yet implmented');
    }

    @isTest
    public static void testRESTAPIBase() {
        RESTAPIBase api = new RESTAPIBase();
        RESTAPI.PayloadDetails py = new RESTAPI.PayloadDetails();
        RESTAPIResult results =  (RESTAPIResult)api.executePost(null);
        System.assertEquals(false, results.success, 'service is not yet implmented');
        results =  (RESTAPIResult)api.executeGet(null);
        System.assertEquals(false, results.success, 'service is not yet implmented');
        api.parseInput(py);
        System.assert(py.Input == null, 'payload input is empty');
    }

    @isTest
    public static void RESTAPIResult() {
        RESTAPIResult api = new RESTAPIResult();
        api.setSuccess(null);
        System.assertEquals(true, api.success, 'success is set to true');
        api.setFailure(new DummyTestException());
        System.assertEquals(false, api.success, 'success is set to false');
        api.setSuccess('dummy msg', null);
        System.assertEquals(true, api.success, 'success is set to false');
        api.setFailure('dummy msg', null);
        System.assertEquals(false, api.success, 'success is set to false');
        api.setFailure('dummy msg');
        System.assertEquals(false, api.success, 'success is set to false');
    }

    public class DummyTestException extends Exception {}
}