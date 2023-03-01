public without sharing class OIDT_OneSourceTaxGenCtrl {

   
   @AuraEnabled
    public static Map<String,String> getTaxFields(Id recordId, Boolean async){
        Map<String,String> mapResponse = new Map<String,String>();
        string obj = recordId.getSObjectType().getDescribe().getName(); 
        Schema.DescribeSObjectResult quoteSobj = SBQQ__Quote__c.sObjectType.getDescribe();
        Schema.DescribeSObjectResult orderSobject = Order.sObjectType.getDescribe();
        Schema.DescribeSObjectResult invoiceSobj = blng__Invoice__c.sObjectType.getDescribe();
        Schema.DescribeSObjectResult creditNoteSobj = blng__CreditNote__c.sObjectType.getDescribe();
        
        if(obj == quoteSobj.getName()){
            mapResponse = OIDT_GenerateTax.getQuoteTaxFields(recordId, async);
        }else if(obj == orderSobject.getName()){
            mapResponse = OIDT_GenerateTax.OrderTaxFields(recordId, async);
        }else if(obj == invoiceSobj.getName()){
            mapResponse = OIDT_GenerateTax.invoiceTaxFields(recordId, async);
        }else if( obj == creditNoteSobj.getName()){
           mapResponse = OIDT_GenerateTax.cnTaxFields(recordId, async);
        }
        return mapResponse;
    }
    
   @InvocableMethod
   public static void calculateTax(List<String> recordIds) {
       if(recordIds != null && recordIds.size() > 0) {
           OIDT_TaxAsynCall asyncCall = new OIDT_TaxAsynCall();
           asyncCall.recordId = recordIds[0];
           System.enqueueJob(asyncCall);
       }
   }  
   
}