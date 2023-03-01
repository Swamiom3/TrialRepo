/**
* Class to send email notification.
* @author Shubham Jain, Traction on Demand
* @date 10/23/2019
*/

global with sharing class trac_EmailNotificationSender {
    @InvocableMethod(Label='Send Email Notification')
    public static void sendEmailNotification(List<Inputs> inputs) {
        try {
            List<Messaging.SingleEmailMessage> messages = new List<Messaging.SingleEmailMessage>();
            List<Case> updateCases = new List<Case>();
            for (Inputs inp : inputs) {
                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                List<String> to = new List<String>();
                to.add(inp.toAddress);
                email.setToAddresses(to);
                email.setTemplateId(inp.templateId);
                email.setWhatId(inp.supportRequestId);
                email.setTargetObjectId(inp.targetObjectId);
                email.setOrgWideEmailAddressId(inp.fromAddress);
                email.setSaveAsActivity(false);
                messages.add(email);
                if (inp.fieldToUpdate != null) {
                    Case cs1 = new Case(Id = inp.supportRequestId);
                    if (inp.fieldToUpdate.equals('Is_24_Hours_After_Email_Sent__c')) {
                        cs1.Is_24_Hours_After_Email_Sent__c = true;
                    } else if (inp.fieldToUpdate.equals('Is_4_Days_After_Email_Sent__c')) {
                        cs1.Is_4_Days_After_Email_Sent__c = true;
                    } else if (inp.fieldToUpdate.equals('Is_7_Days_After_Email_Sent__c') && inp.isStatusUpdateReq == true) {
                        cs1.Is_7_Days_After_Email_Sent__c = true;
                        cs1.Root_Cause__c = 'Not Applicable';
                        cs1.Status = 'Solved';
                    }
                    updateCases.add(cs1);
                }

            }
            if (messages.size() > 0)
                Messaging.sendEmail(messages);
            if (updateCases.size() > 0)
                update updateCases;
        } catch (Exception ex) {
            system.debug('Something went wrong: ' + ex.getMessage());
        }
    }
    global class Inputs {
        @InvocableVariable(Label='Support Request Id' Required=true)
        global String supportRequestId;

        @InvocableVariable(Label='Email Template Id' Required=true)
        global String templateId;

        @InvocableVariable(Label='To Address' Required=true)
        global String toAddress;

        @InvocableVariable(Label='From Address' Required=true)
        global String fromAddress;

        @InvocableVariable(Label='Target Object Id' Required=true)
        global String targetObjectId;

        @InvocableVariable(Label='Is Updated' Required=false)
        global Boolean isStatusUpdateReq;

        @InvocableVariable(Label='Field To Update' Required=false)
        global String fieldToUpdate;
    }

}