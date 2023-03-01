/************************************************************************************************************************************
Author      :   Salesforce
Description :   Apex class invoked via flow for various apex actions
----------------------------------------------------------------------------------------------------------------------------------
    VERSION      DATE         AUTHOR              DETAIL
    1            04/04/2022   Salesforce          Initial creation
**************************************************************************************************************************************/
public with sharing class FlowUtilities {
    public static List<Messaging.SendEmailResult> emailResults;

    @InvocableMethod(Label='Send Email Notification')
    public static void sendEmailNotification(List<EmailInputsRequest> emailInputs) {
        List<Messaging.SingleEmailMessage> emailMessages = new List<Messaging.SingleEmailMessage>();
        
        try {                        
            for(Integer i=0; i < emailInputs[0].emailInputs.size(); i++){                
                EmailInputsWrapper emailInput = emailInputs[0].emailInputs[i];

                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                List<String> to = new List<String>();
                to.add(emailInput.toAddress);
                email.setToAddresses(to);
                email.setTemplateId(emailInput.templateId);
                email.setTargetObjectId(emailInput.targetObjectId);                
                email.setWhatId(emailInput.targetWhatId);
                email.setSaveAsActivity(false);
                emailMessages.add(email);
            }
            if (!emailMessages.isEmpty()){
                emailResults = Messaging.sendEmail(emailMessages);
                
                for (Messaging.SendEmailResult emailResult : emailResults){
                    if(!emailResult.isSuccess()){                        
                        FlowUtilitiesException customException = new FlowUtilitiesException();
                        
                        customException.errorMessage = emailResult.getErrors()[0].getMessage();
                        ApexDebugLog.logException((Exception)customException,'result ==>'+ JSON.serialize(emailMessages),'FlowUtilities','sendEmailNotification');
                    }
                }            
            }                
        } 
        catch (Exception ex) {
            ApexDebugLog.logException(ex,'result ==>'+ JSON.serialize(emailMessages),'FlowUtilities','sendEmailNotification');
        }
    }

    public class EmailInputsRequest{
        @InvocableVariable(label='Wrapper list of Email Inputs' required=true)
        public List<EmailInputsWrapper> emailInputs;
    }

    public class FlowUtilitiesException extends Exception{
        public String errorCode;
        public String errorMessage;
    }
}