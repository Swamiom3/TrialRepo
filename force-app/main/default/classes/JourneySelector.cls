/*************************************************************************************************************************************
    Author      :   Pawel Biszczak
    Description :   This class is selector implementation of particular SObject (Journey__c)
    --------------------------------------------------------------------------------------------------------------------------------------
    VERSION    DATE           AUTHOR            DETAIL
    1          9 Apr, 2021    Pawel Biszczak    Initial Deployment
**************************************************************************************************************************************/
public with sharing class JourneySelector extends SObjectSelector {
    private final String JOURNEY_FIELDS_METADATA = 'Journey_Fields_Metadata';
    private static final List<String> DEFAULT_FIELDS = new List<String>{ 'Id',
                                                                         'Name',
                                                                         'Primary_Contact__c',
                                                                         'Primary_Email__c',
                                                                         'Primary_Lead__c',
                                                                         'OwnerId',
                                                                         'Outreach_Stage__c',
                                                                         'Status__c' };

    public JourneySelector() {
        super(Journey__c.getSObjectType());
    }

    public override Set<String> getDefaultFields(){
        MetadataSetting__mdt metadataRecord = Settings.getMetadataSettingByDevName(JOURNEY_FIELDS_METADATA);
        if (String.isNotBlank(metadataRecord?.Data__c)) {
            return (Set<String>) (JSON.deserialize(metadataRecord.Data__c, Set<String>.class));
        } else {
            return new Set<String> (DEFAULT_FIELDS);
        }
    }

    public List<Journey__c> getJourneysWithAdditionalFieldsByIds(List<Id> ids){
        if (ids == null || ids.isEmpty()) {
            return null;
        }

        List<String> fields = new List<String>{ 'NMD_Next_Contact_Date__c', 'Lead_Id__c', 'Market__c', 'Portfolio_Interested_In__r.Name' };
        fields.addAll(DEFAULT_FIELDS);
        return (List<Journey__c>) getSObjectByIds(fields, ids);
    }

    public List<Journey__c> getJourneysByLeadsIds(List<Id> leadsIds){
        if (leadsIds == null || leadsIds.isEmpty()) {
            return null;
        }

        List<String> fields = new List<String>(DEFAULT_FIELDS);
        return (List<Journey__c>) getSObjectByField(fields, 'Primary_Lead__c', leadsIds, false);
    }

    public List<Journey__c> getJourneysByStatusAndIds(String statusForJourney, List<Id> ids){
        if (ids == null || ids.isEmpty()) {
            return null;
        }

        List<String> fields = new List<String>(DEFAULT_FIELDS);
        List<Object> bindings = new List<Object>{ statusForJourney, ids };
        String whereClause = 'Status__c = :statusForJourney AND Id IN :ids';

        return (List<Journey__c>) getSObjects(fields, whereClause, bindings);
    }

    public List<Journey__c> getJourneysByStatusAndContactAndLeadIds(String statusForJourney, List<Id> contactIds, List<Id> leadIds){
        if ((contactIds == null || contactIds.isEmpty()) && (leadIds == null || leadIds.isEmpty())) {
            return null;
        }
        if(contactIds == null) {
            contactIds = new List<Id>();
        }
        if(leadIds == null) {
            leadIds = new List<Id>();
        }

        List<String> fields = new List<String>(DEFAULT_FIELDS);
        List<Object> bindings = new List<Object>{ statusForJourney, contactIds, leadIds };
        String whereClause = 'Status__c = :statusForJourney AND (Primary_Contact__c IN :contactIds OR Primary_Lead__c IN :leadIds)';

        return (List<Journey__c>) getSObjects(fields, whereClause, bindings);
    }
    
    public List<Journey__c> getJourneysByPrimaryEmailsWhenPrimaryLeadPresented(List<String> primaryEmails){
        if (primaryEmails == null || primaryEmails.isEmpty()) {
            return new List<Journey__c>();
        }

        List<String> fields = new List<String>(DEFAULT_FIELDS);
        List<Object> bindings = new List<Object>{ primaryEmails };
        String whereClause = 'Primary_Email__c IN :primaryEmails AND Primary_Lead__c != null';

        return (List<Journey__c>) getSObjects(fields, whereClause, bindings);
    }
    
    public List<Journey__c> getAcceptedJourneysMatchingParentIds(String statusForJourney, List<Id> combineIds){
        if (combineIds == null || combineIds.isEmpty()) {
            return new List<Journey__c>();
        }
        List<String> fields = new List<String>(DEFAULT_FIELDS);
        List<Object> bindings = new List<Object>{ statusForJourney, combineIds, combineIds, combineIds };
        String whereClause = 'Status__c = :statusForJourney AND (Id IN :combineIds OR Primary_Contact__c IN :combineIds OR Primary_Lead__c IN :combineIds)';
        return (List<Journey__c>) getSObjects(fields, whereClause, bindings);
    }
    
    
    
    public List<Journey__c> getJourneysByIdsWithLeadOrContactPresent(List<Id> journeyIds){
        if (journeyIds == null || journeyIds.isEmpty()) {
            return new List<Journey__c>();
        }
        
        List<String> fields = new List<String>{ 'NMD_Next_Contact_Date__c', 'CreatedDate' };
        fields.addAll(DEFAULT_FIELDS);
        List<Object> bindings = new List<Object>{ journeyIds };
        String whereClause = 'Id IN :journeyIds AND (Primary_Lead__c != null OR Primary_Contact__c != null)';
            
        return (List<Journey__c>) getSObjects(fields, whereClause, bindings);
    }
    
    public List<Journey__c> getJourneysByLeadOrContactPresent(List<Id> leadOrContact){
        if (leadOrContact == null || leadOrContact.isEmpty()) {
            return new List<Journey__c>();
        }
        
        List<String> fields = new List<String>{ 'CampaignId__c' , 'Primary_Lead__c' , 'Primary_Contact__c' };
        List<Object> bindings = new List<Object>{ leadOrContact , leadOrContact };
        String whereClause = 'Primary_Lead__c IN :leadOrContact OR Primary_Contact__c IN :leadOrContact';
            
        return (List<Journey__c>) getSObjects(fields, whereClause, bindings);
    }

    public List<Journey__c> getOpenJourneysByPrimaryContact(Id contactId, List<String> journeyCloseStages){
        if (contactId == null && (journeyCloseStages == null || journeyCloseStages.isEmpty())) {
            return new List<Journey__c>();
        }

        List<String> fields = new List<String>{ 'Building_Interested_In__c',
                                                'Product_Interests__c',
                                                'Interested_in_Number_of_Desks__c',
                                                'Locale__c',
                                                'Description__c' };
        fields.addAll(DEFAULT_FIELDS);
        List<Object> bindings = new List<Object>{ contactId , journeyCloseStages };
        String whereClause = 'Primary_Contact__c = :contactId AND Status__c NOT IN :journeyCloseStages';
        String orderByClause = 'LastModifiedDate DESC';
        return (List<Journey__c>) getSObjects(fields, whereClause, bindings, orderByClause);
    }

    public List<Journey__c> getDuplicateJourneysCreatedToday(List<String> emails, List<String> firstNames, List<String> lastNames){
        if ((emails == null || emails.isEmpty()) && (firstNames == null || firstNames.isEmpty()) && (lastNames == null || lastNames.isEmpty())) {
            return new List<Journey__c>();
        }

        List<String> fields = new List<String>{ 'First_Name__c' , 'Last_Name__c' };
        fields.addAll(DEFAULT_FIELDS);
        List<Object> bindings = new List<Object>{ emails , firstNames , lastNames };
        String whereClause = 'Primary_Email__c IN :emails AND CreatedDate = TODAY AND First_Name__c IN :firstNames AND Last_Name__c IN :lastNames AND Duplicate_Journey__c = FALSE';
        return (List<Journey__c>) getSObjects(fields, whereClause, bindings);
    }

    public List<Journey__c> getJourneysByLeadAndStatus(String leadId, List<String> status){
        if (leadId == null && (status == null || status.isEmpty())) {
            return new List<Journey__c>();
        }

        List<String> fields = new List<String>(DEFAULT_FIELDS);
        List<Object> bindings = new List<Object>{ leadId , status };
        String whereClause = 'Primary_Lead__c =:leadId AND Status__c NOT IN :status';
        return (List<Journey__c>) getSObjects(fields, whereClause, bindings);
    } 

    public List<sObject> getOpenJourneysByLeadOrContact( List<Id> id, List<String> listOfJourneyCloseStages){
        if ((id == null || id.isEmpty()) && (listOfJourneyCloseStages == null || listOfJourneyCloseStages.isEmpty())) {
            return new List<sObject>();
        }

        List<String> fields = new List<String>{'Primary_Lead__c','Primary_Contact__c','Count(Id)'};
        List<Object> bindings = new List<Object>{ id , id , listOfJourneyCloseStages };
        String whereClause = '(Primary_Lead__c IN :id OR Primary_Contact__c IN :id ) AND Status__c NOT IN :setOfJourneyCloseStages';
        String groupByClause = 'Primary_Lead__c, Primary_Contact__c';
        return (List<sObject>) getSObjectsByGroup(fields, whereClause, bindings, groupByClause);
    }

    public List<Journey__c> getJourneysByIds(List<String> customFields, List<Id> journeyIds){
        if(journeyIds == null || journeyIds.isEmpty()){
            return new List<Journey__c>();
        }

        List<String> fields = new List<String>(customFields);
        List<Object> bindings = new List<Object>{ journeyIds };
        String whereClause = 'Id =: journeyIds';
        return (List<Journey__c>) getSObjects(fields, whereClause, bindings);
    }

    public List<Journey__c> getJourneyByCreatedDateAndLeadId(List<String> customFields, Id opportunityId){
        if(opportunityId == null ){
            return new List<Journey__c>();
        }

        List<String> fields = new List<String>(customFields);
        Date createdDate = System.Today().addDays(-365);
        List<Object> bindings = new List<Object>{createdDate , opportunityId };
        String whereClause = 'CreatedDate >=:createdDate AND Lead_Id__c =: opportunityId';
        return (List<Journey__c>) getSObjects(fields, whereClause, bindings);
    }

    public List<Journey__c> getJourneysByLead(List<String> customFields, List<Lead> leads){
        if(leads == null || leads.isEmpty()){
            return new List<Journey__c>();
        }

        List<String> fields = new List<String>(customFields);
        List<Object> bindings = new List<Object>{ leads };
        String whereClause = 'Primary_Lead__c IN : leads';
        return (List<Journey__c>) getSObjects(fields, whereClause, bindings);
    }

    public List<Journey__c> getJourneysCreatedTodayByLeadIds(List<String> customFields, List<Id> ids){
        if(ids == null || ids.isEmpty()){
            return new List<Journey__c>();
        }

        List<String> fields = new List<String>(customFields);
        List<Object> bindings = new List<Object>{ ids };
        String whereClause = 'Lead_Id__c IN :ids AND CreatedDate = TODAY';
        return (List<Journey__c>) getSObjects(fields, whereClause, bindings);
    }

    public List<Journey__c> getJourneysByEmailWithOrderByCreatedDate( List<String> customFields, List<String> email){
        if (email == null || email.isEmpty()) {
            return new List<Journey__c>();
        }

        List<String> fields = new List<String>(customFields);
        List<Object> bindings = new List<Object>{ email };
        String whereClause = 'Primary_Email__c = :email';
        String orderByClause = 'CreatedDate DESC';
        return (List<Journey__c>) getSObjects(fields, whereClause, bindings, orderByClause);
    }

    public String getQueryWithIdAndLeadAndContact(){
        List<String> fields = new List<String>{ 'Id', 'Primary_Lead__c', 'Primary_Contact__c', 'Primary_Lead__r.LeadSource', 'Primary_Lead__r.Referrer__c', 'Primary_Contact__r.LeadSource', 'Primary_Contact__r.Referrer__c' };
        String whereClause = 'Id = :recordId AND ( (Primary_Lead__c != NULL AND Primary_Lead__r.LeadSource IN :setOfLeadSource  AND  Primary_Lead__r.Referrer__c = NULL) OR (Primary_Contact__c != NULL AND Primary_Contact__r.LeadSource IN :setOfLeadSource  AND  Primary_Contact__r.Referrer__c = NULL) )';
        return getQuery(fields, whereClause);
    }

    public String getJourneysWithMoreAdditionalFieldsByIds(){
        List<String> fields = new List<String>{ 'Building_Interested_In__c', 'Primary_Contact__r.Account.Number_of_Full_Time_Employees__c', 'Primary_Contact__r.Account.Interested_in_Number_of_Desks__c', 'Primary_Lead__r.Number_of_Full_Time_Employees__c',
                                                'Primary_Lead__r.Interested_in_Number_of_Desks__c', 'Primary_Lead__r.Referrer_Name__c', 'Primary_Lead__r.Referrer_Email__c', 'Primary_Contact__r.Referrer_Name__c', 'Primary_Contact__r.Referrer_Email__c' };
        fields.addAll(DEFAULT_FIELDS);
        String whereClause = 'Id=: sObjectId';
        return getQuery(fields, whereClause);
    }

    public String getJourneysByCreatedDateAndStatus(){
        List<String> fields = new List<String>{'Id', 'Primary_Contact__c', 'Primary_Lead__c', 'Status__c'};
        String whereClause = 'CreatedDate != LAST_N_DAYS:30 AND Status__c NOT IN (:GlobalConstants.JOURNEY_STATUS_CONVERTED, :GlobalConstants.JOURNEY_STATUS_DEFERRED)';
        
        return getQuery(fields, whereClause);
    }

    public String getQueryWithLeadOrContact(){
        List<String> fields = new List<String>{'Id', 'Name', 'NMD_Next_Contact_Date__c', 'Status__c', 'Primary_Phone__c', 'Referrer__c'};
        String whereClause = '(Primary_Lead__c = :recordId OR Primary_Contact__c = :recordId)';
        
        return getQuery(fields, whereClause);
    }

    public String getQueryWithId(Id id){
        List<String> fields = new List<String>{'Id', 'Status__c', 'Primary_Lead__c', 'Primary_Contact__c', 'Lead_Source__c', 'LeadSource_Sub_Type__c', 'Primary_Contact__r.Account.OwnerId', 'Primary_Contact__r.Account.Owner.Email'};
        String whereClause = 'Id=\''+ id +'\'';
        
        return getQuery(fields, whereClause);
    }

    public String getQueryWithJourneyId(){
        List<String> fields = new List<String>{'Id', 'Primary_Lead__c', 'Primary_Contact__c'};
        String whereClause = 'Id =: journeyId LIMIT 1';
        
        return getQuery(fields, whereClause);
    }

    public List<Journey__c> getJourneyWithTours(Set<Id> journeyIds, Set<String> closeStage) {
        List<String> fields = new List<String>{ 'Id', 'Name', 'Status__c'};
        String innerQuery = 'SELECT Id, AppointmentNumber, Status FROM Service_Appointments__r';
        String outerWhere = 'Id IN :journeyIds AND Status__c NOT IN :closeStage';
        return (List<Journey__c>) getSObjectsWithChilds(fields, innerQuery, outerWhere, new List<Object>{journeyIds, closeStage});
    }

    public List<Journey__c> getJourneysWithReferrer(Set<Id> journeyIds, String creationSource){
        if ((journeyIds == null || journeyIds.isEmpty())) {
            return null;
        }

        List<String> fields = new List<String>{'Id', 'Creation_Source__c', 'Referrer__c'};
        List<Object> bindings = new List<Object>{ journeyIds , creationSource };
        String whereClause = 'Id IN:journeyIds AND Creation_Source__c = :creationSource AND Referrer__c != null';

        return (List<Journey__c>) getSObjects(fields, whereClause, bindings);
    }
}