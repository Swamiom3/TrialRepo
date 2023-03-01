/*****************************************************************************************************************************
  1. The class has some Q2C comments
  
  /*****************************************************************************************************************************
    Author      :  Amol Darekar
    Description :  ---
    History     :  --
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION                 DATE                    AUTHOR                          DETAIL
    1                   05,July 2016            Amol Darekar                    Initial Developement
    2                   06 June 2018            Sunil Bhosale                   Code revamp.
    3                   26 Jan  2021            Maciej Miłosz                   Refactor, change trigger framework
******************************************************************************************************************************/
public class LeadTriggerHandler extends SObjectTriggerHandler {

    @TestVisible
    private List<Lead> newLeads;
    @TestVisible
    private List<Lead> oldLeads;
    @TestVisible
    private Map<Id, Lead> newLeadsMap;
    @TestVisible
    private Map<Id, Lead> oldLeadsMap;
    @TestVisible
    private static JourneySelector journeySelector = new JourneySelector();

    public LeadTriggerHandler(){
        this(
            (List<Lead>) Trigger.new,
            (List<Lead>) Trigger.old,
            (Map<Id, Lead>) Trigger.newMap,
            (Map<Id, Lead>) Trigger.oldMap
        );
    }

    @TestVisible
    private LeadTriggerHandler(List<Lead> newLeads, List<Lead> oldLeads, Map<Id, Lead> newLeadsMap, Map<Id, Lead> oldLeadsMap){
        this.newLeads = newLeads;
        this.oldLeads = oldLeads;
        this.newLeadsMap = newLeadsMap;
        this.oldLeadsMap = oldLeadsMap;
    }
    //Added By Jitesh Adwani for ST-3312
    //TODO investigate
    public static Journey__c objLatestModifiedJourney;
    public static Boolean isLeadDeletedFromMergeBatch = false;

    //TODO: investigate why it's static
    public static Map<Id, Lead> mapDuplicateDeleteLeads = new Map<Id, Lead>();
    public static Map<Id,Lead> mapLeadsEmailChanged = new Map<Id,Lead>();

    public override void beforeInsert(){
        updateActiveReferrerOnLead();
        updateBuildingInterestOnLead();
        validateEmptyEmailOrPhone();
        updateLeadSourceAndLeadSourceDetail();
        updateCleansedName();
        populateCurrentBuildingName();
        updateCleanUrl();
    }

    public override void beforeUpdate(){
        updateBuildingInterestOnLead();
        validateEmptyEmailOrPhone();
        setProcessingStageOnUpdate();
        updateCleansedName();
        populateOrganization();
        populateCurrentBuildingName();
        updateCleanUrl();
    }

    public override void afterInsert(){ 
        convertLeadsToJourneys();
    }

    public override void afterUpdate(){
        updateJourneyPrimaryContact();
        restartJourney();
        convertLeadsToJourneys();
    }

    public override void beforeDelete(){
        mapDuplicateDeleteLeads = oldLeadsMap.clone();
        if(!isLeadDeletedFromMergeBatch){
            validateLeadDeletionWithRelatedJourneys();
        }
    }

    //TODO check why it's used in RestartJourneyQueueable, and extract to service.
    public void restartJourney(Set<Id> restartJourneyLeadIds){
        if(restartJourneyLeadIds == null || restartJourneyLeadIds.isEmpty()){
            return;
        }
        new JourneyRestartService()
            .setDmlConsolidator(dml)
            .restartJourneyForLead(restartJourneyLeadIds);
    }
    
    @TestVisible
    public static List<SObject> prepareRecordsForUpsert(String query, Settings.FieldMappings leadToJourneyFieldMapping, Set<Id> restartJournetyLeadIds){
        List<SObject> leadsToUpdate = new List<SObject>();
        List<SObject> journeyToUpsert = new List<SObject>();
        for(Lead leadRecord : Database.Query(query)){
            if(leadRecord.Journeys__r == null || leadRecord.Journeys__r.isEmpty()){// No Started Journey is present on Lead
                journeyToUpsert.add(createJourneyForLead(leadRecord, leadToJourneyFieldMapping));
            }else{
                for(Journey__c journeyRec : leadRecord.Journeys__r){
                    journeyRec.NMD_Next_Contact_Date__c = Date.today();
                    journeyToUpsert.add(journeyRec);
                }
            }
            leadRecord.Restart_Journey__c = false;
            leadsToUpdate.add(leadRecord);
        }
        List<SObject> recordsForUpsert = new List<SObject>();
        recordsForUpsert.addAll(leadsToUpdate);
        recordsForUpsert.addAll(journeyToUpsert);
        return recordsForUpsert;
    }
    public static String generateQuery(List<Settings.MappedField> fieldMappings){
        String query = 'SELECT Name, LeadSource, OwnerId, SAPI_Submission_Id__c,';
        for(Settings.MappedField field : fieldMappings){
            if(!query.contains(field.fieldname)){
                query += field.fieldname + ',';
            }
        }
        query = query.removeEnd(',');
        query += ' , Building_Interested_In__r.City__c, (SELECT Id, NMD_Next_Contact_Date__c FROM Journeys__r';
        query += ' WHERE Status__c = \'Known\' ORDER BY LastModifiedDate DESC LIMIT 1) FROM Lead WHERE Id IN :restartJournetyLeadIds';
        return query;
    }

    public static Journey__c createJourneyForLead(Lead leadRecord, Settings.FieldMappings leadToJourneyFieldMapping){
        Journey__c journey = new Journey__c();
        journey.NMD_Next_Contact_Date__c = Date.today();
        journey.Primary_Lead__c = leadRecord.Id;
        journey.OwnerId = leadRecord.OwnerId;
        journey.Status__c = 'Known';
        /*if (leadRecord.SAPI_Submission_Id__c != null) {
            journey.SAPI_Submission_Id__c = leadRecord.SAPI_Submission_Id__c;
        }*/
        for(String strKey : leadToJourneyFieldMapping.mappings.keySet()){
            journey.put(strKey, leadRecord.get(leadToJourneyFieldMapping.mappings.get(strKey).fieldname));
        }
        if(lead.Building_Interested_In__c != null && String.isNotBlank(leadRecord.Building_Interested_In__r.City__c) ){
            journey.Name = journey.Name +'-'+leadRecord.Building_Interested_In__r.City__c ;
        }
        if(String.isNotBlank(leadRecord.LeadSource)){
            journey.Name = journey.Name +'-'+leadRecord.LeadSource;
        }
        return journey;
    }

    /*
    moved from workflow trigger.
    */
    @TestVisible
    private void populateCurrentBuildingName(){
        for(Lead newLead : newLeads){
            Lead oldLead = oldLeadsMap?.get(newLead.Id);
            setCurrentBuildingName(newLead, oldLead);
        }
    }
    @TestVisible
    private void setCurrentBuildingName(Lead newlead, Lead oldLead){
        Id buildingId = oldLead?.Building_Interested_In__c;
        if(String.isNotBlank(newlead.Email) && newlead.Building_Interested_In__c != null && 
           (buildingId == null || (newlead.Building_Interested_In__c != buildingId))){
            Building__c objBuilding = BuildingUtility.getBuildingById(newlead.Building_Interested_In__c);
            /*if(objBuilding != null){
                newlead.Building_Interested_Name__c = objBuilding.Name;
            }*/
        }
    }

    @TestVisible
    private void updateCleanUrl(){
        for(Lead newLead : newLeads){
            Lead oldLead = oldLeadsMap?.get(newLead.Id);
            setCleanUrl(newLead, oldLead);
        }
    }
    @TestVisible
    private void setCleanUrl(Lead newLead, Lead oldLead){
        String oldCleanUrl = oldLead?.Full_URL__c;
        if(String.isNotBlank(newLead.Full_URL__c)
           && (oldCleanUrl == null || (newLead.Full_URL__c != oldCleanUrl))){
            newLead.Clean_URL__c = newLead.Full_URL__c.contains('?') ? newLead.Full_URL__c.substringBefore('?') : newLead.Full_URL__c;
        }
    }
    @TestVisible
    private void updateBuildingInterestOnLead() {
        Set<String> buildingNames = new Set<String>();
        Set<Id> buildingIds = new Set<Id>();
        Set<Id> portfolioIds = new Set<Id>();
        validateLeads(buildingNames, buildingIds, portfolioIds);
        Map<String, Id> buildingNamesToIds = new Map<String, Id>();
        if(!buildingNames.isEmpty()) {
            buildingNamesToIds = prepareBuildingNamesToIdsMap(buildingNames);        
        }
        Map<Id, Market__c> portfolios;
        if(!buildingIds.isEmpty()) {
            BuildingUtility.getBuildingsByIds(buildingIds);    
        } else if(!portfolioIds.isEmpty()) {
            portfolios = new Map<Id, Market__c>([SELECT Id, Territory__c FROM Market__c WHERE Id IN :portfolioIds]);  
        }     
        setBuildingInfoOnLeads(buildingNamesToIds, portfolios);
    }
    @TestVisible
    private void validateLeads(Set<String> buildingNames, Set<Id> buildingIds, Set<Id> portfolioIds) {
        for(Lead leadRec : newLeads) {
            if(leadRec.Locations_Interested__c != null) {
                buildingNames.add(leadRec.Locations_Interested__c.split(';')[0]);
            }
            if(leadRec.Building_Interested_In__c != null && (oldLeadsMap == null || TriggerUtility.isFieldValueChanged(leadRec, oldLeadsMap.get(leadRec.Id), 'Building_Interested_In__c'))) {
                buildingIds.add(leadRec.Building_Interested_In__c);
            } else if(leadRec.Portfolio_Interested_In__c != null && (oldLeadsMap == null || TriggerUtility.isFieldValueChanged(leadRec, oldLeadsMap.get(leadRec.Id), 'Portfolio_Interested_In__c'))) {
                portfolioIds.add(leadRec.Portfolio_Interested_In__c);   
            }
        }
    }
    @TestVisible
    private Map<String, Id> prepareBuildingNamesToIdsMap(Set<String> buildingNames) {
        Map<String, Id> buildingNamesToIds = new Map<String, Id>();
        for(Building__c building : new BuildingSelector().getBuildingsByName(new List<String>(buildingNames))) {
            buildingNamesToIds.put(building.Name, building.Id);
        }
        return buildingNamesToIds;
    }
    @TestVisible
    private void setBuildingInfoOnLeads(Map<String, Id> buildingNamesToIds, Map<Id, Market__c> portfolios) {
        for(Lead leadRecord : newLeads) {
            if(leadRecord.Locations_Interested__c != null) {
                String buildingName = leadRecord.Locations_Interested__c.split(';')[0];
                populateLeadByBuildingInterest(leadRecord, BuildingUtility.getBuildingById(buildingNamesToIds.get(buildingName)));
            }
            Building__c buildingRecord = BuildingUtility.getBuildingById(leadRecord.Building_Interested_In__c);
            if(buildingRecord != null) {
                populateLeadByBuildingInterest(leadRecord, buildingRecord);
            } else if(portfolios?.get(leadRecord.Portfolio_Interested_In__c) != null) {
            	populateLeadByPortfolio(leadRecord, portfolios);   
            }
        }
    }
    @TestVisible
    private void populateLeadByBuildingInterest(Lead leadRecord, Building__c building) {
        if(building == null) {
            return;
        }
        if(leadRecord.Building_Interested_In__c == null) {
            leadRecord.Building_Interested_In__c = building.Id;
        }
        leadRecord.Portfolio_Interested_In__c = building.Market__c;
        leadRecord.Territory_Name__c = building.Territory_Name__c;
    }
    @TestVisible
    private void populateLeadByPortfolio(Lead leadRecord, Map<Id, Market__c> portfolios) {
        leadRecord.Territory_Name__c = portfolios.get(leadRecord.Portfolio_Interested_In__c).Territory__c;
    }
    @TestVisible
    private void setBuildingInterestedInOnLeads(Map<String, Id> buildingNameToId){
        for(Lead leadRecord : newLeads){
            if(leadRecord.Locations_Interested__c == null){
                continue;
            }
            String buildingName = leadRecord.Locations_Interested__c.split(';')[0];
            if(leadRecord.Building_Interested_In__c == null && buildingNameToId.containsKey(buildingName)){
                leadRecord.Building_Interested_In__c = buildingNameToId.get(buildingName);
            }
        }
    }

    @TestVisible
    private void updateJourneyPrimaryContact(){
        Set<Id> convertedLeadIds = getConvertedLeadIds();
        if(convertedLeadIds.isEmpty()){
            return;
        }
        List<SObject> recordsToUpdate = new List<sObject>();
        List<Lead> journeyRelatedLeads = new List<Lead>(
            [SELECT Id, ConvertedContactId, 
                (SELECT Id, Primary_contact__c, Primary_Lead__c, Status__c,
                        Building_Interested_In__c, Interested_in_Number_of_Desks__c,
                        Locale__c, Description__c FROM Journeys__r ORDER BY LastModifiedDate DESC),
                (SELECT Id, Status, WhatId FROM Tasks WHERE Status <> 'Completed') 
            FROM Lead 
            WHERE Id IN : convertedLeadIds]);

        //Added By Jitesh Adwani for ST-3312
        //TODO investigate, extract to service
        objLatestModifiedJourney = journeyRelatedLeads[0].Journeys__r.size() > 0 ? journeyRelatedLeads[0].Journeys__r[0] : null;

        List<SObject> journeysToUpdate = new List<SObject>();
        List<SObject> tasksToUpdate = new List<SObject>();

        for(Lead leadRec : journeyRelatedLeads){
            for(Journey__c journeyRec : leadRec.Journeys__r){
                journeyRec.Primary_contact__c = leadRec.ConvertedContactId;
                journeyRec.Primary_Lead__c = null;
                journeysToUpdate.add(journeyRec);
            }
            Journey__c newestJourney = leadRec.Journeys__r.size() > 0 ? leadRec.Journeys__r[0] : null;
            if(newestJourney == null){
                continue;
            }
            for(Task taskRec : leadRec.Tasks){
                taskRec.Status = 'Completed';
                taskRec.WhatId = newestJourney.Id;
                tasksToUpdate.add(taskRec);
            }
        }
        recordsToUpdate.addAll(journeysToUpdate);
        recordsToUpdate.addAll(tasksToUpdate);
        if(!recordsToUpdate.isEmpty()){
            dml.add(recordsToUpdate, DmlConsolidator.Operation.FOR_UPDATE);
        }
    }
    @TestVisible    
    private Set<Id> getConvertedLeadIds(){
        Set<Id> convertedLeadIds = new Set<Id>();
        for(Lead leadRecord : newLeads){
            if(leadRecord.IsConverted && !(oldLeadsMap.get(leadRecord.Id).IsConverted)){
                convertedLeadIds.add(leadRecord.Id);
            }
        }
        return convertedLeadIds;
    }

    @TestVisible
    private void validateEmptyEmailOrPhone() {
        for(Lead leadRecord : newLeads){
            if(String.isBlank(leadRecord.Email) && String.isBlank(leadRecord.Phone)){
                leadRecord.addError('Email and Phone cannot be blank on Lead.');
            }
        }
    }

    @TestVisible
    private void setProcessingStageOnUpdate(){
        for(Lead leadRecord : newLeads){
            if(TriggerUtility.isFieldValueChanged(leadRecord, oldLeadsMap.get(leadRecord.Id),'CI_Updated_DateTime__c') 
            && (String.isBlank(leadRecord.Processing_Stage__c) || leadRecord.Processing_Stage__c == 'Created')){
                leadRecord.Processing_Stage__c = 'Enriched';
            } 
        }
    }

    @TestVisible
    private void updateActiveReferrerOnLead(){
        Set<String> leadEmails = getLeadEmailsIfNotBlank();
        if (leadEmails.isEmpty()) {
            return;
        }
        Map<String, Id> activeReferenceEmailToId = new Map<String, Id>();
        activeReferenceEmailToId = ReferenceHandler.getActiveReference(leadEmails);
        if (activeReferenceEmailToId.isEmpty()) {
            return;
        }
        setRefferersForLeads(activeReferenceEmailToId);
    }
    @TestVisible
    private Set<String> getLeadEmailsIfNotBlank(){
        Set<String> leadEmails = new Set<String>();
        for (Lead leadRecord : newLeads) {
            if(String.isNotBlank(leadRecord.Email)){
                leadEmails.add(leadRecord.Email);
            }
        }
        return leadEmails;
    }
    @TestVisible
    private void setRefferersForLeads(Map<String, Id> activeReferenceEmailToId){
        for (Lead leadRecord : newLeads) {
            if(String.isNotBlank(leadRecord.Email) && activeReferenceEmailToId.containsKey(leadRecord.Email.toLowerCase())){
                leadRecord.Referrer__c = activeReferenceEmailToId.get(leadRecord.Email.toLowerCase());
            }
        }
    }
    
    @TestVisible
    private void restartJourney(){
        Set<Id> validLeadForRestartJourneyIds = getValidLeadsForRestartJourney();
        if(validLeadForRestartJourneyIds.isEmpty()){
            return;
        }
        //TODO investigate
        if((Test.isRunningTest() && validLeadForRestartJourneyIds.size() <= 10) 
            || (System.isBatch()) 
            || (validLeadForRestartJourneyIds.size() <= Integer.valueof(System.Label.LeadAsync_Restart_Journey_Threshold) && !Test.isRunningTest())){
            restartJourney(validLeadForRestartJourneyIds);
        }else if(System.isQueueable()){
            restartJourneyInFuture(validLeadForRestartJourneyIds);
        }else{
            ID jobID = System.enqueueJob(new RestartJourneyQueueable(validLeadForRestartJourneyIds));
        }
    }
    @TestVisible
    private Set<Id> getValidLeadsForRestartJourney(){
        Set<Id> validLeadForRestartJourneyIds = new set <Id>();
        for(Lead leadRecord : newLeads){
            if(TriggerUtility.isFieldValueChanged(leadRecord, oldLeadsMap.get(leadRecord.Id), 'Restart_Journey__c') && leadRecord.Restart_Journey__c == true){
                validLeadForRestartJourneyIds.add(leadRecord.Id);
            }
        }
        return validLeadForRestartJourneyIds;
    }
    @future
    public static void restartJourneyInFuture(Set<Id> setLeadIds){
        new JourneyRestartService().restartJourneyForLead(setLeadIds);
    }

    @TestVisible
    private void validateLeadDeletionWithRelatedJourneys(){
        Set<Id> leadIdsWithJourneys = new Set<Id>();
        List<String> fields = new List<String>{'Primary_Lead__c'};
        for(Journey__c journeyRecord : journeySelector.getJourneysByLead(fields, new List<Lead>(oldLeads))){
            leadIdsWithJourneys.add(journeyRecord.Primary_Lead__c);
        }
        for(Lead objLead : oldLeads){
            if(leadIdsWithJourneys.contains(objLead.Id)){
                objLead.Email.addError('You cannot delete the Lead associated with one or more Journeys.');
            }
        }
    }

    @TestVisible
    private void updateCleansedName(){
        for(Lead lead : newLeads){
            if(String.isNotBlank(lead.Company)){
                lead.Cleansed_Company_Name__c = OrganizationHelper.getCleansedName(lead.Company);
            }else if(String.isNotBlank(lead.Name)){
                lead.Cleansed_Company_Name__c = OrganizationHelper.getCleansedName(lead.Name);
            }else{
                lead.Cleansed_Company_Name__c = OrganizationHelper.getCleansedName(lead.LastName);
            }
            if(String.isNotBlank(lead.Unomy_Company_Name_Formula__c)){
                lead.Cleansed_Unomy_Company_Name__c = OrganizationHelper.getCleansedName(lead.Unomy_Company_Name_Formula__c);
            }
        }
    }

    //TODO investigate and refactor
    @TestVisible
    private void convertLeadsToJourneys(){
        if(LeadConverterHelper.isLeadUpdateFromLeadConverter == true){
            return;
        }
        List<Lead> leadsToConvert = new List<Lead>();
        for(Lead objLead : newLeads){
            Boolean isEmailChanged = (context == TriggerContext.AFTER_UPDATE
                && String.isNotBlank(objLead.Email) 
                && String.isNotBlank(oldLeadsMap.get(objLead.Id).Email) 
                && !(objLead.Email.equalsIgnoreCase(oldLeadsMap.get(objLead.Id).Email)));
            if(context == TriggerContext.AFTER_INSERT || 
                (context == TriggerContext.AFTER_UPDATE 
                    && !objLead.isConverted 
                    && isEmailChanged 
                    || (objLead.Processing_Stage__c  != oldLeadsMap.get(objLead.Id).Processing_Stage__c 
                        && objLead.Processing_Stage__c == 'Assignment Complete') 
                    || (objLead.Send_For_Forcefully_Lead_Assignments__c  != oldLeadsMap.get(objLead.Id).Send_For_Forcefully_Lead_Assignments__c 
                        && objLead.Send_For_Forcefully_Lead_Assignments__c == false))){
                leadsToConvert.add(new Lead(Id = objLead.Id, Email = objLead.Email, Campaign_Id__c = objLead.Campaign_Id__c ));
                if(context == TriggerContext.AFTER_UPDATE){ 
                    LeadConverterHelper.isInsert = false;
                    LeadConverterHelper.isCreateActivity = false; 
                    if(isEmailChanged){
                        mapLeadsEmailChanged.put(objLead.Id,objLead);
                    }                        
                }
            }
        } 
        
        if(leadsToConvert.isEmpty()){
            return;
        }
        //TODO Investigate and refactor
        Boolean isAfterInsertContext = context == TriggerContext.AFTER_INSERT;
        if((Test.isRunningTest() && leadsToConvert.size() <= 10) 
            || (System.isBatch() 
                || (String.isNotBlank(System.Label.Lead_Converter_Threshold) 
                    && leadsToConvert.size() <= Integer.valueof(System.Label.Lead_Converter_Threshold) && !Test.isRunningTest()))){                   
            if(isAfterInsertContext){
                LeadConverterHelper.isInsert = true;
            }
            LeadConverterHelper.manageLead(leadsToConvert);  
        }else if(System.isQueueable()){ 
            callLeadConversionInFuture(JSON.serialize(leadsToConvert), isAfterInsertContext, JSON.serialize(mapLeadsEmailChanged), RESTInboundLeadAPIHelper.isLeadFromWeb);
        }else { 
            System.enqueueJob(new LeadConversionAsyncQueueable(leadsToConvert, isAfterInsertContext, mapLeadsEmailChanged, RESTInboundLeadAPIHelper.isLeadFromWeb));
        }
        LeadConverterHelper.isInsert = true;
    }
    @future
    public static void callLeadConversionInFuture(String serializedLeads, Boolean isInsertContext, String serializedLeadsEmailChanged, Boolean isLeadFromWeb){
        List<Lead> leads = (List<Lead>)JSON.deserialize(serializedLeads,  List<Lead>.class);
        LeadTriggerHandler.mapLeadsEmailChanged = (Map<Id,Lead>)JSON.deserialize(serializedLeadsEmailChanged, Map<Id,Lead>.class);    
        LeadConverterHelper.isInsert = isInsertContext; 
        RESTInboundLeadAPIHelper.isLeadFromWeb = isLeadFromWeb;
        LeadConverterHelper.manageLead(leads);
    }
    
    @TestVisible
    private void populateOrganization(){
        List<Lead> leadsToFindOrg = getLeadsToFindOrgFor();
        if(leadsToFindOrg.isEmpty()){
            return;
        }
        Map<Id, Map<String, Set<String>>> matchingAccountsMap = OrganizationHelperServices.findOrgByNewCriterias(leadsToFindOrg);
        if(matchingAccountsMap.isEmpty()){
            return;
        }
        setAccountForLeads(matchingAccountsMap);
    }
    @TestVisible
    private List<Lead> getLeadsToFindOrgFor(){
        List<Lead> leadsToFindOrg = new List<Lead>();
        for(Lead leadRecord : newLeads){
            if(String.isBlank(leadRecord.Account__c) && leadRecord.CI_Updated_DateTime__c != null && leadRecord.CI_Updated_DateTime__c != oldLeadsMap.get(leadRecord.Id).CI_Updated_DateTime__c){
                leadsToFindOrg.add(leadRecord);
            }
        }
        return leadsToFindOrg;
    }
    @TestVisible
    private void setAccountForLeads(Map<Id, Map<String, Set<String>>> matchingAccountsMap){
        for(Lead leadRecord : newLeads){
            if(matchingAccountsMap.get(leadRecord.Id) == null){
                continue;
            }
            Set<String> matchedAccountIds = matchingAccountsMap.get(leadRecord.Id).get('highConfidenceAccountIds');
            if(matchedAccountIds != null && !matchedAccountIds.isEmpty()){
                leadRecord.Account__c = new List<String>(matchedAccountIds)[0];
            }
        }
    }

    @TestVisible
    private void updateLeadSourceAndLeadSourceDetail(){
        for(Lead leadRecord : newLeads){
            if(String.IsNotBlank((String) leadRecord.get('utm_source__c')) && leadRecord.utm_source__c == 'partner'){
                leadRecord.LeadSource = 'Partner Referral';
                leadRecord.Lead_Source_Detail__c = leadRecord.utm_medium__c;
            }
        }
    }

    public class LeadTriggerHandlerException extends Exception{}

    public class RecordTypeSize {
        public String size {get;set;}
        public String recordType {get;set;}
    }
    public class RecordTypeForCompanySize {
        public RecordTypeSize setting {get;set;}
        public Integer minNumberOfEmployees {get;set;}
        public Integer maxNumberOfEmployees {get;set;} 
        public String recordTypeName {get;set;}

        public RecordTypeForCompanySize(RecordTypeSize setting){
            this.recordTypeName = setting.recordType;
            if (setting.size.contains('-')){
                List<String> bounderies = setting.size.split('-');
                minNumberOfEmployees = Integer.valueOf(bounderies[0]);
                maxNumberOfEmployees = Integer.valueOf(bounderies[1]);
            } else if (setting.size.contains('+')) {
                maxNumberOfEmployees = null;
                minNumberOfEmployees = Integer.valueOf(setting.size.removeEnd('+'));
            }
        }

        public Boolean isWithinRange(Integer companySize){
            return (companySize >= minNumberOfEmployees && (companySize <=maxNumberOfEmployees || maxNumberOfEmployees == null));
        }
    }
}