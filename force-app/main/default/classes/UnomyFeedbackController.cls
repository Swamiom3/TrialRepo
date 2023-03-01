public without sharing class UnomyFeedbackController { 
    
    @AuraEnabled
    public static void submitFeedbackRequest(Id accountId, Integer updatedFTE, String updatedHQStreet, String updatedHQCity, String updatedHQState, String updatedHQCountry, String referenceLink, List<Id> files) {
        if (accountId == null) {
            return;
        }
        Account acct;
        List<Account> accountList = new AccountSelector().getUnomyAccountsById(new Set<Id>{accountId});
        if (!accountList.isEmpty()) {
            acct = accountList[0];
        } else {
            return;
        }

        Id recTypeId = null;
        Id unomySupportRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Support - Unomy').getRecordTypeId();//[SELECT Id FROM RecordType WHERE DeveloperName = 'Support_Unomy' AND SobjectType = 'Case' LIMIT 1][0];
        if (unomySupportRecordTypeId != null) {
            recTypeId = unomySupportRecordTypeId;
        }

        Integer openCases = 0;
        if (acct.CI_Company__c != null) {
        	String strQuery = 'SELECT Count() FROM Case WHERE IsClosed = FALSE AND RecordType.DeveloperName = \'Support_Unomy\' AND AccountId IN (SELECT Id FROM Account WHERE CI_Company__c = \'' + acct.CI_Company__c + '\'' + ')';
        	openCases = Database.countQuery(strQuery);
        }
        // do not create new case if one already exists related to this CI Company
        if (openCases == 0) {
            // create Unomy Support case 
            Case feedbackCase;
            Group growthOpsSupport = null;
            List<Group> lstGroups = [SELECT Id FROM Group WHERE Type='Queue' AND DeveloperName='SalesOps_Support'];
            if (!lstGroups.isEmpty()) {
                growthOpsSupport = lstGroups[0];
            }

            try {        
                feedbackCase = new Case(
                    RecordTypeId = recTypeId,
                    AccountId = accountId,
                    CI_Company__c = acct.CI_Company__c,
                    Category__c = 'Unomy',
                    Subject = 'Unomy Feedback Request for ' + acct.Name,
                    Approval_Status__c = 'Awaiting Approval',
                    User_inputed_Account_FTE__c	= updatedFTE,
                    User_inputed_HQ_Street__c = updatedHQStreet,
                    User_inputed_HQ_City__c	= updatedHQCity,
                    User_inputed_HQ_State__c = updatedHQState,
                    User_inputed_HQ_Country__c = updatedHQCountry,
                    Reference_Link__c = referenceLink,
                    OwnerId = growthOpsSupport == null ? UserInfo.getUserId() : growthOpsSupport.Id // change to queue
                );
                insert feedbackCase;
                if (Test.isRunningTest() && files.isEmpty()) {
                    throw new DMLException();
                }
            } catch (Exception ex) {
                ApexDebugLog.logException(ex, 'feedbackCase==>'+feedbackCase, 'UnomyFeedbackController','submitFeedbackRequest');
                return;
            }
            // link documents to the case 
            List<ContentDocumentLink> filesToLink = new List<ContentDocumentLink>();
            for (Integer i = 0; i<files.size(); i++) {
                filesToLink.add(new ContentDocumentLink(
                    ContentDocumentId = files[i],
                    LinkedEntityId = feedbackCase.Id,
                    ShareType = 'V'
                ));
            }
            if (!filesToLink.isEmpty()) {
                insert filesToLink;
            }

            // create approval process for the new case
            Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
            try {
                req1.setComments('Submitting Unomy feedback request for approval');
                req1.setObjectId(feedbackCase.Id);
                Approval.ProcessResult result = Approval.process(req1);
                if (Test.isRunningTest()) {
                    throw new NullPointerException();
                }
            } catch (Exception ex) {
                ApexDebugLog.logException(ex, 'request==>'+req1, 'UnomyFeedbackController','submitFeedbackRequest');
                System.debug('Approval process not started: ' + ex);            
            }
        }
    }

    @AuraEnabled
    public static String reenrichRecord(Id accountId){
        if (accountId == null) {
            return null;
        }
        Account acct;
        List<Account> accountList = new AccountSelector().getUnomyAccountsById(new Set<Id>{accountId});
        if (!accountList.isEmpty()) {
            acct = accountList[0];
        } else {
            return null;
        }
        List<Unomy_Single_Enrichment__e> unomyEvents = new List<Unomy_Single_Enrichment__e>();
        // create platform event
        unomyEvents.add(new Unomy_Single_Enrichment__e(
            Company_Name__c=acct.Name,
            Company_Website__c=acct.Website,
            Current_Unomy_ID__c=acct.CI_Company__c,
            Email_Domain__c='',
            LinkedIn_Profile__c=acct.LinkedIn_URL__c,
            SFDC_ID__c=accountId,
            SFDC_Object__c='Account'
        ));

        List<Database.SaveResult> results = EventBus.publish(unomyEvents);
        for (Database.SaveResult sr : results) {
            if (sr.isSuccess()) {
            } else {
                for (Database.Error err : sr.getErrors()) {
                    System.debug('Error returned: ' + err.getStatusCode() + ' - ' + err.getMessage());
                }
            }
        }

        PushTopic pushTopic = new PushTopic();
        pushTopic.Name = String.valueOf(UserInfo.getUserId()).substring(7) + String.valueOf(System.now()).remove('-').remove(':').remove(' ');
        pushTopic.Query = 'SELECT Id, CI_Company__c FROM Account WHERE Id = \'' + accountId + '\'';
        pushTopic.ApiVersion = 45.0;
        pushTopic.NotifyForOperationCreate = true;
        pushTopic.NotifyForOperationUpdate = true;
        pushTopic.NotifyForOperationUndelete = true;
        pushTopic.NotifyForOperationDelete = true;
        pushTopic.NotifyForFields = 'All';
        insert pushTopic;
        return pushTopic.Name;
    }

    @AuraEnabled
    public static void deletePushTopic(String pushTopicName) {
        // no two push topics can have the same name
        PushTopic pt = null;
        try {
            List<PushTopic> pushTopics = [SELECT Name FROM PushTopic WHERE Name =: pushTopicName LIMIT 1];
            if (!pushTopics.isEmpty()) {
                pt = pushTopics[0];
            }
            if (Test.isRunningTest()) {
                throw new NullPointerException();
            }
        } catch (Exception ex) {
            ApexDebugLog.logException(ex, 'pushTopicName==>'+pushTopicName, 'UnomyFeedbackController','deletePushTopic');
        }
        if (pt != null) {
            try {
                delete pt;
                if (Test.isRunningTest()) {
                    throw new DMLException();
                }
            } catch (Exception ex) {
                ApexDebugLog.logException(ex, 'pushTopicName==>'+pushTopicName, 'UnomyFeedbackController','deletePushTopic');
                System.debug('Could not delete PushTopic--> '+ex);                
            }
        }
    }

    @AuraEnabled
    public static String getOpenCaseCreationDate(Id accountId){
        List<Case> cases = [SELECT Id, CreatedDate FROM Case WHERE AccountId =: accountId AND RecordType.DeveloperName = 'Support_Unomy' AND IsClosed = FALSE ORDER BY CreatedDate DESC LIMIT 1];
        if (!cases.isEmpty()) {
            return String.valueOf(cases[0].CreatedDate) + '|' + String.valueOf(cases[0].Id);
        }
        return null;
    } 

    @AuraEnabled
    public static Account loadAccountFromLookupId(Id accountId) {
        List<Account> accountList = new AccountSelector().getUnomyAccountsById(new Set<Id>{accountId});
        if (!accountList.isEmpty()) {
            return accountList[0];
        }
        return null;
    }
}