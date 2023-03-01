/************************************************************************************************************************************
    Author      :   Pragalbha Mahajan	
    Description :   This class sends an email to current and previous owners of account when account owner will be changed.
    				Note: This class will be covered by "AccountBypassChildUpdateTrHTest" test class.
    Issue No    : 	-
    History		:	
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION		DATE				AUTHOR				ISSUE NO		DETAIL
    1           30 Aug 2018      	Pragalbha Mahajan   ST-2696         Initial Developement 
    2			-					Chandra Teja 		ST-3686			-
    3			06 Oct 2020			Krishana Tupe		ST-3174			Code Optimization and Consolidated with new trigger structure
**************************************************************************************************************************************/
public inherited sharing class AccountSendEmailToAccountOwnersTrH extends SObjectTriggerHandler { 
    private static final String API_USER_CONTACT_INFO_SETTING = 'APIUserContactInfo';
    private static final String BASE_URL = System.URL.getSalesforceBaseUrl().toExternalForm();
    private static final  MetadataSetting__mdt BYPASSED_PROFILE_FOR_EMAIL_SEND_METADATA = Settings.getMetadataSettingByDevName('ProfilesNotValidToSendOwnerChangeEmails');
    private static final Set<Id> BYPASSED_ADMIN_PROFILES = (BYPASSED_PROFILE_FOR_EMAIL_SEND_METADATA == null) ? new Set<Id>() : (Set<Id>)JSON.deserialize(BYPASSED_PROFILE_FOR_EMAIL_SEND_METADATA.Data__c, Set<Id>.class);
    private static final String API_USER_EMAIL = getAPIUserEmail();
    @TestVisible
    private static Integer emailSentCount = 0;
    @TestVisible
    private List<Account> newAccounts;
    @TestVisible
    private Map<Id, Account> newAccountsMap;
    @TestVisible
    private Map<Id, Account> oldAccountsMap;
    @TestVisible
    Id billingAccountRecordType;
    
    @TestVisible 
    public AccountSendEmailToAccountOwnersTrH(){
        this((List<Account>) Trigger.new, (Map<Id, Account>) Trigger.newMap, (Map<Id, Account>) Trigger.oldMap);
    }
    
    @TestVisible
    private AccountSendEmailToAccountOwnersTrH(List<Account> newAccounts,  Map<Id, Account> newAccountsMap, Map<Id, Account> oldAccountsMap){
        this.newAccounts = newAccounts;
        this.newAccountsMap = newAccountsMap;
        this.oldAccountsMap = oldAccountsMap;
        

    }
    
    public override void afterUpdate(){  
        billingAccountRecordType = Schema.SObjectType.Account.getRecordTypeInfosByName()
                                                                .get('Billing Account').getRecordTypeId();   
        sendEmailToCurrentAndPreviousOwner();
    }
    
    private void sendEmailToCurrentAndPreviousOwner(){
        Set<Id> validAccountIds = new Set<Id>();
        for(Account newAccountRec : newAccounts){
            Account oldAccount = oldAccountsMap.get(newAccountRec.Id);
            if(newAccountRec.OwnerId == oldAccount.OwnerId || newAccountRec.RecordTypeId == billingAccountRecordType){
                continue;
            }
            validAccountIds.add(newAccountRec.Id); 
        }
        if(validAccountIds.isEmpty()){
            return;  
        }        
        sendEmailOnOwnershipChangeForAccounts(validAccountIds, 'Email_on_Account_Owner_Change', new Map<Id, Account>(newAccounts), oldAccountsMap);
    }
    
    private static String getAPIUserEmail(){
        Sales_Console_Setting__mdt apiUserSetting = Settings.get(API_USER_CONTACT_INFO_SETTING);       
        Map<String, Object> apiUserData = (Map<String, Object>)JSON.deserializeUntyped(apiUserSetting.Data__c);        
        return String.valueOf(apiUserData.get('Email'));
    }
    @testVisible
    private void sendEmailOnOwnershipChangeForAccounts(Set<Id> accountIdsToSendEmailNotification, String emailTemplateName, Map<Id, Account> newAccountRecordsMap, Map<Id, Account> oldAccountRecordsMap){
        sendEmailAlertsOnOwnershipChange(accountIdsToSendEmailNotification, emailTemplateName, newAccountRecordsMap, oldAccountRecordsMap);  
    }
    
    public static void sendEmailOnOwnershipChangeForOpportunities(Set<Id> oppIdsToSendEmailNotification, String emailTemplateName, Map<Id, Opportunity> newOpportunityRecordsMap, Map<Id, Opportunity> oldOpportunityRecordsMap){
        sendEmailAlertsOnOwnershipChange(oppIdsToSendEmailNotification, emailTemplateName, newOpportunityRecordsMap, oldOpportunityRecordsMap);    
    }
    
    //TODO: need to refactor this logic
    @TestVisible
    private static void sendEmailAlertsOnOwnershipChange(Set<Id> recordIdsToSendEmailNotification, String emailTemplateName, Map<Id, SObject> newSobjecRecordsMap, Map<Id, SObject> oldSobjecRecordsMap){
        UserUtility.fetchAllUsers();
        Map<Id,User> mapUserById =  UserUtility.idToUser; 
        EmailTemplate emailTemplateOnOwnerChange = Settings.getEmailTemplateByDeveloperName(emailTemplateName);
        List<Messaging.SingleEmailMessage> emailsToBeSent = new List<Messaging.SingleEmailMessage>();
        Messaging.SingleEmailMessage singleMailMsg;       
        List<Id> recordIdsToSendEmails = new List<Id>(recordIdsToSendEmailNotification);
        String SObjectType = String.valueOf(recordIdsToSendEmails[0].getSobjectType());        
        Map<Id, Opportunity> oppIdToAccOwnerChangeOpportunity = new Map<Id, Opportunity>();
        if(SObjectType == 'Opportunity'){
            oppIdToAccOwnerChangeOpportunity = AccountStoreRelOppForEmailAlertTrH.accRelatedOpportunityOnAccOwnerChange;
        }        
        Account newAccount;
        Account oldAccount;
        Opportunity newOpportunity;
        Opportunity oldOpportunity;
        User oldRecOwner;
        User newRecOwner;
        for(Id recId : recordIdsToSendEmails){
            if(SObjectType == 'Account'){
                newAccount = (Account)newSobjecRecordsMap.get(recId);
                oldAccount = (Account)oldSobjecRecordsMap.get(recId); 
                if(newAccount == null || newAccount.Id == null){
                    continue;
                }
                oldRecOwner = mapUserById.get(oldAccount.OwnerId);
                newRecOwner = mapUserById.get(newAccount.OwnerId);
            }else if(SObjectType == 'Opportunity'){
                newOpportunity = (Opportunity)newSobjecRecordsMap.get(recId);
                oldOpportunity = (Opportunity)oldSobjecRecordsMap.get(recId);
                if(newOpportunity == null || newOpportunity.Id == null){
                    continue;
                }
                Opportunity tempOppRec = oppIdToAccOwnerChangeOpportunity.get(recId); 
                if(tempOppRec != null && tempOppRec.OwnerId != null){
                    oldRecOwner = mapUserById.get(tempOppRec.OwnerId);
                    AccountStoreRelOppForEmailAlertTrH.accRelatedOpportunityOnAccOwnerChange.remove(recId);
                }else{
                    oldRecOwner = mapUserById.get(oldOpportunity.OwnerId);
                }
                newRecOwner = mapUserById.get(newOpportunity.OwnerId); 
            }          
            if(oldRecOwner == null || newRecOwner == null){
                continue;
            }  
            Set<String> toEmailAddresses = getValidToEmailAddresses(newRecOwner, oldRecOwner); 
            if(toEmailAddresses.isEmpty()){
                continue;
            }
            singleMailMsg = new Messaging.SingleEmailMessage();            
            singleMailMsg.toAddresses = new List<String>(toEmailAddresses);
            singleMailMsg.setSubject(SObjectType +' Owner has been Changed');
            String htmlBody = emailTemplateOnOwnerChange.Markup;
            htmlBody = htmlBody.replace('{loggedUser}', mapUserById.get(UserInfo.getUserId()).Name);
            if(SObjectType == 'Account'){
                htmlBody = htmlBody.replace('{Account.Name}','<a href="' + BASE_URL + '/'+newAccount.Id+'">' + newAccount.Name + '</a>');
            }else if(SObjectType == 'Opportunity'){
                htmlBody = htmlBody.replace('{Opportunity.Name}','<a href="' + BASE_URL + '/'+newOpportunity.Id+'">' + newOpportunity.Name + '</a>');
            }
            htmlBody = htmlBody.replace('{old' +SObjectType+ 'Owner}', oldRecOwner.Name);
            htmlBody = htmlBody.replace('{new' +SObjectType+ 'Owner}', newRecOwner.Name);
            singleMailMsg.htmlbody = htmlBody;
            singleMailMsg.setSaveAsActivity(false);
            if(singleMailMsg.toAddresses != null){
                emailsToBeSent.add(singleMailMsg);
            }
        }
        if(!emailsToBeSent.isEmpty()){
            Messaging.sendEmail(emailsToBeSent);
            emailSentCount = Limits.getEmailInvocations();           
        }
    }
    @TestVisible
    private static Set<String> getValidToEmailAddresses(User newRecOwner, User oldRecOwner){
        Set<String> toEmailAddresses = new Set<String>();  
        if(newRecOwner.Email == API_USER_EMAIL && oldRecOwner.IsActive && isValidUserToSendEmailOnOwnerChange(oldRecOwner)){
            toEmailAddresses.add(oldRecOwner.Email);
        }else if(oldRecOwner.Email == API_USER_EMAIL && isValidUserToSendEmailOnOwnerChange(newRecOwner)){
            toEmailAddresses.add(newRecOwner.Email);
        }else if(newRecOwner.Email != API_USER_EMAIL && oldRecOwner.Email != API_USER_EMAIL){
            if(oldRecOwner.IsActive && isValidUserToSendEmailOnOwnerChange(oldRecOwner)){
                toEmailAddresses.add(oldRecOwner.Email);
            }
            if(isValidUserToSendEmailOnOwnerChange(newRecOwner)){
                toEmailAddresses.add(newRecOwner.Email);
            }
        }
        return toEmailAddresses;
    }
    
    public static Boolean isValidUserToSendEmailOnOwnerChange(User recordOwner){       
        return (!BYPASSED_ADMIN_PROFILES.contains(recordOwner.ProfileId));
    }
    
}