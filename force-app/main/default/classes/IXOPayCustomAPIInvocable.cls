/************************************************************************************************************************************
Author      :   Salesforce
Description :   Apex class invoked via flow for calling and retrieving payment link, via IXOPayment gateway
----------------------------------------------------------------------------------------------------------------------------------
    VERSION      DATE         AUTHOR              DETAIL
    1            02/08/2022   Salesforce          Initial creation
**************************************************************************************************************************************/
public class IXOPayCustomAPIInvocable {    

    @InvocableMethod(label='Get Payment Link from IXOPay for given set of Payment Link Manager records' description='Returns Payment Link from IXOPayment gateway to be stored on Payment Link Manager record' category='Invoice')
    public static void issuePaymentLinkMultiple(List<PLMRequest> plmRequests) {                                       
        Map<Id, Map<String, String>> paylinkrecMap = new Map<Id, Map<String, String>>();
        String paylinkJson = '';
        
        String accessToken = MuleAPIUtility.getOAuthJWTToken();
        if(String.isBlank(accessToken)){
            IXOPayCustomLinkAPI.IXOPayCustomLinkAPIException customexception = new IXOPayCustomLinkAPI.IXOPayCustomLinkAPIException();
            customexception.setMessage('Empty JWT return from Mule callout');
            ApexDebugLog.logException(customexception,'result ==>'+ JSON.serialize(plmRequests),'IXOPayCustomAPIInvocable','getPaymentLinkMultiple');
            return;
        }

        for(Integer i=0; i<plmRequests[0].plms.size(); i++){
            Payment_Link_Manager__c plm = plmRequests[0].plms[i].plm;
            PaymentLinkManagerWrapper.PLMWrapper plmwrapper =  new PaymentLinkManagerWrapper.PLMWrapper(plm);                                    
            PaymentLinkManagerWrapper.payByLink payByLink =  new PaymentLinkManagerWrapper.payByLink();                        
            List<PaymentLinkManagerWrapper.payByLink> payByLinks = new List<PaymentLinkManagerWrapper.payByLink>();
                
            payByLinks.add(payByLink);
            plmwrapper.payByLink = payByLinks;

            paylinkJson = JSON.serialize(plmwrapper);                
            
            Map<String,String> uuidjsonMap = new Map<String,String>{plm.Location_UUID__c => paylinkJson};
            paylinkrecMap.put(plm.Id, uuidjsonMap);
        }                
    
        try{        
            IXOPayCustomLinkAPI ixopayapi = new IXOPayCustomLinkAPI();
            ixopayapi.doIXOPaymentAPICallout(paylinkrecMap,accessToken);
        }
        catch(exception ex){
            ApexDebugLog.logException(ex,'result ==>'+ JSON.serialize(plmRequests),'IXOPayCustomAPIInvocable','getPaymentLinkMultiple');
        }                    
    }
    
    public class PLMRequest{
        @InvocableVariable(label='Wrapper list of Payment Link Managers' required=true)
        public List<PaymentLinkManagerWrapper> plms;
    }
}