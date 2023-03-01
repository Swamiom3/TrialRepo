/************************************************************************************************************************************
Author      :   Vamsi
Description :   This class provides sufficient test coverage for ApexDebugLog class
----------------------------------------------------------------------------------------------------------------------------------
VERSION     DATE                AUTHOR                  DETAIL
1           20 Nov 2021         Vamsi             Initial Developement
**************************************************************************************************************************************/
@isTest
public class ApexDebugLogTest implements HttpCalloutMock{
    
    public static HttpResponse respond(HttpRequest request){
        HttpResponse response = new HttpResponse();
        response.setBody('{'+
        '"valid": true,'+
        '"number": "14158586273",'+
        '"local_format": "4158586273",'+
        '"international_format": "+14158586273",'+
        '"country_prefix": "+1",'+
        '"country_code": "US",'+
        '"country_name": "United States of America",'+
        '"location": "Novato",'+
        '"carrier": "AT&T Mobility LLC",'+
        '"line_type": "mobile"'+
        '}'
        );
        return response;
    }

    @isTest
    static void logException_Test(){
        try{
            insert new Account();
            System.assert(false);
        }
        catch(Exception ex){
            ApexDebugLog.logException(ex, 'Account Insert Failed', 'ApexDebugLogTest', 'logException_Test');
        }
        String orgName = ApexDebugLog.getSandboxName();
        ApexDebugLog.registerRootInvoker(ApexDebugLog.InvokerType.AURA, 'FollowUpController' + 'getsObjectPrefix', ApexDebugLog.InvokerType.AURA);
        ApexDebugLog.currentInvoker = null;
        ApexDebugLog.registerRootInvoker(ApexDebugLog.InvokerType.AURA, 'FollowUpController' + 'getsObjectPrefix', ApexDebugLog.InvokerType.AURA);
        ApexDebugLog.isRootInvoker(ApexDebugLog.InvokerType.AURA);
        
        String baseUrl = System.URL.getSalesforceBaseUrl().toExternalForm();               
        String expectedOrg = baseUrl.substringBetween('--','.');
        if (expectedOrg == null){
            //it's production
            expectedOrg = 'Production';
        }
        System.assertEquals(expectedOrg, orgName,'Incorrect Organization Name');
    }
    
    @isTest
    static void createLogTest(){
        ApexDebugLog.Log log = new ApexDebugLog.Log();
        log.Type = 'Error';
        log.ApexClass = 'ApexDebugLogTest';
        log.Method = 'createLogTest';
        log.Message = 'Test Log';
        log.StackTrace = 'You must populate all the fields';
        log.UserId = UserInfo.getUserId();
        log.ProfileId = UserInfo.getProfileId();
        new ApexDebugLog().createLog(log);
        new ApexDebugLog.Warning('ApexDebugLogTest','createLogTest','abc','Warning');
        try{
            insert new Account();
            System.assert(false);
        }
        catch(Exception DmlException){
            new ApexDebugLog.Error('ApexDebugLogTest','createLogTest','abc',DmlException);
            System.assertEquals('System.DmlException', DmlException.getTypeName(),'Incorrect Exception Type Name');
        }
    }
    
    @isTest
    static void TestRestCallout(){
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new ApexDebugLogTest());
        Map<String,String> body = ApexDebugLog.getAccessToken();
        
        String jsonbody = '{'+
        '"valid": true,'+
        '"number": "14158586273",'+
        '"local_format": "4158586273",'+
        '"international_format": "+14158586273",'+
        '"country_prefix": "+1",'+
        '"country_code": "US",'+
        '"country_name": "United States of America",'+
        '"location": "Novato",'+
        '"carrier": "AT&T Mobility LLC",'+
        '"line_type": "mobile"'+
        '}';
        String responseBody = ApexDebugLog.executeRest('account', jsonbody);
        
        String accessToken = '';
        Sales_Console_Setting__mdt accessTokenSetting = SalesConsoleSettings.get('AccessTokenSetting'); 
        Map<String,String> mapAccessTokenInfo;
        if(accessTokenSetting != null){
            mapAccessTokenInfo = (Map<String,String>)JSON.deserialize(accessTokenSetting.Data__c,Map<String,String>.class);   
        }
        for(String access : mapAccessTokenInfo.keyset()){
            accessToken = mapAccessTokenInfo.get(access);
        }
        ApexDebugLog.executeRest(accessToken, 'account', jsonbody);
        Test.stopTest();
        
        Map<String,String> expectedBody = (Map<String,String>)JSON.deserialize(jsonbody, Map<String,String>.class);
        
        System.assertEquals(jsonbody, responseBody,'Incorrect Json body');
        System.assertEquals(expectedBody, body,'Not a valid Response body');
    }
    
    @isTest
    static void logRESTAPIResultTest(){
        try{
            insert new Account();
            System.assert(false);
        }
        catch(Exception exLog){
            RESTAPIResult result = new RESTAPIResult();
            result.success = false;
            result.message = 'Insertion Failed';
            RESTAPI.PayloadDetails payload = new RESTAPI.PayloadDetails();
            RestRequest request = new RestRequest();
            ApexDebugLog.logRESTAPIResult(exLog, result, payload, request);
            System.assertEquals('System.DmlException', exLog.getTypeName(),'Incorrect Exception Type Name');
        }
    }
}