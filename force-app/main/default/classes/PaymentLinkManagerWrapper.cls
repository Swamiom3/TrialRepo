/************************************************************************************************************************************
Author      :   Salesforce
Description :   Apex wrapper class for creation of serialized JSON object to IXOPayment gateway API
----------------------------------------------------------------------------------------------------------------------------------
    VERSION      DATE         AUTHOR              DETAIL
    1            02/08/2022   Salesforce          Initial creation
**************************************************************************************************************************************/
//@TestVisible
public class PaymentLinkManagerWrapper {
    @InvocableVariable
    @AuraEnabled public Payment_Link_Manager__c plm;
    
    public class PLMWrapper{
        public String merchantTransactionId {get;set;}
        public String amount {get;set;}
        public String buildingCurrency {get;set;}        
        public String transactionIndicator;        
        public List<payByLink> payByLink;

        public PLMWrapper(Payment_Link_Manager__c plm){
            this.merchantTransactionId = plm.Id;
            this.amount = String.valueOf(plm.Invoice_Due_Amount__c);            
            this.buildingCurrency = plm.Building_Currency__c;
            this.transactionIndicator = 'INITIAL';
        }
    }    

    public class Customer{
        public String uuid {get;set;}
        public String locationUUID {get;set;}

        public Customer(Payment_Link_Manager__c plm){
            this.uuid = plm.Account_UUID__c;
            this.locationUUID = plm.Location_UUID__c;
        }
    }
    
    public class PayByLink{
        public Boolean sendByEmail {get;set;}
        public Integer expirationInMinute {get;set;}

        public PayByLink(){
            this.sendByEmail = false;
            this.expirationInMinute = 43200;
        }
    }
}