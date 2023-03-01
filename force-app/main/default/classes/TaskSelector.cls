/*************************************************************************************************************************************
    Author      :   Pawel Biszczak
    Description :   This class is selector implementation of particular SObject (Task__c)
    --------------------------------------------------------------------------------------------------------------------------------------
    VERSION         DATE            AUTHOR              DETAIL
    1               18 Feb, 2021    Pawel Biszczak      Initial Deployment
**************************************************************************************************************************************/
public with sharing class TaskSelector extends SObjectSelector {
    private final String TASKS_FIELDS_METADATA = 'Task_Fields_Metadata';
    private static final List<String> DEFAULT_FIELDS = new List<String>{ 'Id',
                                                                         'Priority',
                                                                         'Status',
                                                                         'Subject',
                                                                         'Type' };
    private static final List<String> RELATED_OBJECTS_FIELDS = new List<String>{ 'WhoId',
                                                                                 'WhatId',
                                                                                 'OwnerId' };

    public TaskSelector() {
        super(Task.getSObjectType());
    }

    public override Set<String> getDefaultFields(){
        MetadataSetting__mdt metadataRecord = Settings.getMetadataSettingByDevName(TASKS_FIELDS_METADATA);
        if (String.isNotBlank(metadataRecord?.Data__c)) {
            return (Set<String>) (JSON.deserialize(metadataRecord.Data__c, Set<String>.class));
        } else {
            return new Set<String> (DEFAULT_FIELDS);
        }
    }

    public List<Task> getTasks(){
        return (List<Task>) getSObjectsWithoutFilters(DEFAULT_FIELDS);
    }

    public List<Task> getTasksWithRelatedObjectsFields(){
        List<String> fields = new List<String>(DEFAULT_FIELDS);
        fields.addAll(RELATED_OBJECTS_FIELDS);
        return (List<Task>) getSObjectsWithoutFilters(fields);
    }

    public List<Task> getTasksWithAdditionalFields(){
        List<String> fields = new List<String>{ 'ActivityDate',
                                                'CallDisposition',
                                                'CreatedDate',
                                                'Salesforce_Contact__c',
                                                'Saleslady_Contact_UUID__c',
                                                'Vonage_Call_Disposition__c',
                                                'TaskSubtype' };
        fields.addAll(DEFAULT_FIELDS);
        fields.addAll(RELATED_OBJECTS_FIELDS);
        return (List<Task>) getSObjectsWithoutFilters(fields);
    }

    public List<Task> getTasksWithAdditionalFieldsByIds(List<Id> ids){
        if (ids == null || ids.isEmpty()) {
            return null;
        }

        List<String> fields = new List<String>{ 'ActivityDate',
                'CallDisposition',
                'CreatedDate',
                'Salesforce_Contact__c',
                'Saleslady_Contact_UUID__c',
                'TaskSubtype' };
        fields.addAll(DEFAULT_FIELDS);
        fields.addAll(RELATED_OBJECTS_FIELDS);
        return (List<Task>) getSObjectByIds(fields, ids);
    }

    public List<Task> getTasksWithRelatedObjectsFieldsByWhoIds(List<Id> whoIds){
        if (whoIds == null || whoIds.isEmpty()) {
            return null;
        }

        List<String> fields = new List<String>(DEFAULT_FIELDS);
        fields.addAll(RELATED_OBJECTS_FIELDS);
        return (List<Task>) getSObjectByField(fields, 'WhoId', whoIds, false);
    }

    public List<Task> getTasksWithRelatedObjectsFieldsByWhoIdsLimited(List<Id> whoIds, Integer recordsLimit){
        if (whoIds == null || whoIds.isEmpty()) {
            return null;
        }

        List<String> fields = new List<String>(DEFAULT_FIELDS);
        fields.addAll(RELATED_OBJECTS_FIELDS);
        return (List<Task>) getSObjects(fields, 'WhoId', whoIds, false, recordsLimit);
    }

    public List<Task> getTasksWithRelatedObjectsFieldsByWhatIds(List<Id> whatIds){
        if (whatIds == null || whatIds.isEmpty()) {
            return null;
        }

        List<String> fields = new List<String>(DEFAULT_FIELDS);
        fields.addAll(RELATED_OBJECTS_FIELDS);
        return (List<Task>) getSObjectByField(fields, 'WhatId', whatIds, false);
    }

    public List<Task> getTasksWithRelatedObjectsFieldsByWhatIdsLimited(List<Id> whatIds, Integer recordsLimit){
        if (whatIds == null || whatIds.isEmpty()) {
            return null;
        }

        List<String> fields = new List<String>(DEFAULT_FIELDS);
        fields.addAll(RELATED_OBJECTS_FIELDS);
        return (List<Task>) getSObjects(fields, 'WhatId',  whatIds, false, recordsLimit);
    }

    public List<Task> getTasksWithRelatedObjectsFieldsByWhatIdsAndNoCompletedStatus(List<Id> whatIds){
        if (whatIds == null || whatIds.isEmpty()) {
            return null;
        }

        List<String> fields = new List<String>(DEFAULT_FIELDS);

        List<Object> bindings = new List<Object>{ whatIds, GlobalConstants.TASK_STATUS_COMPLETED };
        String whereClause = 'WhatId IN :whatIds AND Status != :statusForCompletedTasks';

        return (List<Task>) getSObjects(fields, whereClause, bindings);
    }

    public List<Task> getQuoteTasks(){
        List<String> fields = new List<String>(DEFAULT_FIELDS);

        String subjectForQuoteWithWildcards = '%' + GlobalConstants.TASK_SUBJECT_QUOTE + '%';
        List<Object> bindings = new List<Object>{ subjectForQuoteWithWildcards };
        String whereClause = 'Subject LIKE :subjectForQuoteWithWildcards AND Type != null';

        return (List<Task>) getSObjects(fields, whereClause, bindings);
    }

    public List<Task> getTasksWithRelatedObjectsFieldsForInactiveOwnersByLeadsEmails(Set<String> emails, Integer recordsLimit){
        if (emails == null || emails.isEmpty()) {
            return null;
        }

        List<String> fields = new List<String>(DEFAULT_FIELDS);
        fields.addAll(RELATED_OBJECTS_FIELDS);

        List<Object> bindings = new List<Object>{ emails };
        String whereClause = 'Owner.isActive = False AND WhoId IN (SELECT Id FROM Lead WHERE isConverted = False AND Email IN :emails)';

        return (List<Task>) getSObjects(fields, whereClause, bindings, recordsLimit);
    }

    public List<Task> getSalesInquiryTasksByWhatIds(List<Id> whatIds){
        if (whatIds == null || whatIds.isEmpty()) {
            return null;
        }

        List<String> fields = new List<String>{ 'Id',
                                                'Building__r.Email__c',
                                                'Building__r.Responsible_CM__r.Email',
                                                'Building__r.Leasing_Manager_Id__r.Email',
                                                'Building__r.Leasing_Director_Id__r.Email' };

        List<Object> bindings = new List<Object>{ whatIds, GlobalConstants.TASK_TYPE_SALES_INQUIRY };
        String whereClause = 'WhatId IN :whatIds AND Type = :typeForSalesInquiryTasks';

        return (List<Task>) getSObjects(fields, whereClause, bindings);
    }
}