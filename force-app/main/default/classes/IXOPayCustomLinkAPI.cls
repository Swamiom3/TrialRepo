/************************************************************************************************************************************
Author      :   Salesforce
Description :   Apex class purposed for invocation of IXOPaymentAPI gateway, to given Mulesoft endpoint, to retrieve issued unique Payment link
----------------------------------------------------------------------------------------------------------------------------------
    VERSION      DATE         AUTHOR              DETAIL
    1            02/08/2022   Salesforce          Initial creation
**************************************************************************************************************************************/
// suppress using named credentials rule, as per design
@SuppressWarnings('PMD.ApexSuggestUsingNamedCred')
public with sharing class IXOPayCustomLinkAPI {
    public HttpResponse response;

    public void doIXOPaymentAPICallout(Map<Id,Map<String,String>> inputValues, String accessToken){        
            String locationUuid = '';
            List<Payment_Link_Manager__c> paymentlinkUpdates = new List<Payment_Link_Manager__c>();
            List<Integration_Audits__c> integrationAudits = new List<Integration_Audits__c>();
                                     
            for(Id paylinkkey:inputValues.keySet()){
                Map<String,String> uuidjsonMap = inputValues.get(paylinkkey);
                for (String jsonbody : uuidjsonMap.values()){
                    Set<String> jsonkeys = uuidjsonMap.keySet();
                    jsonbody = jsonbody.replaceAll('buildingCurrency', 'currency');
                    jsonbody = jsonbody.replace('[', '').replace(']', '');
                    locationUuid = new List<String>(jsonkeys).get(0);
                try{                                        
                    HttpCallout calloutObj = new HttpCallout();
                    calloutObj.apitoken = 'Bearer ' + accessToken;
                    calloutObj.body = jsonbody;
                    calloutObj.method = 'POST';
                    calloutObj.timeout = 120000;
                    calloutObj.contenttype = 'application/json;charset=UTF-8';
                    calloutObj.locationUuid = locationUuid;
                    HttpRequest httpRequest = setupHttpRequest(calloutObj);                    
                    response = new Http().send(httpRequest);            

                    RestRequest restreq = new RestRequest();
                    restreq.httpMethod = httpRequest.getMethod();
                    restreq.requestURI = httpRequest.getEndpoint();
                    restreq.requestBody = Blob.valueof(httpRequest.getBody());                        

                    if(response.getStatusCode() == 200){   
                        IXOPayResponse payResponse = (IXOPayResponse)JSON.deserialize(response.getBody(), IXOPayResponse.class);
                        
                        if(payResponse.success==true && payResponse.returnType=='REDIRECT'){         
                            Payment_Link_Manager__c plmupdate = new Payment_Link_Manager__c(Id = paylinkkey);                                                                       
                            
                            plmupdate.IXO_Purchase_Id__c = payResponse.purchaseId;
                            plmupdate.One_Time_Link__c = payResponse.redirectUrl;                            
                            plmupdate.IXO_Response_Message__c = response.getBody();
                            plmupdate.Status__c = 'Pending';
                            paymentlinkUpdates.add(plmupdate);
                        }
                        else if(payResponse.success==false && payResponse.returnType=='ERROR'){
                            Payment_Link_Manager__c plmupdate = new Payment_Link_Manager__c(Id = paylinkkey);
                            plmupdate.IXO_Error_Code__c = payResponse.Errors[0].errorCode;
                            plmupdate.IXO_Response_Message__c = response.getBody();
                            plmupdate.Status__c = 'Error';
                            paymentlinkUpdates.add(plmupdate);
                        }                        
                    }

                    ApexDebugLog.logRESTAPIResult(null,restreq,response);
                    integrationAudits.add(createIntegationAudit(paylinkkey,jsonbody));         
                }
                catch(exception ex){
                    ApexDebugLog.logException(ex,'result ==>'+ JSON.serialize(inputValues),'IXOPayCustomLinkAPI','doIXOPaymentAPICallout');
                    integrationAudits.add(createIntegationAudit(paylinkkey,jsonbody));
                }
            }                                
        }

        doPaymentLinkUpdates(paymentlinkUpdates, inputValues);
        doIntegrationAuditInsert(integrationAudits, inputValues);
    }

    private static HttpRequest setupHttpRequest(HttpCallout httpcallout) {
        HttpRequest req = new HttpRequest();
        Integration_Data__mdt idmdt;

        if (!Schema.sObjectType.Integration_Data__mdt.fields.EndPoint__c.isAccessible() || !Schema.sObjectType.Integration_Data__mdt.fields.Headers__c.isAccessible()){
            return null;
        }
        else{
            idmdt = [SELECT EndPoint__c, Headers__c ,Method__c, Is_Active__c, Retrial_Limit__c FROM Integration_Data__mdt 
                        WHERE DeveloperName = 'MulesoftIXOPay' AND Is_Active__c = true WITH SECURITY_ENFORCED LIMIT 1];
        }

        //req.setEndpoint('callout:Mulesoft_IXOPay');
        req.setEndpoint(idmdt.EndPoint__c + '?locationUuid=' + httpcallout.locationUuid);
        req.setHeader('Authorization', httpcallout.apitoken);
        req.setHeader('Content-Type', httpcallout.contenttype);
        if(idmdt.Headers__c != null){
            Map<String, Object> mapheaders = (Map<String, Object>)JSON.deserializeUntyped(idmdt.Headers__c);
            for (String key :mapheaders.keySet()){
                req.setHeader(key,(String)mapheaders.get(key));
            }                
        }
        req.setMethod(httpcallout.method);
        req.setTimeout(httpcallout.timeout);
        req.setBody(httpcallout.body);

        return req;
    }    

    private static void doPaymentLinkUpdates(List<Payment_Link_Manager__c> paymentlinkUpdates, Map<Id,Map<String,String>> inputValues){
        if(paymentlinkUpdates.isEmpty() || !Schema.sObjectType.Payment_Link_Manager__c.isUpdateable()){
            IXOPayCustomLinkAPIException customexception = new IXOPayCustomLinkAPIException();
            customexception.setMessage('List empty or lack of access for Payment Link Manager DML update on IXOPayCustomLinkAPI.doIXOPaymentAPICallout');
            ApexDebugLog.logException(customexception,'result ==>'+ JSON.serialize(inputValues),'IXOPayCustomLinkAPI','doIXOPaymentAPICallout');            
        }
        else{           
            update paymentlinkUpdates;
        }
    }

    private static void doIntegrationAuditInsert(List<Integration_Audits__c> integrationAudits, Map<Id,Map<String,String>> inputValues){
        if(integrationAudits.isEmpty()){
            IXOPayCustomLinkAPIException customexception = new IXOPayCustomLinkAPIException();
            customexception.setMessage('List empty for Integration Audit DML insert on IXOPayCustomLinkAPI.doIXOPaymentAPICallout');
            ApexDebugLog.logException(customexception,'result ==>'+ JSON.serialize(inputValues),'IXOPayCustomLinkAPI','doIXOPaymentAPICallout');            
        }
        else{
            insert integrationAudits;
        }
    }

    private static Integration_Audits__c createIntegationAudit(Id sourceId, String payload){
        try{
            Integration_Audits__c intgaudit =  new Integration_Audits__c();
            intgaudit.Date_Time_Identifier__c = String.valueOf(system.now());
            intgaudit.Payload__c = payload;
            intgaudit.Record_Id__c = sourceId;
            intgaudit.Status__c = 'Pending';
            intgaudit.Triggering_Flow__c = 'IXOPayCustomLinkAPI';

            return intgaudit;
        }
        catch(exception ex){
            ApexDebugLog.logException(ex,'result ==>'+ JSON.serialize(payload),'IXOPayCustomLinkAPI','createIntegationAudit');
            return null;
        }        
    }

    public class HttpCallout{
        public String apitoken { get; set; }
        public String body { get; set; }
        public String endpoint { get; set; }
        public String method { get; set; }
        public Integer timeout { get; set; }
        public String contenttype { get; set; }
        public String locationUuid { get; set; }
    }

    public class IXOPayCustomLinkAPIException extends Exception {}
}