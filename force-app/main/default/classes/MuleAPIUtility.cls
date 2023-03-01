/************************************************************************************************************************************
Author      :   Salesforce
Description :   This class is responsible for containing worker methods for Mulesoft API that can be used from any apex consumer.
----------------------------------------------------------------------------------------------------------------------------------
VERSION     DATE                AUTHOR                  DETAIL
1           02/16/2022          Salesforce              Initial creation
**************************************************************************************************************************************/
public with sharing class MuleAPIUtility {
    public static String getOAuthJWTToken() {
        TokenWrapper tWrapper = new TokenWrapper();
        Http http = new Http();
        HttpRequest httpRequest = new HttpRequest();
        String accessToken = '';
        Integer expiresIn;
        String tokenType;

        httpRequest.setHeader('Content-Type', 'application/json;charset=UTF-8');
        httpRequest.setHeader('Content-Length', '0');
        httpRequest.setEndPoint('callout:Mulesofte_eAPI');
        httpRequest.setBody('{"client_id":"{!$Credential.UserName}","client_secret":"{!$Credential.Password}","audience":"wework","grant_type":"client_credentials"}');
        httpRequest.setMethod('POST');
        HttpResponse response = new HttpResponse();
        
        try{
            response = http.send(httpRequest);
            if(response.getStatusCode()==200){
                String tokenResBody = response.getBody();
                tokenResBody = tokenResBody.Replace('access_token','accessToken');
                tokenResBody = tokenResBody.Replace('expires_in','expiresIn');
                tokenResBody = tokenResBody.Replace('token_type','tokenType');                
                tWrapper = (TokenWrapper)JSON.deserialize(tokenResBody, TokenWrapper.class);
                accessToken = tWrapper.accessToken;   
            }
            else{
                RESTAPIResult result = new RESTAPIResult();            
                result.setFailure(response.getBody(), response);
                RestRequest restreq = new RestRequest();
                restreq.httpMethod = httpRequest.getMethod();
                restreq.requestURI = httpRequest.getEndpoint();
                restreq.requestBody = Blob.valueof(httpRequest.getBody());

                RESTAPI.PayloadDetails payload = RESTAPI.getPayload(restreq);
                if(Test.isRunningTest()){                    
                    payload.IsMockCall = true;
                }                

                payload.APIModelsClassName = 'MuleAPIUtility';
                payload.ClassName = 'MuleAPIUtility';

                payload.Input = JSON.deserialize(payload.Body, RESTAPI.PayloadDetails.class);
                RESTAPIBase restApiBase = new RESTAPIBase();                
                result = restApiBase.executePost(payload);                        

                ApexDebugLog.logRESTAPIResult(null, result, payload, restreq);
            }
        }
        catch(exception ex){
            ApexDebugLog.logException(ex,'result ==>'+ JSON.serialize(httpRequest),'MuleUtility','getOAuthJWTToken');
        }

        return accessToken;        
    }
    
    public class TokenWrapper{
        public String accessToken {get;set;}
        public Integer expiresIn {get;set;}
        public String tokenType {get;set;}
    }
}