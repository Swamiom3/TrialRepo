/************************************************************************************************************************************
    Author      :   Dipak Pawar
    Description :   This class contain all aura methods related to Followup Call page.
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION     DATE                AUTHOR                  DETAIL
    1           7 January 2019      Dipak Pawar             Initial Developement
	2			9 April 2019		Ashish Mishra			Modify for bulk journey update.
**************************************************************************************************************************************/
public without sharing class FollowUpController {
    public static Boolean isInvoker = false;
    public static Savepoint objSavePoint {get; set;}
    public List<Id> journeyIds { get; set; }
    private static TaskSelector taskSelector = new TaskSelector();
    @TestVisible
    private static JourneySelector journeySelector = new JourneySelector();

    static {
        isInvoker = ApexDebugLog.registerRootInvoker(ApexDebugLog.InvokerType.AURA, 'FollowUpController' + 'getsObjectPrefix', ApexDebugLog.InvokerType.AURA);
    }

    public FollowUpController(ApexPages.StandardSetController standardController){
        List<SObject> lstSelectedJourneys = standardController.getSelected();
        journeyIds = new List<Id>();
        if(!lstSelectedJourneys.isEmpty()) {
            for(SObject objJourney : lstSelectedJourneys){
                journeyIds.add(objJourney.Id);
            }
        } else {
            journeyIds.add(ApexPages.currentPage().getParameters().get('id'));
        }
    }

    /************************************************************************************************************************************
        Author         : Dipak Pawar
        Description    : This method takes journeyId as a parameter and return formdata for Journey Followup
        Created Date   : 9 January 2019
        Issue No.      :
    **************************************************************************************************************************************/
    @AuraEnabled
    public static DatabaseResult getFollowUpData(List<Id> lstJourneyIds){
        try{
            Map<String, Object> mapFollowupData = new Map<String, Object>();

            mapFollowupData.put('currentDate', Date.today());

            MetadataSetting__mdt followupCallSetting = Settings.getMetadataSetting('FollowUpCall');
            mapFollowupData.put('followupCallSetting', followupCallSetting.Data__c);

            List<Journey__c> lstJourney = journeySelector.getJourneysWithAdditionalFieldsByIds(new List<Id>(lstJourneyIds));
            mapFollowupData.put('journeyRecord', lstJourney);

            return new DatabaseResult(mapFollowupData);
        } catch(Exception pEx) {
            ApexDebugLog.logException(pEx, null, 'FollowUpController', 'getFollowUpData');
            return new DatabaseResult(pEx);
        }
    }

    /************************************************************************************************************************************
        Author         : Dipak Pawar
        Description    : Method to save the followup for gievn Journeys with next followup date and comments
        Created Date   : 9 January 2019
        Issue No.      :
    **************************************************************************************************************************************/
    @AuraEnabled
    public static DatabaseResult saveJourneyFollowUp(List<Id> lstJourneyIds, String nextFollowUpDate, String strFollowUpComments){
        try {
            objSavePoint = Database.setSavepoint();
            Set<Id> setJourneyIds = new Set<Id>(lstJourneyIds);
            List<Journey__c> lstJourneys = journeySelector.getJourneysByIdsWithLeadOrContactPresent(new List<Id>(setJourneyIds));

            Map<Id, Task> mapFollowUpTasks = new Map<Id, Task>(getTasksForJourneys(lstJourneys));
            Integer followupCallPeriod = getFollowupCallPeriod();

            Set<String> setJourneyCloseStages = JourneyHelper.getJourneyCloseStages();

            List<Task> lstFollowUpTasks = new List<Task>();
            for(Journey__c objJourney : lstJourneys){
                objJourney.NMD_Next_Contact_Date__c = Date.valueOf(nextFollowUpDate);
                if(getDateDifference(objJourney.CreatedDate, Date.valueOf(nextFollowUpDate)) > followupCallPeriod && !setJourneyCloseStages.contains(objJourney.Status__c)){
                    objJourney.Outreach_Stage__c ='Manual Outreach';
                }
                Task objTask;
                if(objJourney.Primary_Lead__c != null && mapFollowUpTasks.containsKey(objJourney.Primary_Lead__c)){
                    objTask = mapFollowUpTasks.get(objJourney.Primary_Lead__c).clone(false, true, false, false);
                } else if(objJourney.Primary_Contact__c != null && mapFollowUpTasks.containsKey(objJourney.Primary_Contact__c)){
                    objTask = mapFollowUpTasks.get(objJourney.Primary_Contact__c).clone(false, true, false, false);
                    objTask.WhoId = objJourney.Primary_Contact__c;
                }
                if(objTask != null){
                    objTask.Type = 'Call';
                    objTask.Subject = 'Follow-Up';
                    objTask.Status = 'Not Started';
                    objTask.WhatId = objJourney.Id;
                    objTask.ActivityDate = Date.valueOf(nextFollowUpDate);
                    objTask.Description = String.isNotBlank(strFollowUpComments) ? strFollowUpComments : NULL;
                    objTask.OwnerId = UserInfo.getUserId();
                    lstFollowUpTasks.add(objTask);
                }
            }
            for(Task objTask : taskSelector.getTasksWithRelatedObjectsFieldsByWhatIdsAndNoCompletedStatus(new List<Id>(setJourneyIds))){
                objTask.Status = 'Completed';
                lstFollowUpTasks.add(objTask);
            }
            if(!lstJourneys.isEmpty()){
                update lstJourneys;
                if(!lstFollowUpTasks.isEmpty()){
                    upsert lstFollowUpTasks;
                }
            }

            return new DatabaseResult(true);
        } catch(Exception pEx) {
            System.debug('pEx ==>'+pEx.getStackTraceString());
            Database.rollback(objSavePoint);
            ApexDebugLog.logException(pEx, lstJourneyIds + String.valueOf(nextFollowUpDate), 'FollowUpController', 'saveFollowUp');
            return new DatabaseResult(pEx);
        }
    }

    /************************************************************************************************************************************
        Author         : Dipak Pawar
        Description    : This method will give the Tasks for given Journeys
        Created Date   : 10 January 2019
        Issue No.      :
    **************************************************************************************************************************************/
    public static Map<Id, Task> getTasksForJourneys(List<Journey__c> lstJourneys){
        Map<Id, Task> mapFollowUpTasks = new Map<Id, Task>();
        Set<Id> setLeadIds = new Set<Id>();
        Set<Id> setContactIds = new Set<Id>();
        for(Journey__c objJourney : lstJourneys){
            if(objJourney.Primary_Lead__c != null){
                setLeadIds.add(objJourney.Primary_Lead__c);
            } else if(objJourney.Primary_Contact__c != null){
                setContactIds.add(objJourney.Primary_Contact__c);
            }
        }
        if(!setLeadIds.isEmpty()){
            Map<Id, SObject> fieldMappings = FieldMappingsHelper.getMappings(setLeadIds, 'FieldMappings_LeadToActivity');
            for(Id parentId : fieldMappings.keySet()){
                Task objTask = (Task)fieldMappings.get(parentId);
                mapFollowUpTasks.put(parentId, objTask);
            }
        }

        if(!setContactIds.isEmpty()){
            Map<Id, SObject> fieldMappings = FieldMappingsHelper.getMappings(setContactIds, 'FieldMappings_ContactToActivity');
            for(Id parentId : fieldMappings.keySet()){
                Task objTask = (Task)fieldMappings.get(parentId);
                mapFollowUpTasks.put(parentId, objTask);
            }
        }
        return mapFollowUpTasks;
    }

    /************************************************************************************************************************************
        Author         : Dipak Pawar
        Description    : This method will give the difference between given two dates
        Created Date   : 10 January 2019
        Issue No.      :
    **************************************************************************************************************************************/
    public static Long getDateDifference(DateTime journeyCreatedDate, DateTime journeyNextNmdDate) {
        Long createdDate = journeyCreatedDate.getTime(), nextNMDDate = journeyNextNmdDate.getTime();
        Long milliseconds = nextNMDDate - createdDate;
        Long seconds = milliseconds / 1000;
        Long minutes = seconds / 60;
        Decimal rem =  Math.mod(minutes, 60);
        Decimal hours = minutes / 60;
        if(rem > 30) {
            hours += 0.6;
        }
        return Math.round(hours);
    }

    /************************************************************************************************************************************
        Author         : Dipak Pawar
        Description    : This method will give the Followup Call Period configured in "FollowupOptions"
        Created Date   : 10 January 2019
        Issue No.      :
    **************************************************************************************************************************************/
    public static Integer getFollowupCallPeriod(){
        Sales_Console_Setting__mdt followupSetting = SalesConsoleSettings.get('FollowupOptions');
        Integer followupCallPeriod = 48;
        if(followupSetting != null && String.isNotBlank(followupSetting.Data__c)){
            Map<String, String> mapFollowupSetting = (Map<String, String>)JSON.deserialize(followupSetting.Data__c, Map<String, String>.class);
            if(mapFollowupSetting != null && mapFollowupSetting.containsKey('FollowupCallPeriod') && mapFollowupSetting.get('FollowupCallPeriod') != null){
                followupCallPeriod = Integer.valueOf(mapFollowupSetting.get('FollowupCallPeriod'));
            }
        }
        return followupCallPeriod;
    }
    
    /****************************************************************************************************************************
        Author              : Sunil Bhosale
        Description         : This Method is used to update bulk of journey.
        Created Date        : 03/07/2017
        Last Modified By    : Ashish Mishra
        Last Modified Date  : 31,May 2018
		Last Modified By    : Vaishnavi Khandar
        Last Modified Date  : 06, Feb 2020
   *****************************************************************************************************************************/
    public static DatabaseResult bulkJourneyUpdates(List<String> journeyIds,String nmdNextContactDate1,String description) {
        if(journeyIds != NULL && !journeyIds.isEmpty()){
            return saveJourneyFollowUp(journeyIds, nmdNextContactDate1, description);
        }
        return new DatabaseResult(false);
    }
}