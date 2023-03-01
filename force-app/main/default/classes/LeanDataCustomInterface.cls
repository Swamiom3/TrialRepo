/********************************************************************************************************* 
    Name: LeanDataCustomInterface() 

    ====================================================== 
    ====================================================== 
    Purpose: Custom code that is called during the LeanData Routing process
    to support custom actions that aren't handled by LeanData Out of the Box
    ------- 
    ====================================================== 
    ====================================================== 
    History 
    ------- 
    VERSION AUTHOR DATE DETAIL FEATURES/CSR/TTP 
    1.0 - Kurt Jurgens 03/22/20019 INITIAL DEVELOPMENT
    1.1 - Andrei Dedovets 09/08/2021 Added is Closed Opportunity check, refactored customRoutingRule() method
 *******************************************************************************************************/
global with sharing class LeanDataCustomInterface extends LeanData.CustomInterface {
    /*This map store opportunity related data.*/
    static Map<Id, Opportunity> mapOpportunity = new Map<Id, Opportunity>();
    private static final String GLOBAL_ACCOUNT_SEGMENT = 'Global Account';
    private static final String ACCOUNT_SALES = 'LeanDataAddOppTM#3';//Value is Account Sales
    private static final String ACCOUNT_DIRECTOR = 'LeanDataassigntoaccountteamdirector';
    private TaskSelector taskSelector = new TaskSelector();
    @TestVisible
    private static final GeographySelector geographySelector = new GeographySelector();
    @TestVisible
    private static UserSelector userSelector = new UserSelector();
    @TestVisible
    private static JourneySelector journeySelector = new JourneySelector();

    /**************************************************************************************************************
           Purpose: Method called in the LeanData Routing process when hitting a custom node
           Parameters: Parameter determines which custom node type to process. Primary is the record
           that is being routed and chosenSObjects is any matched objects found for the primary
           Example: chosenSObjects.get('L2A') is the matched account for lead routing
           Returns: Node edge to continue to traverse the graph correctly depending on the result
           Throws [Exceptions]: [optional]
    *******************************************************************************************************************/
    global override String customRoutingRule(Sobject record, Map<String, Sobject> mapChosenSobjects, String strParameter) {
        String strPoolName;
        Boolean isSamePool;
        if(String.isNotBlank(strParameter) && record != null) {
            switch on strParameter.toLowerCase() {
                when 'get geography as per country code' {
                    List<Lead> leads = [SELECT Id, Country_Code__c FROM Lead WHERE Id =: record.Id];
                    List<Geography__c> geographies = (geographySelector.getGeographiesByCountryCode(leads[0].Country_Code__c));

                    if (geographies.isEmpty()) {
                        return 'False';
                    }

                    record.put('Country_Code_Geography__c', geographies[0].Id);
                    record.put('Territory_Name__c', geographies[0].Nearest_Building__r.Market__r.TerritoryID__r.Name);
                    record.put('CC_Portfolio_Name__c', geographies[0].Nearest_Building__r.Market__r.Name);
                    
                    return 'Next Node';
                }
                when 'update related journeys' {
                    return updateRelatedJourneys(record, true);
                }
                when 'update related journeys without mql' {
                    return updateRelatedJourneys(record, false);
                }
                when 'fire lead assignment rule' {
                    Lead lead = (Lead) record;
                    
                    Database.DMLOptions dmo = new Database.DMLOptions();
                    dmo.assignmentRuleHeader.useDefaultRule= true;
                    lead.setOptions(dmo);
                    
                    update lead;
                    
                    return 'Next Node';
                }
                when 'get lead owner by assignment rule' {
                    List<Lead> leads = [SELECT Id, OwnerId FROM Lead WHERE Id = :record.Id];
                    record.put('OwnerId', leads[0].OwnerId);
                    
                    return 'Next Node';
                }
                when 'capture opportunity old owner' {
                    mapOpportunity = new Map<Id, Opportunity>([
                        SELECT Id, OwnerId, Building__c, Building__r.Market__c, Building__r.Market__r.Name, 
                        Building__r.Market__r.Territory__c, Building__r.Market__r.Region__c, 
                        Building__r.Market__r.Enterprise_Assignment_Override__c 
                        FROM Opportunity 
                        WHERE Id = :record.Id
                    ]);

                    return 'Next Node';
                }
                when 'update account owner' {
                    Account account = LeanDataCustomInterface.getOpportunityAccount(record);
                    
                    if (account != null && String.isNotBlank((String)record.get('OwnerId'))) {
                        account.OwnerId = (Id)record.get('OwnerId');
                        update account;
                        
                        return 'Next Node';
                    }
                }
                when 'assign account to susie' {
                    Account account = LeanDataCustomInterface.getOpportunityAccount(record);
                    
                    if (account != null && ApiUsersUtils.apiUserId != null) {
                        account.OwnerId = ApiUsersUtils.apiUserId;
                        update account;
                        
                        return 'Next Node';
                    }
                }

                when 'add opportunity team member' {
                    if (record.Id == null) {
                        return 'False';
                    }

                    Account account = LeanDataCustomInterface.getOpportunityAccount(record);

                    if (account != null && !isClosedOpportunity(record)) {
                        List<AccountTeamMember> accountTeamMembers = [
                            SELECT Id, UserId
                            FROM AccountTeamMember
                            WHERE TeamMemberRole =: Settings.getTeamRoleConfigSettings('LeanDataAddOppTM#1')
                                AND AccountId = :account.Id
                            ORDER BY CreatedDate ASC
                            LIMIT 1
                        ];
                        if (!accountTeamMembers.isEmpty()) {
                            insert new OpportunityTeamMember(
                                OpportunityId = record.Id,
                                TeamMemberRole = Settings.getTeamRoleConfigSettings('LeanDataAddOppTM#2'),
                                UserId = accountTeamMembers[0].UserId
                            );

                            return 'Next Node';
                        }
                    }
                }

                when 'request co-owner mlb' {
                    Opportunity oldOpportunity = mapOpportunity.get(record.Id);
                    strPoolName = getPoolName(oldOpportunity, true);
                    
                    if (oldOpportunity != null && record != null && String.isNotBlank(strPoolName)) {
                        createOpportunityTeamMemberIfValid(oldOpportunity, (Opportunity)record, strPoolName, true);
                    }
                    record.put('OwnerId', oldOpportunity.OwnerId);
                    
                    return 'Next Node';
                }
                when 'request co-owner ent' {
                    Opportunity oldOpportunity = mapOpportunity.get(record.Id);
                    strPoolName = getPoolName(oldOpportunity, false);
                    
                    if (oldOpportunity != null && record != null && String.isNotBlank(strPoolName)) {
                        createOpportunityTeamMemberIfValid(oldOpportunity, (Opportunity)record, strPoolName, false);
                    } else {
                        record.put('OwnerId', oldOpportunity.OwnerId);
                    }

                    return 'Next Node';
                }
                when 'co-owner for small portfolio manger'{
                    if (record.getSobject('Building__r')?.get('Associate_Director_Market_Sales__c') != null && !isClosedOpportunity(record)) {
                        insert new OpportunityTeamMember(
                            OpportunityId = record.Id, 
                            TeamMemberRole = Settings.getTeamRoleConfigSettings('LeanDatasmallportfmgr'), 
                            UserId = (Id)record.getSobject('Building__r')?.get('Associate_Director_Market_Sales__c')
                        );
                    }
                    record.put('Assignment_Status__c', 'Completed');
                    
                    return 'Next Node';
                }
                when 'co-owner for large portfolio salesperson'{
                    if (record.getSobject('Building__r')?.get('Associate_Director_Portfolio_Sales__c') != null && !isClosedOpportunity(record)) {
                        insert new OpportunityTeamMember(
                            OpportunityId = record.Id, 
                            TeamMemberRole = Settings.getTeamRoleConfigSettings('LeanDatalargeportfsalesperson'), 
                            UserId = (Id)record.getSobject('Building__r')?.get('Associate_Director_Portfolio_Sales__c')
                        );
                    }
                    record.put('Assignment_Status__c', 'Completed');
                    
                    return 'Next Node';
                }
                when 'co-owner for small portfolio salesperson'{
                    if (record.getSobject('Building__r')?.get('Senior_Associate_Market_Sales__c') != null && !isClosedOpportunity(record)) {
                        insert new OpportunityTeamMember(
                            OpportunityId = record.Id, 
                            TeamMemberRole = Settings.getTeamRoleConfigSettings('LeanDatasmallportfsalesperson'), 
                            UserId = (Id)record.getSobject('Building__r')?.get('Senior_Associate_Market_Sales__c')
                        );
                    }
                    record.put('Assignment_Status__c', 'Completed');
                    
                    return 'Next Node';
                }
                when 'co-owner for large portfolio director'{
                    if (record.getSobject('Building__r')?.get('Director_Portfolio_Sales__c') != null && !isClosedOpportunity(record)) {
                        insert new OpportunityTeamMember(
                            OpportunityId = record.Id, 
                            TeamMemberRole = Settings.getTeamRoleConfigSettings('LeanDatalargeportfdirector'), 
                            UserId =  (Id)record.getSobject('Building__r')?.get('Director_Portfolio_Sales__c')
                        );
                    }
                    record.put('Assignment_Status__c', 'Completed');
                    
                    return 'Next Node';
                }
                when 'assign to account team director'{
                    List<AccountTeamMember> accountTeamMembers = [
                        SELECT Id, UserId 
                        FROM AccountTeamMember 
                        WHERE AccountId = :(Id)record.get('AccountId') 
                            AND TeamMemberRole = :Settings.getTeamRoleConfigSettings('LeanDataassigntoaccountteamdirector') 
                            AND User.isActive = true 
                        ORDER BY CreatedDate ASC
                    ];

                    if (!accountTeamMembers.isEmpty()) {
                        record.put('OwnerId', accountTeamMembers[0].UserId);
                        return 'True';
                    } else {
                        return 'False';
                    }
                }
                when 'accountteammember to opportunity' {
                    List<AccountTeamMember> accountTeamMembers = [SELECT Id, UserId FROM AccountTeamMember
                            WHERE AccountId = :(Id)record.get('AccountId') AND TeamMemberRole = :'Territory Co-Prime'
                            AND Region__r.Name = :(String)record.get('Region_Name__c')
                            AND User.IsActive = TRUE ORDER BY CreatedDate ASC LIMIT 1];
                    if(!accountTeamMembers.isEmpty()) {
                        record.put('OwnerId', accountTeamMembers[0].UserId);
                        return 'True';
                    }else {
                        return 'False';
                    }
                }
                when 'sales inquiry task assignment'{
                    Opportunity opportunity = (Opportunity) record;
                    Id apiUserId = UserUtility.getApiUserId();
                    Set<Id> setUserId = new Set<Id>{opportunity.Account.OwnerId, opportunity.OwnerId};
                    Map<Id, User> mapActiveUser = new Map<Id, User>(userSelector.getUsersById(setUserId));
                    if (mapActiveUser.get(opportunity.OwnerId).IsActive) {
                        handleSalesInquiryTask(opportunity, mapActiveUser, apiUserId);
                    }
                    record.put('OwnerId', apiUserId);

                    return 'Next Node';
                }
                when 'usa canada add opportunity team member'{
                    Opportunity opportunity = (Opportunity) record;
                    Id apiUserId = UserUtility.getApiUserId();
                    List<OpportunityTeamMember> opportunityTeamMembersToInsert = new List<OpportunityTeamMember>();
                    
                    if (apiUserId != opportunity.Account.OwnerId && opportunity.Account.Owner.isActive) {
                        opportunityTeamMembersToInsert.add(getTeamMemberForUsaCanadaOpportunity(ACCOUNT_SALES, opportunity.Id, opportunity.Account.OwnerId));
                    }
                    if (String.isBlank(opportunity.Account.Named_Account_Segment__c) || !opportunity.Account.Named_Account_Segment__c.equalsIgnoreCase(GLOBAL_ACCOUNT_SEGMENT)) {
                        insertTeamMemberForUsaCanadaOpportunity(opportunityTeamMembersToInsert, opportunity);
                        
                        return 'Next Node';
                    }
                    if (opportunity.Account.Named_Account_Segment__c.equalsIgnoreCase(GLOBAL_ACCOUNT_SEGMENT)) {
                        checkAndInsertGlobalAccountTeamMemberForUsaCanadaOpportunity(opportunityTeamMembersToInsert, opportunity);
                    }

                    return 'Next Node';
                }
                when else {
                    return 'Next Node';
                }
            }
            return 'False';
        }
        return 'Next Node';
    }

    private void checkAndInsertGlobalAccountTeamMemberForUsaCanadaOpportunity(List<OpportunityTeamMember> opportunityTeamMembersToInsert, Opportunity opportunityRecord){
        for(AccountTeamMember objAccountTeamMember : [SELECT Id, UserId FROM AccountTeamMember WHERE AccountId =: opportunityRecord.AccountId
        AND TeamMemberRole =: Settings.getTeamRoleConfigSettings(ACCOUNT_DIRECTOR)
        AND User.isActive = true ORDER BY CreatedDate ASC]){
            opportunityTeamMembersToInsert.add(getTeamMemberForUsaCanadaOpportunity(ACCOUNT_DIRECTOR, opportunityRecord.Id, objAccountTeamMember.UserId));
        }
        insertTeamMemberForUsaCanadaOpportunity(opportunityTeamMembersToInsert, opportunityRecord);
    }

    private void insertTeamMemberForUsaCanadaOpportunity(List<OpportunityTeamMember> opportunityTeamMembersToInsert, Opportunity opportunityRecord){
        opportunityRecord.put('Assignment_Status__c', 'Completed');
        if(!opportunityTeamMembersToInsert.isEmpty()){
            insert opportunityTeamMembersToInsert;
        }
    }

    private OpportunityTeamMember getTeamMemberForUsaCanadaOpportunity(String teamRoleSettingName, Id opportunityId, Id userId){
        return new OpportunityTeamMember(OpportunityId = opportunityId,
                TeamMemberRole = Settings.getTeamRoleConfigSettings(teamRoleSettingName),
                UserId = userId);

    }

    @TestVisible
    private void handleSalesInquiryTask(Opportunity objOpportunity, Map<Id, User> mapUsers, Id apiUserId){
        List<Task> lstSalesInquiryTasks = new List<Task>();
        for(Task objTask : taskSelector.getSalesInquiryTasksByWhatIds(new List<Id>{ objOpportunity.Id })){
            objTask.OwnerId = objOpportunity.OwnerId;
            objTask.WhatId = objOpportunity.AccountId;
            lstSalesInquiryTasks.add(objTask);
        }
        if(!lstSalesInquiryTasks.isEmpty()){
            UPDATE lstSalesInquiryTasks;
            sendSalesInquiryEmail(lstSalesInquiryTasks, objOpportunity, mapUsers.get(objOpportunity.Account.OwnerId), apiUserId);
            AsyncsExecutor asyncsExecutor = new AsyncsExecutor(QueueDmlOnSobjects.class,
                    new Map<String, Object>{
                            'SObjects'=> new List<SObject>{objOpportunity},
                            'isDelete'=> true,
                            'isUpdate'=> false,
                            'isInsert'=> false,
                            'isUndelete'=> false,
                            'allowPartialSave'=> false
                    });
            asyncsExecutor.execute();
        }
    }

    @TestVisible
    private void sendSalesInquiryEmail(List<Task> tasks, Opportunity opportunityRecord, User userRecord, Id apiUserId) {
        EmailTemplate salesInquiryEmailTemplate =
                EmailService.getEmailTemplateByDeveloperName('Sales_Inquiry');
        List<Messaging.SingleEmailMessage> emailMessages = new List<Messaging.SingleEmailMessage>();
        List<String> ccAddresses = new List<String>();
        if(salesInquiryEmailTemplate == null) {
            ApexDebugLog.logException(new LeanDataCustomInterfaceException('No email template for \'Sales_Inquiry\''), 'tasks==>'+tasks, 'LeanDataCustomInterface', 'sendSalesInquiryEmail');
            return;
        }
        for (Task taskRecord : tasks) {
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setTemplateId(salesInquiryEmailTemplate.Id);
            email.setWhatId(taskRecord.Id);
            email.setOrgWideEmailAddressId(EmailService.getOrganizationWideDefaultAddressId());
            email.setSaveAsActivity(false);
            email.setTargetObjectId(taskRecord.OwnerId);
            if (String.isNotBlank(taskRecord.Building__r.Email__c)) {
                ccAddresses.add(taskRecord.Building__r.Email__c);
            }
            if (String.isNotBlank(opportunityRecord.Account_Manager_Email__c)) {
                ccAddresses.add(opportunityRecord.Account_Manager_Email__c);
            }
            if (String.isNotBlank(opportunityRecord.Account.Named_Account_Segment__c)
                    && userRecord.Id != apiUserId && userRecord.IsActive
                    && !opportunityRecord.Account.Named_Account_Segment__c.equalsIgnoreCase('Bullpen')) {
                ccAddresses.add(userRecord.Email);
            }
            if (String.isNotBlank(taskRecord.Building__r.Leasing_Manager_Id__r.Email)) {
                ccAddresses.add(taskRecord.Building__r.Leasing_Manager_Id__r.Email);
            }
            if (String.isNotBlank(taskRecord.Building__r.Leasing_Director_Id__r.Email)) {
                ccAddresses.add(taskRecord.Building__r.Leasing_Director_Id__r.Email);
            }
            if (!ccAddresses.isEmpty()) {
                email.setCcAddresses(ccAddresses);
            }
            emailMessages.add(email);
        }
        if (!emailMessages.isEmpty()) {
            Messaging.sendEmail(emailMessages);
        }
    }

    global static Account getOpportunityAccount(sObject opportunity) {
        Id accountId = (Id)opportunity.get('AccountId');
        Account objAcount;

                if(String.isNotBlank(accountId)){
                    objAcount = [SELECT Id, OwnerId FROM Account WHERE Id = :accountId];
                }

        return objAcount;
    }

    static void createOpportunityTeamMemberIfValid(Opportunity objOpportunity, Opportunity objUpdatedOpportunity, String strPoolName, Boolean isMLBOpportunity){
        Boolean isSamePool = isbothUserSamePool(objOpportunity.OwnerId, objUpdatedOpportunity.OwnerId, strPoolName);
        if (isSamePool) {
            if (!isMLBOpportunity) {
                objUpdatedOpportunity.put('OwnerId', objOpportunity.OwnerId);
            }
        }else if (!isClosedOpportunity(objUpdatedOpportunity)) {
            String oppAccessLevel = String.isNotBlank(Label.LeanDataOppTeamMemberCreation) ?  Label.LeanDataOppTeamMemberCreation : 'Read';
            insert new OpportunityTeamMember(OpportunityId = objUpdatedOpportunity.Id, TeamMemberRole = Settings.getTeamRoleConfigSettings('LeanDatacreateOppTeam'), UserId = isMLBOpportunity ? objUpdatedOpportunity.OwnerId : objOpportunity.OwnerId, OpportunityAccessLevel = oppAccessLevel, Primary_Tour_Assist__c = false, TeamMemberCreationSource__c = 'RequestCoOwner');
        }
    }

    static Boolean isbothUserSamePool(Id oldOwnerId, Id newOwnerId, String strPoolName){
        if(oldOwnerId == newOwnerId){
            return true;
        }
        List<LeanData__Round_Robin_Pool__c> lstRoundRobinPools = new List<LeanData__Round_Robin_Pool__c>([SELECT Id FROM LeanData__Round_Robin_Pool__c WHERE LeanData__Object_Type__c = 'Opportunity' AND LeanData__Grouping_Name__c LIKE :strPoolName LIMIT 1]);

        if(!lstRoundRobinPools.isEmpty()){
            Set<Id> setPoolUserIds = new Set<Id>();
            for(LeanData__Round_Robin_Setting__c roundRobinSetting : [SELECT Id, LeanData__OwnerId__c, LeanData__Grouping__c, LeanData__Grouping_Name__c FROM LeanData__Round_Robin_Setting__c WHERE LeanData__Grouping__c = :lstRoundRobinPools[0].Id]){
                setPoolUserIds.add(roundRobinSetting.LeanData__OwnerId__c);
            }
            if(setPoolUserIds.contains(Id.valueOf(oldOwnerId)) && setPoolUserIds.contains(Id.valueOf(newOwnerId))){
                return true;
            }
        }
        return false;
    }

    static String getPoolName(Opportunity objOpportunity, Boolean isMLBType){
        String strRoundRobinType = objOpportunity.Building__r != null && objOpportunity.Building__r.Market__c != null ? String.isNotBlank(objOpportunity.Building__r.Market__r.Enterprise_Assignment_Override__c) ? objOpportunity.Building__r.Market__r.Enterprise_Assignment_Override__c : 'Portfolio' : null;
        if(String.isNotBlank(strRoundRobinType)){
            String strRoundRobinName = strRoundRobinType.equalsIgnoreCase('Portfolio') ? objOpportunity.Building__r.Market__r.Name : strRoundRobinType.equalsIgnoreCase('Territory') ?  objOpportunity.Building__r.Market__r.Territory__c : strRoundRobinType.equalsIgnoreCase('Region') ? objOpportunity.Building__r.Market__r.Region__c : null;
            return strRoundRobinType +' '+(isMLBType ? 'MM' : 'ENT')+' '+strRoundRobinName;
        }
        return null;
    }

    public static String updateRelatedJourneys(Sobject opportunity, Boolean isMQL){

        Id leadOwnerId =  opportunity.get('OwnerId') != null ? (Id)opportunity.get('OwnerId') : null;
        String objRestrictUpdateJourneyStatusAsMQL = Label.RestrictUpdateJourneyStatusAsMQL;
        Set<String> setRestrictUpdateJourneyStatusAsMQL = new Set<String>();
        if(String.isNotBlank(objRestrictUpdateJourneyStatusAsMQL)){
            setRestrictUpdateJourneyStatusAsMQL = Settings.splitStringToSet(objRestrictUpdateJourneyStatusAsMQL.toLowerCase(), ',');
        }
        if(String.isNotBlank(leadOwnerId)){
            List<Journey__c> lstJourneysToUpdate = new List<Journey__c>();
            List<String> fields = new List<String>{'Id', 'OwnerId', 'Routing_Qualification_Result__c', 'Status__c'};
            for(Journey__c objJourney : journeySelector.getJourneyByCreatedDateAndLeadId(fields, opportunity.Id)){
                if(objJourney.ownerId != leadOwnerId){
                    Journey__c objTempJourney = new Journey__c(Id = objJourney.Id, OwnerId = leadOwnerId, Routing_Qualification_Result__c = (String)opportunity.get('Routing_Qualification_Result__c'));
                    if(String.isBlank(objJourney.Status__c) || (String.isNotBlank(objJourney.Status__c) && !setRestrictUpdateJourneyStatusAsMQL.contains(objJourney.Status__c.toLowerCase()))){
                        if(isMQL){
                            objTempJourney.Status__c = 'MQL';
                        }else if(String.valueOf(objTempJourney.OwnerId.getSobjectType()).equalsIgnoreCase('User')){
                            objTempJourney.Status__c = 'Accepted';
                        }
                    }
                    lstJourneysToUpdate.add(objTempJourney);
                }
            }
            if(!lstJourneysToUpdate.isEmpty()){
                update lstJourneysToUpdate;
            }
            return 'Next Node';
        }
        return 'False';
    }

    static Boolean isClosedOpportunity(SObject opportunity) {
        return (Boolean) opportunity.get('IsClosed');
    }

    public class LeanDataCustomInterfaceException extends Exception{}
}