/**********************************************************************************************************************************
    Author      : Ramsey Solutions
    Description : Placeholder for different Task triggers logic
    ---------------------------------------------------------------------------------------------------------------------------------
    VERSION    DATE            AUTHOR             DETAIL
    1          18 Jan, 2016    RamseySolutions    Placeholder for different Task triggers
    2          12 Jun, 2018    Krishana Tupe      Changes for Optimize the Task trigger
    3          9 Apr, 2021     Pawel Biszczak     Refactor for data mocking
    4          17 Feb, 2022    Ishwar Shinde      Migration to new trigger framework
*****************************************************************************************************************************************/
public class TaskTriggerHandler extends SObjectTriggerHandler{
    @TestVisible
    private List<Task> newTasks;
    @TestVisible
    private Map<Id, Task> newTasksMap;
    @TestVisible
    private List<Task> oldTasks;
    @TestVisible
    private Map<Id, Task> oldTasksMap;
    
    @TestVisible
    private TaskSelector taskSelector = new TaskSelector();
    @TestVisible
    private JourneySelector journeySelector = new JourneySelector();
    @TestVisible
    private ContactSelector contactSelector = new ContactSelector();
    @TestVisible
    private GroupMemberSelector groupMemberSelector = new GroupMemberSelector();
    @TestVisible
    private LeadSelector leadSelector = new LeadSelector();
    
    private static Set<Id> journeysWithUpdatedOwnersIds = new Set<Id>();
    private static Set<Id> tasksWithUpdatedContactsIds;
    public static Boolean updateFiredFromInsertMethod = false;
    
    public TaskTriggerHandler(){
        this((List<Task>) Trigger.new, (Map<Id, Task>) Trigger.newMap, (List<Task>) Trigger.old, (Map<Id, Task>) Trigger.oldMap);
    }
    @TestVisible
    private TaskTriggerHandler(List<Task> newTasks, Map<Id, Task> newTasksMap, List<Task> oldTasks, Map<Id, Task> oldTasksMap){
    	this.newTasks = newTasks;
        this.newTasksMap = newTasksMap;
        this.oldTasks = oldTasks;
        this.oldTasksMap = oldTasksMap;
    }

    public override void beforeInsert(){
        updateFiredFromInsertMethod = true;
        updateActiveReferrer();
        updateOutreachStageOnJourney();
        updateTaskTypeOnInsert();
        updateTaskFieldsForNVMCalls();
    }

    public override void afterInsert() {
        updateFiredFromInsertMethod = true;
        updateLeadEngagementFields();
        updateContactOnTask();
    }

    public override void beforeUpdate(){
        updateJourneyNMDNextContactDate();
        updateOutreachStageOnJourney();
        //Commented as a part of Q2C Org Consolidation
        // if(TriggerSettings.mappedField.Task_ChangeOwnerToFirstUserWhoRespond)
           // changeTaskOwner((List<Task>)newTasks, (Map<Id, Task>) newTasksMap, (List<Task>)oldTasks, (Map<Id, Task>)oldTasksMap);
        updateTaskTypeOnUpdate();
        updateTaskFieldsForNVMCalls();
    }

    public override void afterUpdate(){
        updateContactOnTask();
    }

    public void updateLeadEngagementFields() {
        updateRecords(getRecordsToUpdateEngagementFields(newTasks));
    }

    public List<Lead> getRecordsToUpdateEngagementFields(List<Task> newTasks) {
        Set<Id> leadIds = new Set<Id>();
        for (Task taskRecord : newTasks) {
            if (String.isNotBlank(taskRecord.WhoId) && OrganizationHelper.isLead(taskRecord.WhoId)
                && String.isNotBlank(taskRecord.Subject) && taskRecord.Subject.startsWith('Engage Campaign:')) {
                leadIds.add(taskRecord.WhoId);
            }
        }
        if (leadIds == null || leadIds.isEmpty()) {
            return new List<Lead>();
        }
        Map<Id, Lead> leadsByIds = new Map<Id, Lead>(leadSelector.getLeadsById(new List<Id>(leadIds)));
        if (leadsByIds.isEmpty()) {
            return new List<Lead>();
        }
        for (Task taskRecord : newTasks) {
            if (leadsByIds.containsKey(taskRecord.WhoId)) {
                Lead leadRecord = leadsByIds.get(taskRecord.WhoId);
                //Commented as a part of Q2C Org Consolidation
                // leadRecord.Engage_Emails_Sent__c = leadRecord.Engage_Emails_Sent__c == null ? 1 : leadRecord.Engage_Emails_Sent__c + 1;
                // leadRecord.Last_Engage_Email_Sent__c = taskRecord.CreatedDate;
            }
        }
        return leadsByIds.values();
    }
    public class QueueRoundRobinSettings {
        public String excludeprofiles { get; set; }
        public String[] types { get; set; }
        public String[] status { get; set; }
        public String[] excludesubjects { get; set; }
    }

    //Commented as a part of Q2C Org Consolidation

    /*public void changeTaskOwner(List<Task> newTasks, Map<Id, Task> newTasksMap, List<Task> oldTasks, Map<Id, Task> oldTasksMap) {
        updateRecords(getRecordsToChangeTaskOwner(newTasks));
    }

    public List<SObject> getRecordsToChangeTaskOwner(List<Task> newTasks){
        Sales_Console_Setting__mdt settingsQueue = SalesConsoleSettings.get('QueueManagementSettings');
        //If no settings are found do not process the queue
        if (settingsQueue == null || String.isBlank(settingsQueue.Data__c)) {
            return new List<SObject>();
        }
        Set<String> types = new Set<String>();
        Set<String> statuses = new Set<String>();
        Set<String> excludedSubjects = new Set<String>();
        Set<Id> journeysIds = new Set<Id>();
        Set<Id> leadsIds = new Set<Id>();

        QueueRoundRobinSettings setting = (QueueRoundRobinSettings) JSON.deserialize(settingsQueue.Data__c, QueueRoundRobinSettings.class);
        if (setting.types != null) {
            types = new Set<String>(setting.types);
        }
        if (setting.status != null) {
            statuses = new Set<String>(setting.status);
        }
        if (setting.excludesubjects != null) {
            excludedSubjects = new Set<String>(setting.excludesubjects);
        }

        for (Task task : newTasks) {
            if (statuses.contains(task.Status) && (types.contains(task.Type)) && (!excludedSubjects.contains(task.Subject))) {
                //Find out WhatId which are Journey.
                if (String.isNotBlank(task.WhatId) && OrganizationHelper.isJourney(task.WhatId)) {
                    journeysIds.add(task.WhatId);
                }
                //Find out WhoId which are Lead.
                if (String.isNotBlank(task.WhoId) && OrganizationHelper.isLead(task.WhoId)) {
                    leadsIds.add(task.WhoId);
                }
            }
        }

        List<SObject> recordsToUpdate = new List<SObject>();
        recordsToUpdate.addAll(getChangeTaskOwnerRecordsForLeads(leadsIds));
        recordsToUpdate.addAll(getChangeTaskOwnerRecordsForJourneys(journeysIds));
        return recordsToUpdate;
    }

    public List<SObject> getChangeTaskOwnerRecordsForLeads(Set<Id> leadsIds) {
        if (leadsIds == null || leadsIds.isEmpty()) {
            return new List<SObject>();
        }
        Id currentUserId = UserInfo.getUserId();
        List<GroupMember> queueMembers = new List<GroupMember>();
        Set<Id> leadOwnersFromQueue = new Set<Id>();
        List<Lead> leadsToUpdate = new List<Lead>();
        List<Journey__c> leadJourneysToUpdate = new List<Journey__c>();

        List<Lead> leadsWithOwnersIds = new List<Lead>(leadSelector.getLeadsById(new List<Id>(leadsIds)));
        List<Journey__c> leadsJourneys = new List<Journey__c>(journeySelector.getJourneysByLeadsIds(new List<Id>(leadsIds)));
        //Find out list of queues which are require.
        for (Lead leadRecord : leadsWithOwnersIds) {
            if (OrganizationHelper.isGroup(leadRecord.OwnerId)) {
                leadOwnersFromQueue.add(leadRecord.OwnerId);
            }
        }
        //Find out members of queue.
        if (leadOwnersFromQueue.isEmpty()) {
            return new List<SObject>();
        }

        queueMembers = groupMemberSelector.getGroupMembersByGroupIds(new List<Id>(leadOwnersFromQueue));
        for (Lead leadRecord : leadsWithOwnersIds) {
            for (GroupMember queueMember : queueMembers) {
                if (queueMember.GroupId == leadRecord.OwnerId && queueMember.UserOrGroupId == currentUserId) {
                    //Find out Lead's Journey which are having same Queue like Lead and change owner of that journey to current user.
                    for (Journey__c journeyIterator : leadsJourneys) {
                        if (journeyIterator.Primary_Lead__c == leadRecord.Id && journeyIterator.OwnerId == leadRecord.OwnerId) {
                            journeyIterator.OwnerId = currentUserId;
                            leadJourneysToUpdate.add(journeyIterator);
                        }
                    }
                    leadRecord.OwnerId = currentUserId;
                    leadsToUpdate.add(leadRecord);
                }
            }
        }

        List<SObject> recordsToUpdate = new List<SObject>();
        recordsToUpdate.addAll((List<SObject>) leadsToUpdate);
        recordsToUpdate.addAll((List<SObject>) leadJourneysToUpdate);
        return recordsToUpdate;
    }

    public List<SObject> getChangeTaskOwnerRecordsForJourneys(Set<Id> journeysIds) {
        if (journeysIds == null || journeysIds.isEmpty() || journeysWithUpdatedOwnersIds.containsAll(journeysIds)) {
            return new List<SObject>();
        }
        journeysIds.removeAll(journeysWithUpdatedOwnersIds);
        journeysWithUpdatedOwnersIds.addAll(journeysIds);
        //For Journey whatId
        Id currentUserId = UserInfo.getUserId();
        List<GroupMember> journeyQueueMembers = new List<GroupMember>();
        Set<Id> journeyOwnersFromQueue = new Set<Id>();
        List<Journey__c> journeysToUpdate = new List<Journey__c>();

        //Find out list of queues which are require.
        Set<Journey__c> journeysWithOwnerIds = new Set<Journey__c>(journeySelector.getJourneysWithAdditionalFieldsByIds(new List<Id>(journeysIds)));
        for (Journey__c journeyOwnerId : journeysWithOwnerIds) {
            if (OrganizationHelper.isGroup(journeyOwnerId.OwnerId)) {
                journeyOwnersFromQueue.add(journeyOwnerId.OwnerId);
            }
        }
        //Find out members of queue.
        if (journeyOwnersFromQueue != null && !journeyOwnersFromQueue.isEmpty()) {
            journeyQueueMembers = groupMemberSelector.getGroupMembersByGroupIds(new List<Id>(journeyOwnersFromQueue));
            for (Journey__c journeyIterator : journeysWithOwnerIds) {
                for (GroupMember queueMember : journeyQueueMembers) {
                    if (queueMember.GroupId == journeyIterator.OwnerId && queueMember.UserOrGroupId == currentUserId) {
                        journeyIterator.OwnerId = currentUserId;
                        journeysToUpdate.add(journeyIterator);
                    }
                }
            }
        }
        return journeysToUpdate;
    }*/

    public void updateJourneyNMDNextContactDate() {
        updateRecords(getJourneyToUpdateNMDNextContactDate(newTasks));
    }

    public List<Journey__c> getJourneyToUpdateNMDNextContactDate(List<Task> newTasks) {
        Sales_Console_Setting__mdt journeySettings = SalesConsoleSettings.get('JourneySettings');

        if (journeySettings == null) {
            return new List<Journey__c>();
        }

        List<NMDNextDateClass> nmdNextDates;
        Map<String, Integer> callResultsByDays = new Map<String, Integer>();
        Map<Id, String> journeysToCallResults = new Map<Id, String>();
        nmdNextDates = (List<NMDNextDateClass>) JSON.deserialize(journeySettings.Data__c, List<NMDNextDateClass>.class);
        for (NMDNextDateClass currentNMDJson : nmdNextDates) {
            callResultsByDays.put(currentNMDJson.CallResult.toLowerCase(), currentNMDJson.NextDate);
        }

        if (callResultsByDays == null) {
            return new List<Journey__c>();
        }

        for (Task taskRecord : newTasks) {
            if (taskRecord.Status == GlobalConstants.TASK_STATUS_COMPLETED
                && String.isNotBlank(taskRecord.WhatId)
                && OrganizationHelper.isJourney(taskRecord.WhatId)
                && String.isNotBlank(taskRecord.CallDisposition) && callResultsByDays.containsKey(taskRecord.CallDisposition.toLowerCase())) {
                journeysToCallResults.put(taskRecord.WhatId, taskRecord.CallDisposition.toLowerCase());
                taskRecord.ActivityDate = DateUtilities.addBusinessDays(Date.today(), callResultsByDays.get(taskRecord.CallDisposition.toLowerCase()));
            }
        }

        Map<Id, Journey__c> journeysToUpdateByIds = new Map<Id, Journey__c>();//here map is used to prevent 'Duplicate id in List' exception.
        if (journeysToCallResults != null && !journeysToCallResults.isEmpty()) {
            Map<Id, String> journeysPrimaryContactsByJourneys = new Map<Id, String>();
            //Select Id, Name, Primary_Contact__c, NMD_Next_Contact_Date__c
            for (Journey__c journey : journeySelector.getJourneysWithAdditionalFieldsByIds(new List<Id>(journeysToCallResults.keySet()))) {
                if (journeysToCallResults.containsKey(journey.Id) && callResultsByDays.containsKey(journeysToCallResults.get(journey.Id).toLowerCase())) {
                    Integer daysToAdd = callResultsByDays.get(journeysToCallResults.get(journey.Id).toLowerCase());
                    journey.NMD_Next_Contact_Date__c = DateUtilities.addBusinessDays(Date.today(), daysToAdd);
                    journeysToUpdateByIds.put(journey.Id, journey);
                    if (journey.Primary_Contact__c != null) {
                        journeysPrimaryContactsByJourneys.put(journey.Id, journey.Primary_Contact__c);
                    }
                }
            }

            if (journeysPrimaryContactsByJourneys.size() > 0) {
                for (Task taskRecord : newTasks) {
                    if (String.isNotBlank(taskRecord.WhatId) && journeysPrimaryContactsByJourneys.containsKey(taskRecord.WhatId)) {
                        taskRecord.WhoId = journeysPrimaryContactsByJourneys.get(taskRecord.WhatId);
                    }
                }
            }
        }

        for (Task taskRecord : newTasks) {
            if (String.isNotBlank(taskRecord.WhatId)
                && OrganizationHelper.isJourney(taskRecord.WhatId)
                && taskRecord.ActivityDate < Date.today()
                && taskRecord.Status != GlobalConstants.TASK_STATUS_COMPLETED) {
                taskRecord.Status = GlobalConstants.TASK_STATUS_COMPLETED;
            }
        }

        return journeysToUpdateByIds.values();
    }

    public void updateRecords(List<SObject> records) {
        if (records == null || records.isEmpty()) {
            return;
        }
        update records;
    }

    public void insertRecords(List<SObject> records) {
        if (records == null || records.isEmpty()) {
            return;
        }
        insert records;
    }

    public void updateActiveReferrer() {
        Set<String> emails = new Set<String>();
        Set<Id> leadIds = new Set<Id>();
        Set<Id> contactIds = new Set<Id>();

        for (Task taskRecord : newTasks) {
            if (String.isNotBlank(taskRecord.WhoId)) {
                if (OrganizationHelper.isLead(taskRecord.WhoId)) {
                    leadIds.add(taskRecord.WhoId);
                } else if (OrganizationHelper.isContact(taskRecord.WhoId)) {
                    contactIds.add(taskRecord.WhoId);
                }
            }
        }

        Map<Id, Contact> contactsByIds = new Map<Id, Contact>();
        Map<Id, Lead> leadsByIds = new Map<Id, Lead>();
        if (contactIds != null && !contactIds.isEmpty()) {
            contactsByIds = new Map<Id, Contact>(contactSelector.getContactsByIdAndNotNullEmail(new List<Id>(contactIds)));
            for (Contact contactRecord : contactsByIds.values()) {
                if (String.isNotBlank(contactRecord.Email)) {
                    emails.add(contactRecord.Email.toLowerCase());
                }
            }
        }

        if (leadIds != null && !leadIds.isEmpty()) {
            leadsByIds = new Map<Id, Lead>(leadSelector.getLeadsByIdAndNotNullEmail(new List<Id>(leadIds)));
            for (Lead leadRecord : leadsByIds.values()) {
                if (String.isNotBlank(leadRecord.Email)) {
                    emails.add(leadRecord.Email.toLowerCase());
                }
            }
        }

        if (emails == null || emails.isEmpty()) {
            return;
        }
        Map<String, Id> mapActiveReferences = ReferenceHandler.getActiveReference(emails);
        //commented as a part of Q2C Org Consolidation
        /*for (Task taskRecord : newTasks) {
            if (String.isNotBlank(taskRecord.WhoId)) {
                if (OrganizationHelper.isLead(taskRecord.WhoId) && String.isNotBlank(leadsByIds.get(taskRecord.WhoId)?.Email)) {
                    //taskRecord.Referrer__c = mapActiveReferences.get(leadsByIds.get(taskRecord.WhoId).Email.toLowerCase());
                } else if (OrganizationHelper.isContact(taskRecord.WhoId) && String.isNotBlank(contactsByIds.get(taskRecord.WhoId)?.Email)) {
                   // taskRecord.Referrer__c = mapActiveReferences.get(contactsByIds.get(taskRecord.WhoId).Email.toLowerCase());
                }
            }
        }*/
    }

    public void updateOutreachStageOnJourney() {
        JourneysAndTasksWrapper journeysAndTasks = getJourneysAndTasksForOutreachStageUpdate(newTasks, oldTasksMap);
        updateRecords(journeysAndTasks.journeys);
        insertRecords(journeysAndTasks.tasks);
    }

    public JourneysAndTasksWrapper getJourneysAndTasksForOutreachStageUpdate(List<Task> newTasks, Map<Id, Task> oldTasksMap) {
        Set<Id> relatedJourneysIds = new Set<Id>();
        Set<Id> relatedPrimaryContacts = new Set<Id>();
        Set<Id> relatedPrimaryLeads = new Set<Id>();
        Map<Id, Journey__c> journeysToBeProcessedByIds = new Map<Id, Journey__c>();
        List<Task> tasksToBeProcessed = new List<Task>();

        for (Task taskRecord : newTasks) {
            if (String.isBlank(taskRecord.Subject)) {
                taskRecord.Subject = 'FastCall Outbound Call';
            }
            if ((this.context == TriggerContext.BEFORE_INSERT || oldTasksMap.get(taskRecord.Id).get('Subject') == 'fc_EmptySubject')
                 && (String.isNotBlank(taskRecord.WhatId) && String.isNotBlank(taskRecord.Subject)
                 && String.valueOf(taskRecord.Subject).equalsIgnoreCase('FastCall Outbound Call')
                 && OrganizationHelper.isJourney(taskRecord.WhatId)))  {
                relatedJourneysIds.add(taskRecord.WhatId);
            }
        }
        if (relatedJourneysIds == null || relatedJourneysIds.isEmpty()) {
            return new JourneysAndTasksWrapper(null, null);
        }

        Map<Id, Journey__c> relatedJourneysByIds =
                new Map<Id, Journey__c>(journeySelector.getJourneysByStatusAndIds(
                        GlobalConstants.JOURNEY_STATUS_KNOWN,
                        new List<Id>(relatedJourneysIds)));
        for (Journey__c journey : relatedJourneysByIds.values()) {
            if (journey.Primary_Lead__c != null) {
                relatedPrimaryLeads.add(journey.Primary_Lead__c);
            }
            if (journey.Primary_Contact__c != null) {
                relatedPrimaryContacts.add(journey.Primary_Contact__c);
            }
        }
        if (relatedPrimaryContacts.isEmpty() && relatedPrimaryLeads.isEmpty()) {
            return new JourneysAndTasksWrapper(null, null);
        }

        List<Journey__c> knownJourneys =
                new List<Journey__c>(journeySelector.getJourneysByStatusAndContactAndLeadIds(
                        GlobalConstants.JOURNEY_STATUS_KNOWN,
                        new List<Id>(relatedPrimaryContacts),
                        new List<Id>(relatedPrimaryLeads)));
        Map<Id, List<Journey__c>> journeysByContactAndLeadIds = new Map<Id, List<Journey__c>>();
        for (Journey__c journey : knownJourneys) {
            if (journey.Primary_Contact__c != null) {
                if (journeysByContactAndLeadIds.containsKey(journey.Primary_Contact__c)) {
                    List<Journey__c> contactsJourneys = journeysByContactAndLeadIds.get(journey.Primary_Contact__c);
                    contactsJourneys.add(journey);
                    journeysByContactAndLeadIds.put(journey.Primary_Contact__c, contactsJourneys);
                } else {
                    journeysByContactAndLeadIds.put(journey.Primary_Contact__c, new List<Journey__c>{
                            journey
                    });
                }
            }
            if (journey.Primary_Lead__c != null) {
                if (journeysByContactAndLeadIds.containsKey(journey.Primary_Lead__c)) {
                    List<Journey__c> leadsJourneys = journeysByContactAndLeadIds.get(journey.Primary_Lead__c);
                    leadsJourneys.add(journey);
                    journeysByContactAndLeadIds.put(journey.Primary_Lead__c, leadsJourneys);
                } else {
                    journeysByContactAndLeadIds.put(journey.Primary_Lead__c, new List<Journey__c>{
                            journey
                    });
                }
            }
        }

        if (relatedJourneysIds.isEmpty() || journeysByContactAndLeadIds.isEmpty()) {
            return new JourneysAndTasksWrapper(null, null);
        }

        for (Task taskRecord : newTasks) {
            if (String.isEmpty(taskRecord.Subject)) {
                taskRecord.Subject = 'FastCall Outbound Call';
            }
            if (String.isNotBlank(taskRecord.Subject) && taskRecord.Subject.equalsIgnoreCase('FastCall Outbound Call')
                && (relatedJourneysByIds.get(taskRecord.WhatId).Outreach_Stage__c == 'Call 1' || (relatedJourneysByIds.get(taskRecord.WhatId).Outreach_Stage__c == '') || (relatedJourneysByIds.get(taskRecord.WhatId).Outreach_Stage__c == null))
                && relatedJourneysByIds.get(taskRecord.WhatId).Status__c == GlobalConstants.JOURNEY_STATUS_KNOWN) {
                List<Journey__c> journeys = new List<Journey__c>();

                if ((relatedJourneysByIds.get(taskRecord.WhatId)).Primary_Contact__c != null) {
                    journeys = journeysByContactAndLeadIds.get((relatedJourneysByIds.get(taskRecord.WhatId)).Primary_Contact__c);
                }
                if ((relatedJourneysByIds.get(taskRecord.WhatId)).Primary_Lead__c != null) {
                    journeys = journeysByContactAndLeadIds.get((relatedJourneysByIds.get(taskRecord.WhatId)).Primary_Lead__c);
                }
                if (journeys == null || journeys.isEmpty()) {
                    continue;
                }
                for (Journey__c journey : journeys) {
                    Task taskForOutreachJourney = new Task();
                    taskForOutreachJourney.Type = GlobalConstants.TASK_TYPE_CALL;
                    taskForOutreachJourney.TaskSubtype = GlobalConstants.TASK_TYPE_CALL;
                    taskForOutreachJourney.Status = GlobalConstants.TASK_STATUS_COMPLETED;
                    taskForOutreachJourney.Priority = 'Normal';
                    taskForOutreachJourney.whatId = journey.Id;
                    taskForOutreachJourney.WhoId = journey.Primary_Contact__c;
                    if (journey.Outreach_Stage__c == 'Call 1' && relatedJourneysByIds.get(taskRecord.WhatId).Outreach_Stage__c == journey.Outreach_Stage__c) {
                        journey.Outreach_Stage__c = 'Call 2';
                        taskForOutreachJourney.Subject = 'Log A Call :' + journey.Outreach_Stage__c;
                        tasksToBeProcessed.add(taskForOutreachJourney);
                        journeysToBeProcessedByIds.put(journey.Id, journey);
                    } else if ((journey.Outreach_Stage__c == '' || journey.Outreach_Stage__c == null)
                               && relatedJourneysByIds.get(taskRecord.WhatId).Outreach_Stage__c == journey.Outreach_Stage__c) {
                        journey.Outreach_Stage__c = 'Call 1';
                        taskForOutreachJourney.Subject = 'Log A Call :' + journey.Outreach_Stage__c;
                        tasksToBeProcessed.add(taskForOutreachJourney);
                        journeysToBeProcessedByIds.put(journey.Id, journey);
                    }
                }

            }
        }
        return new JourneysAndTasksWrapper(journeysToBeProcessedByIds.values(), tasksToBeProcessed);
    }

    private void updateContactOnTask() {
        updateRecords(getRecordsToUpdateContactOnTask(newTasks, oldTasksMap));
    }

    @TestVisible
    private List<Task> getRecordsToUpdateContactOnTask(List<Task> newTasks, Map<Id, Task> oldTasksMap) {
        Set<Id> tasksIds = new Set<Id>();
        Set<String> contactsUUIds = new Set<String>();
        Map<Id, Task> triggerOldMap = oldTasksMap;
        Map<Id, Task> triggerNewMap;
        Map<String, Contact> relatedContactsByUUIDs = new Map<String, Contact>();
        for (Task task : newTasks) {
            tasksIds.add(task.Id);
        }
        if(tasksWithUpdatedContactsIds == null) {
            tasksWithUpdatedContactsIds = new Set<Id>();
        }
        tasksIds.removeAll(tasksWithUpdatedContactsIds);
        //This query is used becuase the trigger is after insert/update context and Saleslady_Contact_UUID__c and Salesforce_Contact__c getting null.
        if (tasksIds.isEmpty()) {
            return new List<Task>();
        }
        triggerNewMap = new Map<Id, Task>(taskSelector.getTasksWithAdditionalFieldsByIds(new List<Id>(tasksIds)));
        if (triggerNewMap.isEmpty()) {
            return new List<Task>();
        }

        for (Task task : triggerNewMap.values()) {
            if (task.Saleslady_Contact_UUID__c != null) {
                if (this.context == TriggerContext.AFTER_INSERT) {
                    contactsUUIds.add(task.Saleslady_Contact_UUID__c);
                } else if (task.Saleslady_Contact_UUID__c != triggerOldMap.get(task.Id).Saleslady_Contact_UUID__c) {
                    contactsUUIds.add(task.Saleslady_Contact_UUID__c);
                    tasksWithUpdatedContactsIds.add(task.Id);
                }
            }
        }
        if (!contactsUUIds.isEmpty()) {
            for (Contact contactRecord : contactSelector.getContactsByUUIDs(new List<String>(contactsUUIds))) {
                relatedContactsByUUIDs.put(contactRecord.UUID__c, contactRecord);
            }
        }
        Map<Id, Task> tasksToUpdateByIds = new Map<Id, Task>();
        for (Task taskRecord : triggerNewMap.values()) {
            if (this.context == TriggerContext.AFTER_INSERT) {
                if (relatedContactsByUUIDs != null && relatedContactsByUUIDs.containsKey(taskRecord.Saleslady_Contact_UUID__c)) {
                    taskRecord.Salesforce_Contact__c = relatedContactsByUUIDs.get(taskRecord.Saleslady_Contact_UUID__c).Id + ' '
                                                       + relatedContactsByUUIDs.get(taskRecord.Saleslady_Contact_UUID__c).Name;
                } else {
                    taskRecord.Salesforce_Contact__c = '';
                }
                tasksToUpdateByIds.put(taskRecord.Id, taskRecord);
            } else {
                if (taskRecord.Saleslady_Contact_UUID__c != null && taskRecord.Saleslady_Contact_UUID__c != triggerOldMap.get(taskRecord.Id).Saleslady_Contact_UUID__c) {
                    if (!relatedContactsByUUIDs.isEmpty() && relatedContactsByUUIDs.containsKey(taskRecord.Saleslady_Contact_UUID__c)) {
                        taskRecord.Salesforce_Contact__c = relatedContactsByUUIDs.get(taskRecord.Saleslady_Contact_UUID__c).Id + ' ' + relatedContactsByUUIDs.get(taskRecord.Saleslady_Contact_UUID__c).Name;
                    } else {
                        taskRecord.Salesforce_Contact__c = '';
                    }
                    tasksToUpdateByIds.put(taskRecord.Id, taskRecord);
                } else if (String.isBlank(taskRecord.Saleslady_Contact_UUID__c) && taskRecord.Saleslady_Contact_UUID__c != triggerOldMap.get(taskRecord.Id).Saleslady_Contact_UUID__c) {
                    taskRecord.Salesforce_Contact__c = '';
                    tasksToUpdateByIds.put(taskRecord.Id, taskRecord);
                }
            }
        }

        return tasksToUpdateByIds.values();
    }

    @TestVisible
    private void updateTaskFieldsForNVMCalls() {
        for (Task taskRecord : newTasks) {
            if (taskRecord.Vonage_Call_Disposition__c != null
                && (this.context == TriggerContext.BEFORE_INSERT || TriggerUtility.isFieldValueChanged(taskRecord,  oldTasksMap.get(taskRecord.Id), 'Vonage_Call_Disposition__c'))) {
                taskRecord.CallDisposition = taskRecord.Vonage_Call_Disposition__c;
            }
        }
    }

    private void updateTaskTypeOnInsert(){
        for(Task taskRecord : newTasks){
            updateTaskType(taskRecord);
        }
    }

    private void updateTaskType(Task taskRecord) {
        if (String.isNotBlank(taskRecord.Type)) {
            taskRecord.Activity_Type_2__c = taskRecord.Type;
            return;
        }
        String taskSubject = taskRecord.Subject.toUpperCase();
        if (taskSubject.contains('EMAIL')) {
            taskRecord.Type = 'Email';
        } else if (taskSubject.contains('COLD CALL')) {
            taskRecord.Type = 'Cold Call';
        } else if (taskSubject.contains(GlobalConstants.TASK_TYPE_CALL.toUpperCase())) {
            taskRecord.Type = GlobalConstants.TASK_TYPE_CALL;
        } else if (taskSubject.contains('MEETING')) {
            taskRecord.Type = 'Meeting';
        } else if (taskSubject.contains('SITE VISIT')) {
            taskRecord.Type = 'Site Visit';
        } else if (taskSubject.contains('QUOTE')) {
            taskRecord.Type = 'Send Letter/Quote';
        } else {
            taskRecord.Type = 'Other';
        }
        taskRecord.Activity_Type_2__c = taskRecord.Type;
    }
    private void updateTaskTypeOnUpdate() {
        for (Task taskRecord : newTasks) {
            if (taskRecord.Subject != oldTasksMap.get(taskRecord.Id).Subject) {
                updateTaskType(taskRecord);
            }
        }
    }

    public class NMDNextDateClass {
        public String CallResult { get; set; }
        public Integer NextDate { get; set; }
    }

    public class JourneysAndTasksWrapper {
        public List<Journey__c> journeys;
        public List<Task> tasks;

        public JourneysAndTasksWrapper(List<Journey__c> journeys, List<Task> tasks) {
            this.journeys = journeys;
            this.tasks = tasks;
        }
    }
}