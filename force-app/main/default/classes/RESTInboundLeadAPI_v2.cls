/************************************************************************************************************************************
  Author         : Pranay Jadhav.
  Description    : This class exposes the Lead via SFDC's REST API.
   
  History        : 
----------------------------------------------------------------------------------------------------------------------------------
  VERSION          DATE                AUTHOR              DETAIL
    1            5th June 2018         Pranay Jadhav       Initial Developement
    2            15th May 2019         Nicholas Zozaya     v2 implementation
**************************************************************************************************************************************/
@RestResource(urlMapping='/InboundLeadv2')
global class RESTInboundLeadAPI_v2 {
    global static Savepoint sp {get;set;}
    global static Map<Id, Id> leadIdToReferralId;
    
    @HttpPost 
    global static Response doPost(WWTypes.InboundLead body){
        ApexDebugLog.registerRootInvoker(ApexDebugLog.InvokerType.API, 'RESTInboundLeadAPI_v2' + '.doPost()', ApexDebugLog.InvokerType.API);
        RESTInboundLeadAPI_v2.Response response = new RESTInboundLeadAPI_v2.Response();
        try{
            RESTInboundLeadAPIController_v2 controller = new RESTInboundLeadAPIController_v2(body);
            leadIdToReferralId = controller.handlePostRequest();
            response.setSuccess(leadIdToReferralId);
        }catch(Exception pEx){
            response.setFailure(pEx);
            if(ApexDebugLog.isRootInvoker(ApexDebugLog.InvokerType.API)){
                ApexDebugLog.logException(pEx,JSON.serialize(body),'RESTInboundLeadAPI_v2','doPost');
            }
        }
        return response;
    }
    
    global class Response {
        public Boolean success;
        public String message;
        public String referral_sfid;
        public String lead_sfid;
        
        global void setSuccess(Map<Id, Id> leadIdToReferralId){
            this.success = true;
            if(leadIdToReferralId.isEmpty()){
                return;
            }
            this.referral_sfid = leadIdToReferralId.values()[0];
            this.lead_sfid = new List<Id>(leadIdToReferralId.keyset())[0];
            this.message = 'Referral processed!';
        }
        
        global void setFailure(Exception pMessage) {
            this.success = false;
            this.message = pMessage.getMessage();
        }
    }
}