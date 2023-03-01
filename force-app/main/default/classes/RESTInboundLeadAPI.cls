/************************************************************************************************************************************
  Author        : Pranay Jadhav.
  Description   : This class exposes the Lead via SFDC's REST API.
   
  History       :
----------------------------------------------------------------------------------------------------------------------------------
  VERSION       DATE                AUTHOR              DETAIL                  ISSUE
    1           5th June 2018       Pranay Jadhav       Initial Developement    ST-  
    2           1st March 2021      Krasko Oleg         Refactoring             ST-7767
**************************************************************************************************************************************/
@RestResource(urlMapping='/InboundLead/*')
global class RESTInboundLeadAPI {    
    @HttpPost 
    global static Response doPost(WWTypes.InboundLead body){
        Boolean isInvoker = ApexDebugLog.registerRootInvoker(ApexDebugLog.InvokerType.API, 'RESTInboundLeadAPI' + '.doPost()', ApexDebugLog.InvokerType.API);
        RESTInboundLeadAPI.Response response = new RESTInboundLeadAPI.Response();
        Id leadId = new RESTInboundLeadAPIController(body).handlePostRequest(response);
        if (leadId != null) {
            response.setSuccess(leadId);
        }
        return response;
    }
    
    global class Response {
        public Boolean success;
        public String message;
        public String lead_sfid;
        public String contact_sfid;
        public void setSuccess(Id leadId){
            this.success = true;
            this.lead_sfid = leadId;
            this.message = 'Lead processed!'; 
        }
        public void setFailure(Exception pMessage) {
            this.success = false;
            this.message = pMessage.getMessage();
        }
    }
}