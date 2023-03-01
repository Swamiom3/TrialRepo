/******************************************************************************************************************** 
Name              : APIConnection.cls 
Description       : API Connection class .

Revision History  :-
Created/Modified by         Created/Modified Date       Requested by         Technical Design Proposal
---------------------------------------------------------------------------------------------------------------------
1. Rashad Saeed (Creator)      31 DEC 2018              WeWork                
---------------------------------------------------------------------------------------------------------------------
*********************************************************************************************************************/
public class APIConnection{
    
    private HttpRequest req;
    private Integration_Data__mdt CMT;
    private Http caller;
    public Boolean isActive = false;
    private String endPoint;
    private Integer retrialLimit;
    private final Integer INDEX = 0;
    
    public APIConnection(String project) {
        CMT = [SELECT EndPoint__c, Headers__c ,Method__c, Is_Active__c, Retrial_Limit__c 
               FROM Integration_Data__mdt 
               WHERE DeveloperName = :project 
               LIMIT 1] ; 
        
        this.endPoint = CMT.EndPoint__c;
        this.req = new HttpRequest();
        this.isActive = CMT.Is_Active__c;
        this.retrialLimit = CMT.Retrial_Limit__c != NULL ? Integer.valueOf(CMT.Retrial_Limit__c) : NULL;
        If (CMT.Headers__c <> null){
            Map<String, Object> HeadersData = (Map<String, Object>)JSON.deserializeUntyped(CMT.Headers__c);
            for (String Key :HeadersData.keySet())
                this.req.setHeader(key,(String)HeadersData.get(key));
        }
        this.caller = new Http();
    }
    
    public HttpResponse sendRequest(String messageBody) {
        req.setEndpoint(endPoint);
        req.setMethod(CMT.Method__c); 
        if(!String.isEmpty(messageBody)){
            req.setBody(messageBody);
        }
        if(this.retrialLimit != NULL && this.retrialLimit >= 1){
            return sendRequestWithRetrialLogic(); 
        }else{
            HttpResponse resp = caller.send(req);
            return resp;
        }
    }
    
    private HttpResponse sendRequestWithRetrialLogic() {
        HttpResponse resp;
        while(INDEX < this.retrialLimit){
            try{
                resp = caller.send(req);
                if(resp.getStatusCode() != 200){
                    this.retrialLimit--;
                    sendRequestWithRetrialLogic();
                }else{
                    return resp;
                }
            }catch(Exception pEx){
                this.retrialLimit--;
                if(this.retrialLimit != 0){
                    sendRequestWithRetrialLogic();
                }else{
                    ApexDebugLog.logException(pEx, 'CMT==>'+CMT, 'APIConnection', 'sendRequestWithRetrialLogic'); 
                }
            }
        }
        return resp;
    }
    
    public static string getEndPointWithEnv(string endPoint){
        string env = LightningComponentController.getEnvironmentName();
        return endPoint + '_' + env;
    }
    
    public void setEndPointParams (list <string> endPointParamsLST)
    {
        for(Integer i = 0; i < endPointParamsLST.size(); i++)
        {
            endPoint = endPoint.replace('{' + string.valueOf(i) + '}', endPointParamsLST[i]);
        }
    }
    
    public void setHeader(String headerKey, String headerValue){
        req.setHeader(headerKey, headerValue);
    }
}