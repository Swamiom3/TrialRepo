/************************************************************************************************************************************
    Author      :     Pragalbha Mahajan
    Description :     This class contains the business logic of sending Email to REA case.
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION      DATE                   AUTHOR                      DETAIL
    1            22 October 2019        Pragalbha Mahajan           Initial Development
    2            17 March 2020          Ashish Sharma               Modifications for ST-5905
    3            16 Jun 2021            Tomasz Sadowski             ST-8436 - Migration to new trigger framework
**************************************************************************************************************************************/
public class CaseEmailNotificationReaTrH extends SObjectTriggerHandler{
    @TestVisible
    private List<Case> newCases;
    @TestVisible
    private static Integer emailNotificationCount = 0;
    @TestVisible
    private final static String TRANSACTION_STRATEGY = 'REA-Transaction Strategy';
    @TestVisible
    private final static String COMM_TERM_REQUEST_TYPE = 'Commercial Terms';
    @TestVisible
    private static Map<Id, Case> reaCasesWithTerritory = new Map <Id,Case>();
    Id REA_CASE_RECORD_TYPE_ID = Schema.SObjectType.Case.getRecordTypeInfosByName().get(GlobalConstants.CASE_RT_NAME_REA).getRecordTypeId();


    public CaseEmailNotificationReaTrH() {
        this(
            (List<Case>) Trigger.new
        );
    }
    
    @TestVisible
    private CaseEmailNotificationReaTrH(List<Case> newCases) {
        this.newCases = this.returnOnlyObjectWithValidRT(Case.SObjectType, 
                                                          newCases,
                                                          CaseConstants.CASE_SALES_RECORD_TYPE);
    }
    
    public override void afterInsert() {
        sendEmailToValidCases();
    }
    
    public void sendEmailToValidCases() {
        reaCasesWithTerritory = getCasesWithTerritoires();
        List<Case> filteredCases = prepareCaseActors();
        Map<Id, Case> caseIdToCase = new Map<Id,Case>(filteredCases);
        Set<Id> accountIds = prepareAccountActors(filteredCases);
        Map<String, Set<String>> accountIdToEmailAddresses = new Map<String, Set<String>>();
        Map<String, Set<String>> queueNameToEmailAddresses = new Map<String, Set<String>>();
        if (!caseIdToCase.isEmpty()) {
            getQueueMembersEmails(queueNameToEmailAddresses);
            getAccountTeamMembersEmails(accountIds, accountIdToEmailAddresses);
        }
        if (!queueNameToEmailAddresses.isEmpty() && !caseIdToCase.isEmpty()) {
            if (!(System.isBatch() || System.isFuture())) {       
                sendEmailInFuture(JSON.serialize(caseIdToCase), JSON.serialize(queueNameToEmailAddresses), JSON.serialize(accountIdToEmailAddresses)); 
            } else {
                sendEmail(caseIdToCase, queueNameToEmailAddresses, accountIdToEmailAddresses);
            }
        }
    }

    private List<Case> prepareCaseActors() {
        List<Case> filteredCases = new List<Case>();
        Id reaCaseRtId = Schema.SObjectType.Case.getRecordTypeInfosByName().get(GlobalConstants.CASE_RT_NAME_REA).getRecordTypeId();
        for (Case caseRecord : newCases) {
            if (reaCasesWithTerritory.containsKey(caseRecord.Id) && verifyCaseHasTerritory(caseRecord, reaCasesWithTerritory.get(caseRecord.Id))) {
                filteredCases.add(caseRecord);
            }
        }
        return filteredCases;
    }
       
    private Set<Id> prepareAccountActors(List<Case> filteredCases) {
        Set<Id> accountIds = new Set<Id>();
        for (Case caseRecord : newCases) {
            if (caseRecord.AccountId == null) {
                continue;
            }
            accountIds.add(caseRecord.AccountId);
        }
        return accountIds;
    }
    
    public static void getQueueMembersEmails(Map<String, Set<String>> queueNameToEmailAddresses) {
        for (GroupMember groupMember : [SELECT Id, GroupId, UserOrGroupId, Group.Name, Group.Email FROM GroupMember
                                        WHERE GroupId IN (SELECT Id FROM Group WHERE Type = 'Queue' AND Name LIKE 'REA-%')]) {
            if (groupMember.Group.Name == TRANSACTION_STRATEGY && String.isNotBlank(groupMember.Group.Email)) {
                if (!queueNameToEmailAddresses.containsKey(groupMember.Group.Name)) {
                    queueNameToEmailAddresses.put(groupMember.Group.Name, new Set<String>{groupMember.Group.Email.toLowerCase()});
                } else {
                    queueNameToEmailAddresses.get(groupMember.Group.Name).add(groupMember.Group.Email.toLowerCase());
                }
            }
            if (String.isNotBlank(groupMember.UserOrGroupId) && String.valueOf(groupMember.UserOrGroupId.getSobjectType()) == 'User') {
                User userRecord = UserUtility.getUserById(groupMember.UserOrGroupId);
                if(userRecord == null || !EmailService.isValidUserToSendEmailOnOwnerChange(userRecord.ProfileId)) {
                    continue;
                }
                if (!queueNameToEmailAddresses.containsKey(groupMember.Group.Name)) {
                    queueNameToEmailAddresses.put(groupMember.Group.Name, new Set<String>{userRecord.Email.toLowerCase()});
                } else {
                    queueNameToEmailAddresses.get(groupMember.Group.Name).add(userRecord.Email.toLowerCase());
                }
            }
        }
    }
    
    public static void getAccountTeamMembersEmails(Set<Id> accountIds, Map<String, Set<String>> accountIdToEmailAddresses) {
        if (!accountIds.isEmpty()) {
            Map<Id, Id> accountIdToParentAccountId = new Map<Id, Id>();
            for (Account accountRecord : [SELECT Id, Parent_Org_Id__c, Account_Type__c FROM Account WHERE Id IN :accountIds]) {                
                if (accountRecord.Account_Type__c == 'Sales') {
                    accountIdToParentAccountId.put(accountRecord.Id, accountRecord.Parent_Org_Id__c);
                } else {
                    accountIdToParentAccountId.put(accountRecord.Id, accountRecord.Id);
                }
            }
            if (!accountIdToParentAccountId.isEmpty()) {
                for (AccountTeamMember accountTeamMember : [SELECT Id, UserId, User.Email,User.ProfileId, AccountId, TeamMemberRole
                                                            FROM AccountTeamMember WHERE AccountId IN :accountIdToParentAccountId.values()
                                                                                         AND TeamMemberRole = :GlobalConstants.USER_ATTRIBUTE_REA]) {
                    for (Id accountId : accountIdToParentAccountId.keySet()) {
                        Id parentAccountId = accountIdToParentAccountId.get(accountId) != null ? accountIdToParentAccountId.get(accountId) : null;
                        if (parentAccountId != null && parentAccountId == accountTeamMember.AccountId && EmailService.isValidUserToSendEmailOnOwnerChange(accountTeamMember.User.ProfileId)) {
                            if (!accountIdToEmailAddresses.containsKey(accountId)) {
                                accountIdToEmailAddresses.put(accountId, new Set<String>{accountTeamMember.User.Email.toLowerCase()});
                            } else {
                                accountIdToEmailAddresses.get(accountId).add(accountTeamMember.User.Email.toLowerCase());
                            }
                        }
                    }                    
                }
            }
        }
    }
    
    public static void sendEmail(Map<Id, Case> caseIdToCase, Map<String, Set<String>> queueNameToEmailAddresses, Map<String, Set<String>> accountIdToEmailAddresses) {
        List<Messaging.SingleEmailMessage> emailsToSend = new List<Messaging.SingleEmailMessage>();
        EmailTemplate objEmailTemplate = Settings.getEmailTemplateByDeveloperName('REA_Asset_Region_Email_Notification'); 
        if (objEmailTemplate != null) {
            for (Id caseId : caseIdToCase.keySet()) {
                Case caseRecord = caseIdToCase.get(caseId);
                Set<String> toAddresses = new Set<String>();
                String currentCaseTerritory = getCaseTerritory(reaCasesWithTerritory?.get(caseId));
                if (caseRecord.REA_Request_Type__c == COMM_TERM_REQUEST_TYPE && queueNameToEmailAddresses.containsKey(TRANSACTION_STRATEGY)) {
                    toAddresses = queueNameToEmailAddresses.get(TRANSACTION_STRATEGY);
                } else {
                    if (reaCasesWithTerritory.containsKey(caseId) 
                        && queueNameToEmailAddresses.containsKey('REA-' + currentCaseTerritory)) {
                    toAddresses = queueNameToEmailAddresses.get('REA-' + currentCaseTerritory);
                    }
                }
                Set<String> ccAddresses = new Set<String>();
                if (!accountIdToEmailAddresses.isEmpty() && caseRecord.AccountId != null && accountIdToEmailAddresses.containsKey(caseRecord.AccountId)) {
                    ccAddresses = accountIdToEmailAddresses.get(caseRecord.AccountId);
                }
                if (toAddresses.isEmpty()) {
                    continue;
                }
                Messaging.SingleEmailMessage singleEmail = new Messaging.SingleEmailMessage();
                singleEmail.setTargetObjectId(UserInfo.getUserId());
                singleEmail.setWhatId(caseRecord.Id);
                singleEmail.setTemplateId(objEmailTemplate.Id);
                if (!ccAddresses.isEmpty()) {
                    singleEmail.ccAddresses = new List<String>(ccAddresses);
                }
                singleEmail.setTreatTargetObjectAsRecipient(false);
                singleEmail.setSaveAsActivity(false);
                singleEmail.toAddresses = new List<String>(toAddresses);
                emailsToSend.add(singleEmail);
            }
        }
        if (!emailsToSend.isEmpty()) {            
            Messaging.sendEmail(emailsToSend);
            emailNotificationCount = Limits.getEmailInvocations();
        }
    }
    
    @future
    public static void sendEmailInFuture(String serializedCasesToSendMail, String serializedQueueWithUserIds, String serializedAccountTeamWithEmail) {
        Map<Id, Case> caseIdToCases = (Map<Id, Case>) JSON.deserialize(serializedCasesToSendMail, Map<Id, Case>.class);
        Map<String, Set<String>> queueNameToEmailAddresses = (Map<String, Set<String>>) JSON.deserialize(serializedQueueWithUserIds, Map<String, Set<String>>.class);
        Map<String, Set<String>> accountIdToEmailAddresses;
        if (String.isNotBlank(serializedAccountTeamWithEmail)) {
            accountIdToEmailAddresses = (Map<String, Set<String>>) JSON.deserialize(serializedAccountTeamWithEmail, Map<String, Set<String>>.class);
        }
        sendEmail(caseIdToCases, queueNameToEmailAddresses, accountIdToEmailAddresses);
    }
    @TestVisible
    private Map<Id, Case> getCasesWithTerritoires() {
        Set<Id> caseIds = new Map<Id,Case>(newCases).keySet();
        return new Map<Id, Case>([SELECT Id, Building_Nearest_Address__r.Market__r.TerritoryID__r.Name FROM Case 
                WHERE RecordTypeId = :REA_CASE_RECORD_TYPE_ID 
                AND Id IN :caseIds]);
    }
    @TestVisible
    private Boolean verifyCaseHasTerritory(Case caseInTrigger, Case caseWithTerritory) {
        if (caseInTrigger == null || caseWithTerritory == null) {
            return false;
        }
        if (caseWithTerritory?.Building_Nearest_Address__r?.Market__r?.TerritoryID__r?.Name == null) {
            return false;
        }        
        return true;
    }
    @TestVisible
    private static String getCaseTerritory(Case caseWithTerritory) {
        if (caseWithTerritory == null) {
            return '';
        }
        return caseWithTerritory.Building_Nearest_Address__r.Market__r.TerritoryID__r.Name; 
    }
}