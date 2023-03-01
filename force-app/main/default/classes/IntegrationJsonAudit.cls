/************************************************************************************************************************************
Author      :   Tayo Chestnut
Description :   Quick Stringify to Capture Input from Endpoint for Audit Purposes
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION      DATE         AUTHOR              DETAIL
    1            2/5/2022   Tayo Chestnut     Execute from Flow
**************************************************************************************************************************************/
public with sharing class IntegrationJsonAudit {

    @InvocableMethod (label='JSON Quick Audits' description='Original JSON for Inbound API Calls' category='Mulesoft')
    public static List<ReturnOutput> quickJsonAudit (List<Request> requests) {
        String outboundJSON;
        String outboundJSONregisteredMethods;

        List<ReturnOutput> outputJsonList = new List<ReturnOutput>();

        for(request r: requests){
            ReturnOutput ro = new ReturnOutput();
            switch on r.category {
                when 'Chargebacks'{   
                    outboundJSON = JSON.serialize(r.inboundAPItoProcess);  
                    ro.inboundAPIProcessed = outboundJSON;
                    outputJsonList.add(ro);
                }when 'Payment Methods'{
                    ro.currentPaymentMethod = JSON.serialize(r.inboundcurrentPayMethod); 
                    ro.registeredPaymentMethods = JSON.serialize(r.inboundregisteredPayMethods);
                    outputJsonList.add(ro);
                }when 'Overages'{
                    ro.overageParams = JSON.serialize(r.inboundOverageParam); 
                    ro.overageResults = JSON.serialize(r.inboundOverageCredits);
                    outputJsonList.add(ro);
                }
                when else{
                    outboundJSON = 'Invalid Category';
                    ro.inboundAPIProcessed = outboundJSON;
                    outputJsonList.add(ro);
                }
            }
        }
        return outputJsonList;
    }

    public class Request{
        @InvocableVariable
        public String category;

        @InvocableVariable
        public ChargebackWrapper inboundAPItoProcess;

        @InvocableVariable
        public PaymentMethods inboundcurrentPayMethod;

        @InvocableVariable
        public List<PaymentMethods> inboundregisteredPayMethods;

        @InvocableVariable
        public OverageParameters inboundOverageParam;

        @InvocableVariable
        public List<OverageCredits> inboundOverageCredits;
    }

    public class ReturnOutput{
        @InvocableVariable
        public String inboundAPIProcessed;

        @InvocableVariable
        public String currentPaymentMethod;

        @InvocableVariable
        public String registeredPaymentMethods;

        @InvocableVariable
        public String overageParams;

        @InvocableVariable
        public String overageResults;
    }
}