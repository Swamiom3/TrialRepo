/*************************************************************************************************************************************************
Name              : BatchEmailUsersBeforeCloseOpps.cls 
Description       : send an email to the users 3 days before close opps

Revision History  :-
Created/Modified by                     Created/Modified Date       Requested by                  Technical Design Proposal
---------------------------------------------------------------------------------------------------------------------------------------------------
1. Rashad Saeed (initial implementation)     27 AUG 2019                 WeWork                              CSI-2327                      
---------------------------------------------------------------------------------------------------------------------------------------------------
**************************************************************************************************************************************************/
global class BatchEmailUsersBeforeCloseOpps implements Database.Batchable<sObject> {
    global set<Id> userIds;
    global BatchEmailUsersBeforeCloseOpps (set<Id> userIds){
        this.userIds = userIds;
    }

    global Database.QueryLocator start(Database.BatchableContext BC){
        string query = 'select id from user where id in :userIds';
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<user> scope) {
        List<Messaging.SingleEmailMessage> allmsg = new List<Messaging.SingleEmailMessage>();
        EmailTemplate EmailTemplate = [select id from EmailTemplate where DeveloperName = 'Unhandled_Opportunity_alert'];
        OrgWideEmailAddress OrgWideEmailAddress = [select id from OrgWideEmailAddress where DisplayName = 'Do Not Reply'];
        for (user user : scope){
           Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
           mail.setTemplateID(EmailTemplate.id); // Unhandled Opportunity alert email template 
           mail.setSaveAsActivity(false);
           mail.setTargetObjectId(user.Id);
           mail.setOrgWideEmailAddressId(OrgWideEmailAddress.id);// do not reply 
           allmsg.add(mail);
        }
       Messaging.sendEmail(allmsg, true);
    }

    global void finish(Database.BatchableContext BC) {
    }
}