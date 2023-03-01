/************************************************************************************************************************************
    Author      : Dipak Pawar
    Description : This class will contain the business logic of UserTrigger.
    Issue No.	: ST-542,  ST-682
    History		: --
   ----------------------------------------------------------------------------------------------------------------------------------
    VERSION					DATE					AUTHOR							DETAIL
    1					    09,Sept 2016		    Dipak Pawar	                    Initial Developement
    2						26,Sept 2016			Dipak Pawar						--
    3.                      8,March 2020            Oleksandr Vashchenko            Joined two frameworks to single
 **************************************************************************************************************************************/
//TODO: split class accrording to layering strategy
public without sharing class UserTriggerHandler extends SObjectTriggerHandler{
    private List<User> newRecords;
    private Map<Id, User> oldRecordsMap;

    public UserTriggerHandler() {
        this((List<User>) Trigger.new, (Map<Id, User>) Trigger.oldMap); 
    }

    @TestVisible
    private UserTriggerHandler(List<User> newRecords, Map<Id, User> oldRecordsMap) {
        this.newRecords = newRecords; 
        this.oldRecordsMap = oldRecordsMap;
    }

    public override void beforeInsert() {
        this.populateUserFederationId();
    }

    public override void beforeUpdate() {
        this.populateUserFederationId();
    }

    public override void afterUpdate(){
        Set<User> deactivatedUsers = filterDeactivatedUsers(); 
        if (deactivatedUsers.isEmpty()) {
            return;
        }
        this.sendObjectSummary(deactivatedUsers);
        setEndDateOnUserDeactivation(pluckIds(deactivatedUsers));
    }

    @future
    public static void setEndDateOnUserDeactivation(Set<Id> deactivatedUserIds) {
        List<User_Attribute__c> toDeactivate = new List<User_Attribute__c>();
        SObjectTriggerHandler.bypass('UserAttributeUpdateGapField');
        SObjectTriggerHandler.bypass('UserAttributeUpdateOpportunities');
        SObjectTriggerHandler.bypass('UserAttributeUpdateUsers');
        SObjectTriggerHandler.bypass('UserAttributeUpdateOpportunitiesTrH');
        SObjectTriggerHandler.bypass('UserAttributeValidateAttributes');
        for(User_Attribute__c itemUA : [SELECT Id, End_Date__c, User__c, User__r.IsActive 
                                        FROM User_Attribute__c 
                                        WHERE User__c IN : deactivatedUserIds AND End_Date__c = null]) {
            itemUA.End_Date__c = System.today();
            toDeactivate.add(itemUA);
        }
        update toDeactivate;
    }

    public static String queryGenerator(String objectName,List<String> fields,String userId,Boolean isTextArea, Map<String,Schema.SObjectField> sObjectFields){
        if(isTextArea) {
            return 'SELECT Id,Name,'+String.join(fields,',')+' FROM '+objectName;
        }
        String query = 'SELECT Id,Name FROM '+objectName+' WHERE ';
        String fieldType;
        List<String> references = new List<String>();
        List<String> fieldApiNames = new List<String>(fields);
        for(String fieldName: fields) {
            fieldType = String.valueOf(sObjectFields.get(fieldName).getDescribe().getType());
            if(fieldType == 'ID' || fieldType == 'REFERENCE') {
                references.add(fieldName);
                fieldApiNames.remove(fieldApiNames.indexOf(fieldName));
            }
        }
        if(!references.isEmpty() && !fieldApiNames.isEmpty() ) {
            return query + String.join(references,' = \''+userId+'\' OR ') + 
                        ' = \''+userId+'\' OR '+ 
                        String.join(fieldApiNames, ' LIKE \'%' + userId+ '%\' OR ')+
                        ' LIKE \'%'+ userId+'%\'';
        }
        if(!fieldApiNames.isEmpty()) {
            return query + String.join(fieldApiNames, ' LIKE \'%'+ userId+'%\' OR ') + 
                    ' LIKE \'%' + 
                    userId+'%\'';
        }
        return query + String.join(references,' = \''+userId+'\' OR ')+ ' = \''+userId+'\'';  
    }
  
    public static void sendEmail(String userId,String userName,Map<String,String> mapOfCSV,String emailSubject,String emailBody,Set<String> toEmailAddress){
        List<Messaging.EmailFileAttachment> lstCSVAttachments = new  List<Messaging.EmailFileAttachment>();
        String subject;
        String label;
        String[] toAddresses = new List<String>(toEmailAddress); 
        Messaging.EmailFileAttachment csvAttachment;
        for(String objectName : mapOfCSV.keySet() ){
            csvAttachment = new Messaging.EmailFileAttachment();
            label = Schema.getGlobalDescribe().get(objectName).getDescribe().getLabel();
            csvAttachment.setFileName(label+' Summary.csv');
            csvAttachment.setBody( blob.valueOf(mapOfCSV.get(objectName)));
            lstCSVAttachments.add(csvAttachment);
        }
        subject = emailSubject;
        subject = subject.contains('&userId') ? subject.replace('&userId', userId) :subject;
        subject = subject.contains('&userName') ? subject.replace('&userName', userName) :subject;
        Messaging.SingleEmailMessage  email = new Messaging.SingleEmailMessage();
        email.setSubject(subject);
        email.setPlainTextBody(emailBody);
        email.setToAddresses(toAddresses);
        email.setFileAttachments(lstCSVAttachments);
        Messaging.sendEmail(new Messaging.SingleEmailMessage[]{email});  
    }

    private void populateUserFederationId(){
        for(User itemUser : this.newRecords){
            if(String.isBlank(itemUser.FederationIdentifier) && itemUser.Username != itemUser.FederationIdentifier){
                itemUser.FederationIdentifier = itemUser.Username.toLowerCase();              
            } 
        } 
    }

    private Set<User> filterDeactivatedUsers() {
        Set<User> result = new Set<User>();
        for(User itemUser : this.newRecords) {
            if(itemUser.IsActive == false && TriggerUtility.isFieldValueChanged(itemUser, this.oldRecordsMap.get(itemUser.Id), 'IsActive')) {
                result.add(itemUser);
            }
        }
        return result; 
    }

    private Set<Id> pluckIds(Set<User> users) {
        // was tested, faster that for loop in 20% 
        return (new Map<Id,User>(new List<User>(users))).keyset();
    }

    private void sendObjectSummary(Set<User> deactivatedUsers){
        if(deactivatedUsers.isEmpty()) {
            return; 
        }
        // TODO: Redesign with new approach
        Sales_Console_Setting__mdt sendDeactivateUserStatusSetting = Settings.get('SendDeactivateUserStatus');
        SendDeactivateUserStatus sendDeactivateUserStatusWrapper = (SendDeactivateUserStatus)JSON.deserialize(sendDeactivateUserStatusSetting.Data__c,SendDeactivateUserStatus.class);
        if(!sendDeactivateUserStatusWrapper.searchInObjects.isEmpty()) {
            for(User itemUser: deactivatedUsers) {
                // TODO: Redesign to single batch execution
                Database.executeBatch(new BatchToFindDeactivatedUserIdInObject(0,itemUser,new Map<String,String>(), sendDeactivateUserStatusWrapper));
            }
        }
    }

    public class SendDeactivateUserStatus {
        public Set<String> Emails;
        public String subject; 
        public String csvName;
        public String emailBody;
        public List<Map<String,List<String>>> searchInObjects;
    }
}