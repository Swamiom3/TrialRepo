/*********************************************************************************************************
	Author        :  Shobhit Gahlot
	Description   :  This class will contain buisness logic of Territory Update Name
	Issue No.     :  ST-8870
	History       :
-----------------------------------------------------------------------------------------------------------
	VERSION        DATE            AUTHOR             DETAIL
	1          24-Aug-2021      Shobhit Gahlot        Refactor
***********************************************************************************************************/
public class TerritoryUpdateNameNotificationTrH extends SObjectTriggerHandler {
    @TestVisible
    private List<Territory__c> newTerritories;
    @TestVisible
    private Map<Id, Territory__c> oldTerritoriesMap;
    public static Integer totalEmails = 0;
    public TerritoryUpdateNameNotificationTrH(){
        this((List<Territory__c>) Trigger.new, (Map<Id, Territory__c>) Trigger.oldMap);
    }
    
    @TestVisible
    private TerritoryUpdateNameNotificationTrH(List<Territory__c> newTerritories, Map<Id, Territory__c> oldTerritoriesMap){
        this.newTerritories = newTerritories;
        this.oldTerritoriesMap = oldTerritoriesMap;
    }
    
    public override void afterUpdate(){
        sendEmailOnTerritoryNameChange();
    }
    
    @TestVisible
    private void sendEmailOnTerritoryNameChange() {
        List<Territory__c> territories = getNameChangedTerritories();
        if(territories.isEmpty()){
            return;
        }
        EmailTemplate emailTemplate = Settings.getEmailTemplateByDeveloperName('Email_To_Send_When_Territory_Name_Change');
        if(emailTemplate == null){
            return;
        }
        Set<String> toAddresses = getEmails();
        if(toAddresses.isEmpty()){
            return;
        }
        String baseUrl = System.URL.getSalesforceBaseUrl().toExternalForm();
        List<Messaging.SingleEmailMessage> emailsToSend = new List<Messaging.SingleEmailMessage>();
        
        for(Territory__c territory : territories){
            Territory__c oldTerritory = oldTerritoriesMap.get(territory.Id);
            Messaging.SingleEmailMessage singleMail = new Messaging.SingleEmailMessage();
            singleMail.setSubject('Territory Name has been Changed');
            String htmlBody = emailTemplate.Markup;
            htmlBody = htmlBody.replace('{oldTerritoryName}','<a href="' + baseUrl + '/'+ oldTerritory.Id +'">' + oldTerritory.Name + '</a>');
            htmlBody = htmlBody.replace('{newTerritoryName}','<a href="' + baseUrl + '/'+ territory.Id +'">' + territory.Name + '</a>');
            singleMail.htmlbody = htmlBody;
            singleMail.setSaveAsActivity(false);
            singleMail.toAddresses = new List<String>(toAddresses);
            emailsToSend.add(singleMail);
        }
        
        if(!emailsToSend.isEmpty()){
            Messaging.sendEmail(emailsToSend);
            totalEmails = emailsToSend.size();
        }
    }
    
    private List<Territory__c> getNameChangedTerritories() {
        List<Territory__c> territories = new List<Territory__c>();
        for(Territory__c newTerritory : newTerritories) {
            if(TriggerUtility.isFieldValueChanged(newTerritory, oldTerritoriesMap.get(newTerritory.Id), 'Name')) {
                territories.add(newTerritory);
            }
        }
        return territories;
    }
    
    private Set<String> getEmails(){   
        Set<String> usersEmail = new Set<String>();   
        for(GroupMember groupMember : [SELECT (SELECT UserOrGroupId FROM GroupMembers) FROM Group WHERE Name =: Label.Queue_Name].GroupMembers){
            User user =  UserUtility.getUserById(groupMember.UserOrGroupId);
            if(user != null && EmailService.isValidUserToSendEmailOnOwnerChange(user.ProfileId)){
                usersEmail.add(user.Email);
            }
        }
        return usersEmail;
    }
}