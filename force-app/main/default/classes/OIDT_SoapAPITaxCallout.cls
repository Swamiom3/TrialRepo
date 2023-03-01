public without sharing class OIDT_SoapAPITaxCallout {
    
    public static String usTaxCallout(String inputStr, Id recordId, Boolean async){  
        //Callout for Tax Calculation
        System.debug('inputStr '+inputStr);
        if(String.isBlank(inputStr)){
            return null;
        }
        String xmlResp=makeTaxCallout(inputStr);
        saveAttachment(inputStr,xmlResp,recordId);
        return xmlResp;
    }

    @future(callout=true)
    public static void usAsyncTaxCallout(String inputStr, Id recordId, Boolean async){  
        if(String.isBlank(inputStr)){
            return;
        }
        Map<String,String> quoteMapresponse =  new Map<String,String>() ;
        String xmlResp=makeTaxCallout(inputStr);
        quoteMapresponse = OIDT_XMLGenerateCtrl.taxCalcRes(xmlResp);
        OIDT_GenerateTax.updateQuote(quoteMapresponse,recordid);
        saveAttachment(inputStr,xmlResp,recordId);     
    }

    public static void saveAttachment(String requestBody,String responseBody,String recId){
        Id recordId = (Id)recId;
        String objectname=recordId.getSObjectType().getDescribe().getName();
        List<Attachment> attachmentToInsert=new List<Attachment>();        

        List<Attachment> attmtList = [SELECT Id,ParentId FROM Attachment WHERE ParentId =: recordId];
        if(!attmtList.isEmpty()){
            delete attmtList;     
        }        
        String docNumber  ;
        if(objectname == 'SBQQ__Quote__c'){
            docNumber = [SELECT name FROM SBQQ__Quote__c WHERE id =:recordId LIMIT 1].name;    
        }else if(objectname == 'Order'){
            docNumber = [SELECT OrderNumber FROM Order WHERE id =:recordId LIMIT 1].OrderNumber;    
        }else if(objectname == 'blng__Invoice__c'){
            docNumber = [SELECT name FROM blng__Invoice__c WHERE id =:recordId LIMIT 1].name;    
        }else if(objectname == 'blng__CreditNote__c'){
            docNumber = [SELECT name FROM blng__CreditNote__c WHERE id =:recordId LIMIT 1].name;    
        }
        String filename;
        if(!String.isBlank(requestBody)){
            filename=docNumber+'__'+'request';
            Attachment reqAttachment = new Attachment();
            reqAttachment.Body = Blob.valueOf(requestBody);
            reqAttachment.Name = String.valueOf(filename+'.xml');
            reqAttachment.ParentId = recordId;  
            attachmentToInsert.add(reqAttachment);          
        }
        if(!String.isBlank(responseBody)){
            filename=docNumber+'__'+'response';
            Attachment respAttachment = new Attachment();
            respAttachment.Body = Blob.valueOf(responseBody);
            respAttachment.Name = String.valueOf(filename+'.xml');
            respAttachment.ParentId = recordId; 
            attachmentToInsert.add(respAttachment);         
        }

        if(!attachmentToInsert.isEmpty()){
            INSERT attachmentToInsert;
        }
    }

    public static String makeTaxCallout(String inputBody){  
        String xmlResp;
        if(String.isNotEmpty(inputBody)){
            String endpoint = App_Configuration__mdt.getInstance('WeWork_Credentials').Endpoint__c;
            Http http = new Http();
            HttpRequest req = new HttpRequest();
            req.setEndpoint(endpoint);
            req.setMethod('POST');
            req.setbody(inputBody);
            req.setTimeout(120000);
            req.setHeader('Content-Type', 'text/xml');
            HttpResponse res= new HttpResponse();
            res = http.send(req); 
            xmlResp = res.getBody();
        } 
        return xmlResp;
    }
    
}