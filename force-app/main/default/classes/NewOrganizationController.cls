/************************************************************************************************************************************
    Author      :  Nikhil Mehta
    Description :  This class contain all aura methods related new Account flow.

    History     :
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION     DATE                AUTHOR          DETAIL
     1          30 August 2018      Nikhil Mehta    Initial Developement
**************************************************************************************************************************************/

global without sharing class NewOrganizationController {
    public class  NewOrganizationControllerException extends Exception{}
    public static Boolean isInvoker = false;
    public static Savepoint sp {get;set;}

    static {
        isInvoker = ApexDebugLog.registerRootInvoker(ApexDebugLog.InvokerType.AURA, 'NewOrganizationController' + 'getsObjectPrefix', ApexDebugLog.InvokerType.AURA);
    }

  /****************************************************************************************************************************
        Author              : Nikhil Mehta
        Description         : This method is used to get new organtion creation permission and instructions.
        Created Date        : 03 september 2018
        Issue No			: ST-2731
        LastModified Date   : 8 March 2019
        LastModified By     : Krishana Tupe (Rollback transaction if exception occured)
  *****************************************************************************************************************************/
    @AuraEnabled
    public static DatabaseResult getNewOrganizationData(){
        try{
            sp = Database.setSavepoint();
            NewOrganizationSettingWrapper newOrgCreationSettingRec = new NewOrganizationSettingWrapper();
            if(newOrgCreationSettingRec.excludeProfiles != null && newOrgCreationSettingRec.excludeProfiles.size() > 0){
                User userRec = UserUtility.getUserById(UserInfo.getUserId());
                newOrgCreationSettingRec.excludeProfiles = string.join(newOrgCreationSettingRec.excludeProfiles,',').toLowerCase().split(',');
                if(!newOrgCreationSettingRec.excludeProfiles.contains(userRec.Profile.Name.toLowerCase())){
                    newOrgCreationSettingRec.isUserCreateOrg = true;
                }
                List<PermissionSetAssignment> lstPermissionSetAssignments = new List<PermissionSetAssignment>([SELECT Id, PermissionSetId, AssigneeId FROM PermissionSetAssignment WHERE PermissionSet.Name = 'Can_Create_Organization' AND AssigneeId =: UserInfo.getUserId()]);
                if(lstPermissionSetAssignments.size() > 0){
                    newOrgCreationSettingRec.isUserCreateOrg = true;
                    newOrgCreationSettingRec.isUserCreateEnterpriseOrg = true;
                }
                return new DatabaseResult(newOrgCreationSettingRec);
            }else if(newOrgCreationSettingRec.instructions != null && newOrgCreationSettingRec.instructions.size() > 0){
                return new DatabaseResult(newOrgCreationSettingRec);
            }else{
                throw new NewOrganizationControllerException('NewOrgCreationSetting is null');
            }
        }catch(Exception pEx) {
            LightningComponentController.rollbackTransaction(sp);
            ApexDebugLog.logException(pEx, '', 'CreateNewOrganizationController', 'getPermissionForAccountFlow');
            return (new DatabaseResult(pEx));
        }
    }

    public class NewOrganizationSettingWrapper{
        public List<string> excludeProfiles;
        @AuraEnabled
        public Map<String, List<String>> instructions;
        @AuraEnabled
        public Boolean isUserCreateOrg;
        @AuraEnabled
        public Boolean isUserCreateEnterpriseOrg;
        NewOrganizationSettingWrapper(){
            isUserCreateOrg = false;
            isUserCreateEnterpriseOrg = false;
            Sales_Console_Setting__mdt newOrgSetting = SalesConsoleSettings.get('NewOrgCreationSetting');
            if(newOrgSetting != null){
                NewOrganizationSettingWrapper newOrgCreationSettingRec = (NewOrganizationSettingWrapper)JSON.deserialize(newOrgSetting.Data__c, NewOrganizationSettingWrapper.class);
                excludeProfiles = newOrgCreationSettingRec.excludeProfiles != null && newOrgCreationSettingRec.excludeProfiles.size() > 0 ? newOrgCreationSettingRec.excludeProfiles : null;
                instructions = newOrgCreationSettingRec.instructions != null && newOrgCreationSettingRec.instructions.size() > 0 ? newOrgCreationSettingRec.instructions : null;
            }else{
                excludeProfiles = null;
                instructions = null;
            }
        }
    }

    /****************************************************************************************************************************
        Author              : Pragalbha Mahajan
        Description         : This method is used to createNewOrganization.
        Created Date        : 03 september 2018
		Issue No			: ST-2729
        LastModified Date   : 16 May 2019
        LastModified By     : Pragalbha Mahajan
   *****************************************************************************************************************************/
    public static Boolean isFromConvertBroker = FALSE;
    @AuraEnabled
    public static DatabaseResult createNewOrgAccount(List<sObject> lstRecords, Boolean isFromConvertBrokerLead){
        isFromConvertBroker =  isFromConvertBrokerLead;
        return createNewOrgAccount(lstRecords);
    }

    /****************************************************************************************************************************
        Author              : Pragalbha Mahajan
        Description         : This method is used to createNewOrganization.
        Created Date        : 03 september 2018
		Issue No			: ST-2729
        LastModified Date   : 16 May 2019
        LastModified By     : Pragalbha Mahajan
   *****************************************************************************************************************************/
    @AuraEnabled
    public static DatabaseResult createNewOrgAccount(List<sObject> lstRecords){
        Account objAccount;
        Contact objContact;
        Lead objLead;
        
        try{
            sp = Database.setSavepoint();
            for(sObject record : lstRecords){
                switch on record {
                    when Account accRec {
                        objAccount = accRec;
                    }
                    when Contact conRec {
                        objContact = conRec;
                    }
                    
                    when Lead leadRec{
                        objLead = leadRec;
                    }
                }
            }
            boolean isLeadPartnerAffiliate = ConvertBrokerLeadController.isParterAffilate(objLead);
            if(objAccount != null){
                Integer thresholdLimit = Integer.valueOf(Label.Duplicate_Account_Creation_Threshold);
                Sales_Console_Setting__mdt RestrictOpportunityCreation = SalesConsoleSettings.get('RestrictOpportunityCreation');
                Map<String,Map<String,set<String>>> mapOfCriteria  = (Map<String,Map<String,set<String>>>)JSON.deserialize(RestrictOpportunityCreation.Data__c.toLowerCase(), Map<String,Map<String,set<String>>>.class);
                Map<String,set<String>> mapOfLeadSource = mapOfCriteria.get('leadsourcecriteriaforconvertedlead');
                if(objLead!=null && String.isNotBlank(objLead.Id)){
                    Id recTypeEnterpriseId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Business Account').getRecordTypeId();
                    Map<Id, Account> mapLeadToAccount = new Map<Id,Account>();
                    mapLeadToAccount.put(objLead.Id, objAccount);
                    List<Account> lstAccount = (List<Account>)FieldmappingsHelper.getMappings(mapLeadToAccount, 'FieldMappings_LeadToAccount').values();
                    if(lstAccount.size() > 0){
                        if(String.isNotBlank(objAccount.Account_Type__c) && objAccount.Account_Type__c.equalsIgnoreCase('Sales')){
                            lstAccount[0].Account_Type__c = 'Sales';
                            lstAccount[0].ParentId = objAccount.ParentId;
                        }
                        objAccount = lstAccount[0];
                    }
                    if(isLeadPartnerAffiliate && isFromConvertBroker){
                        objAccount.Account_SubType__c = 'Partner';
                        objAccount.RecordTypeId = recTypeEnterpriseId;
                    }
                }
                if(objContact != NULL && objAccount.Number_of_Full_Time_Employees__c > thresholdLimit){
                    objAccount.Duplicate_Status__c = 'Pending';
                }else if(objContact != NULL){
                    objAccount.Duplicate_Status__c = 'Auto-Approved';
                }
                insert objAccount;
                if(objContact != null){
                    if(objContact.Id != null){
                        if(objContact.AccountId == null && objAccount.Id != null){
                            objContact.AccountId = objAccount.Id;
                            PersonEndpointHelper.updateCICompany(objContact);
                        }
                        update objContact;
                        
                    }else{
                        objContact.AccountId = objAccount.Id != null ? objAccount.Id : null ;
                        if(objLead!=null && String.isNotBlank(objLead.Id)){
                            Map<Id, Contact> mapContactsToMap = new Map<Id, Contact>();
                            mapContactsToMap.put(objLead.Id, objContact);
                            List<Contact> lstContact = (List<Contact>)FieldmappingsHelper.getMappings(mapContactsToMap, 'FieldMappings_LeadToContact').values();
                            if(lstContact.size() > 0){
                                objContact = lstContact[0];
                                objContact.Convert_Lead__c = false;
                                objContact.Contact_Lead_Status__c = 'Converted';
                                if(mapOfLeadSource.containsKey('leadsource') && String.isNotBlank(objlead.LeadSource) && (mapOfLeadSource.get('leadsource')).contains(objlead.LeadSource.toLowerCase())){
                                    objContact.Type__c = 'Broker';
                                }
                                if(isLeadPartnerAffiliate && isFromConvertBroker){
                                    objContact.Type__c = 'Partner';
                                }
                            }
                        }
                        insert objContact;
                    }
                    if(objContact.Id != null){
                        objAccount.Primary_Member__c  = objContact.Id;
                        update objAccount;
                    }
                }
                return new DatabaseResult(objAccount.Id);
            }else{
                throw new NewOrganizationControllerException('Account is null');
            }
        }catch(Exception pEx) {
            LightningComponentController.rollbackTransaction(sp);
            ApexDebugLog.logException(pEx, JSON.serialize(lstRecords), 'CreateNewOrganizationController', 'createNewOrg');
            return (new DatabaseResult(pEx));
        }
    }

    /****************************************************************************************************************************
        Author              : Nikhil Mehta
        Description         : This method is used to send mail for new orgnanization request from create new organization.
        Created Date        : 03 september 2018
		Issue No			: ST-2729
	-----------------------------------------------------------------------------------------------------------------------------
        Modified Date       : 18 September 2018
		Description         : Now this method is used to send mail for new orgnanization request using sales console setting.
		Issue No			: ST-2694
   --------------------------------------------------------------------------------------------------------------------------------
        LastModified Date   : 8 March 2019
        LastModified By     : Krishana Tupe (Rollback transaction if exception occured)
   *****************************************************************************************************************************/
    @AuraEnabled
    public static DatabaseResult sendNewOrganizationRequest(List<sObject> lstRecords){
        Account objAccount;
        Contact objContact;
        try{
            sp = Database.setSavepoint();
            for(sObject record : lstRecords){
                switch on record {
                    when Account accRec {
                        objAccount = accRec;
                    }
                    when Contact conRec {
                        objContact = conRec;
                    }
                }
            }
            if(objAccount != null && objAccount.Name != null && objAccount.Number_of_Full_Time_Employees__c != null){
                Map <String, Schema.SObjectField> fieldMap = Schema.getGlobalDescribe().get('Account').getDescribe().fields.getMap();
                List<String> accountFields = new List<String>();
                for(Schema.SObjectField field : fieldMap.values()){
                    if(String.isNotBlank(String.valueOf(objAccount.get(field.getDescribe().getname())))){
                        accountFields.add(field.getDescribe().getname());
                    }
                }
                List<String> contactFields = new List<String>();
                if(objContact != null && objContact.Email != null && objContact.FirstName != null && objContact.LastName != null){
                    fieldMap = Schema.getGlobalDescribe().get('Contact').getDescribe().fields.getMap();
                    for(Schema.SObjectField field : fieldMap.values()){
                        if(String.isNotBlank(String.valueOf(objContact.get(field.getDescribe().getname())))){
                            contactFields.add(field.getDescribe().getname());
                        }
                    }
                }
                List<String> toAddresses = new List<String>();
                Sales_Console_Setting__mdt newOrgRequestEmails=SalesConsoleSettings.get('NewOrganizationCreationRequestEmails');
                if(newOrgRequestEmails != null && newOrgRequestEmails.data__c != null){
                    List<String> lstEmails = (List<String>)JSON.deserialize(newOrgRequestEmails.data__c, List<String>.class);
                    if(lstEmails.size() > 0){
                        toAddresses.addAll(lstEmails);
                    }
                }
                if(toAddresses.size() > 0){
                    EmailTemplate emailTemplateRequestNewOrgCreation = [SELECT Id, Name, Markup FROM EmailTemplate Where DeveloperName = 'New_Org_Creation_Request_With_Contact' LIMIT 1];
                    List<Messaging.SingleEmailMessage> lstEmails = new List<Messaging.SingleEmailMessage>();
                    Messaging.SingleEmailMessage objSingleMail;
                        for(String address : toAddresses ){
                            objSingleMail = new Messaging.SingleEmailMessage();
                            objSingleMail.setSubject('New Enterprise Organization Creation Request-'+objAccount.Name);
                            String htmlBody = emailTemplateRequestNewOrgCreation.Markup;
                            htmlBody = htmlBody.replace('{{loggedUser}}', UserInfo.getFirstName()+' '+UserInfo.getLastName());
                            for(String fieldName : accountFields){
                                htmlBody = htmlBody.replace('{{Account.'+fieldName+'}}', String.isNotBlank(String.valueOf(objAccount.get(fieldName)))?String.valueOf(objAccount.get(fieldName)):'');
                            }
                            for(String fieldName : contactFields){
                                htmlBody = htmlBody.replace('{{Contact.'+fieldName+'}}', String.isNotBlank(String.valueOf(objContact.get(fieldName)))?String.valueOf(objContact.get(fieldName)):'');
                            }
                            while(htmlBody.countMatches('{{')>0 && htmlBody.countMatches('}}')>0){
                                htmlBody=htmlBody.replace(htmlBody.substring(htmlBody.indexOf('{{'),htmlBody.indexOf('}}')+2),'');
                            }
                            htmlBody = htmlBody.replace('<a href="/001/o">Click here</a>', '<a href="' + System.Label.URL + '/apex/NewOrganization">Click here</a>');
                            objSingleMail.htmlbody = htmlBody;
                            objSingleMail.setTreatTargetObjectAsRecipient(false);
                            objSingleMail.toAddresses = new List<String>{address};
                            objSingleMail.setSaveAsActivity(false);
                            lstEmails.add(objSingleMail);
                        }
                    Messaging.SendEmailResult[] emailResults =  Messaging.sendEmail(lstEmails);
                    for(Messaging.SendEmailResult emailResult :emailResults ){
                        if(emailResult.isSuccess()){
                            return new DatabaseResult(true);
                        }
                    }
                }
            }else if(objAccount == null ){
                throw new NewOrganizationControllerException('Account is null');
            }
            return new DatabaseResult(false);
        }catch(Exception pEx) {
            LightningComponentController.rollbackTransaction(sp);
            ApexDebugLog.logException(pEx, JSON.serialize(lstRecords), 'CreateNewOrganizationController', 'sendNewOrganizationRequest');
            return (new DatabaseResult(pEx));
        }
    }
}