/**
 * @description Handler class for the Case trigger
 * @name trac_CaseHandler
 * @author Shubham Jain, Traction on Demand
 * @date 2019-08-27
 */

public with sharing class trac_CaseHandler {

    public static void blockTimeDelay(List<Case> cases) {
        Global__c globalSetting = Global__c.getInstance();
        Decimal numSeconds = globalSetting.Email_to_Case_Time_Delay__c == null ? 10 : globalSetting.Email_to_Case_Time_Delay__c;
        Set<String> emailAddresses = TLList.collectStrings(cases, Case.SuppliedEmail);
        if (emailAddresses.size() < 1) { 
            return;
        }

        Datetime now = Datetime.now();
        Long futureDateTime = now.getTime() - (Long) (numSeconds * 1000);
        List<Case> recentCases = [SELECT Id, SuppliedEmail FROM Case WHERE CreatedDate > :Datetime.newInstance(futureDateTime)];
        Set<String> emailAddressesToBlock = TLList.collectStrings(recentCases, Case.SuppliedEmail);
        for (Case cs : cases) {
            if (emailAddressesToBlock.contains(cs.SuppliedEmail)) {
                cs.addError('This email address already created a case within the past ' + numSeconds + ' seconds.');
            }
        }
    }


    public static void maskCreditCardNumbers(List<Case> cases) {
        List<Case> emailCases = TLTrigger.filterByFieldCriterium(cases, Case.Origin, 'Email');
        if (emailCases.size() < 1) return;
        Set<String> fields = new Set<String>();
        for (Schema.FieldSetMember field : Schema.SObjectType.Case.fieldSets.Credit_Card_Mask_Fields.getFields()) {
            fields.add(String.valueOf(field.getFieldPath()));
        }
        trac_Utilities.maskCreditCardNumbers((List<SObject>) emailCases, fields);
    }

    /**
     * @description method to filter cases when the status has changed
     * @param cases list of case records
     * @param oldMap map of id to previous record values
     */
    public static void statusChange(List<Case> cases, Map<Id, Case> oldMap) {
        statusChange((List<Case>) TLTrigger.filterByFieldChanged(cases, oldMap, Case.Status));
    }


    /**
     * @description method to distribute logic for all methods that rely on status
     * @param cases list of case records
     */
    public static void statusChange(List<Case> cases) {
        for (Case cs : cases) {
         /*   updateSupportRequestReOpenTillDate(cs); */
            updateSupportRequestWaitingOnSubmitterFields(cs);
            updateSupportRequestIsBusinessDay(cs);
        }
    }

    /**
     * @description method to update Support Request Re Open Till Date with Solved Date + 3 Business Days
     *              if Status is updated to Solved
     * @MOVING TO TIME BASED WORKFLOW 1/25 - JM
     * @param cs case record
     */
  

    /**
     * @description method to update Support Request Waiting on Support Request Date and Fields and email sent checkboxes if Status
     * is updated to Waiting on Support Request Submitter
     * @param cs case record
     */
    public static void updateSupportRequestWaitingOnSubmitterFields(Case cs) {
        System.debug(cs.Status);
        System.debug(TLOrgConstants.CASE_STATUS_WAITING);
        if (isWaitingStatus(cs)) {
            System.debug('hi');
            if (hasBusinessHours(cs) && isSupportRequest(cs)) {
                System.debug('hello');
                cs.Waiting_on_Support_Request_24_hours__c = addDays(cs.BusinessHoursId, System.now(), 1);
                //cs.Waiting_on_Support_Request_4_days__c = addDays(cs.BusinessHoursId, System.now(), 4);
                //cs.Waiting_on_Support_Request_Submitter__c = addDays(cs.BusinessHoursId, System.now(), 7);
                cs.Is_24_Hours_After_Email_Sent__c = false;
                //cs.Is_4_Days_After_Email_Sent__c = false;
                //cs.Is_7_Days_After_Email_Sent__c = false;
            }
        } else {
            cs.Waiting_on_Support_Request_24_hours__c = null;
            //cs.Waiting_on_Support_Request_4_days__c = null;
            cs.Waiting_on_Support_Request_Submitter__c = null;
        }
    }


    /**
     * @description method returns a DateTime after adding specified business days in a datetime
     * @param bHourId Id of Business Hours
     * @param startDate Start Date to add business days in it
     * @param days No of business days to add
     */
    public static Datetime addDays(Id bHourId, Datetime startDate, Integer days) {
        //If startdate is not within working days, take next working day
        startDate = BusinessHours.nextStartDate(bHourId, startDate);

        for (Integer elapsed = 0; elapsed < days; elapsed++) {
            //Add 1 day
            startDate = startDate.addDays(1);

            //Check if new date is within working days
            if (!BusinessHours.isWithin(bHourId, startDate)) {
                //If new date is not within working days, get new working day
                startDate = BusinessHours.nextStartDate(bHourId, startDate);
            }
        }
        return startDate;
    }


    /**
     * @description method update Support Request isBusinessDay or isHoliday is status is New
     * @param cs case record
     */
    public static void updateSupportRequestIsBusinessDay(Case cs) {
       BuildingSelector buildingClass = new BuildingSelector();
        List<Building__c> buildList = buildingClass.getBuildingHoursId(cs.Building_Nearest_Address__c);
        if(buildList != null && !buildList.isEmpty()){
         if (buildList[0].Business_Hours_Id__c != null && isNewStatus(cs) && hasBusinessHours(cs) && isSupportRequest(cs) && IsWeLOB(cs)) {
            cs.BusinessHoursId = buildList[0].Business_Hours_Id__c;
            cs.Is_Business_Day__c = isWorkingDay(cs.BusinessHoursId, System.now());
            cs.Is_Holiday__c = isHoliday(cs.BusinessHoursId, System.now());
         }
        }
        else{
            return ;
        }
    }

    /**
     * @description method to calculate the duration of business hours between case opening and closing time.
     */

    public static void updateTotalHandleTimeOnCaseComplete(List<Case> newCaseList, Map<Id,Case> oldCasesMap) {
        for(Case cs: newCaseList){
            //Update the field : Total handle time in business hours if case status is changed to closed on support request.
            if(trigger.isInsert){
                if (hasBusinessHours(cs) && cs.isclosed == TRUE && cs.CreatedDate != null) {
                    Decimal timeInHour = (Decimal) BusinessHours.diff(cs.BusinessHoursId, cs.CreatedDate, System.now()) / 3600000;
                    cs.Total_Handle_Time_in_Business_Hours__c = timeInHour.setScale(2);
                }
            }
            if(trigger.isUpdate){
                Case oldCase = oldCasesMap.get(cs.Id);
                if (hasBusinessHours(cs) && cs.isclosed == TRUE && cs.isclosed != oldCase.isclosed && cs.CreatedDate != null) {
                    Decimal timeInHour = (Decimal) BusinessHours.diff(cs.BusinessHoursId, cs.CreatedDate, System.now()) / 3600000;
                    cs.Total_Handle_Time_in_Business_Hours__c = timeInHour.setScale(2);
                }
            }
            //Remove any value on total handle time field if current case status is not closed.
            if (isNotCompleteStatus(cs)) {
                cs.Total_Handle_Time_in_Business_Hours__c = null;
            }
        }
    }

    /**
     * @description method to filter cases when the first response time has changed in After update trigger
     * @param cases list of case records
     * @param oldMap map of id to previous record values
     */

    public static void firstResponseTimeChange(List<Case> cases, Map<Id, Case> oldMap) {
        firstResponseTimeChange((List<Case>) TLTrigger.filterByFieldChanged(cases, oldMap, Case.First_Response_Time__c));
    }

    /**
     * @description method to calculate the time duration between case opening and first response in after update
     * @param cases list of case records
     */

    private static void firstResponseTimeChange(List<Case> cases) {
        for (Case cs : cases) {
            //Update the field : Number of business hours in first response if first response has been made on support request.
            if (hasBusinessHours(cs) && cs.First_Response_Time__c != null && cs.CreatedDate != null) {
                Decimal timeInHour = (Decimal) BusinessHours.diff(cs.BusinessHoursId, cs.CreatedDate, cs.First_Response_Time__c) / 3600000;
                cs.No_of_Business_Hours_in_First_Response__c = timeInHour.setScale(2);
            }
        }
    }

    /**
     * @description filters records that have location changed
     * @param cases list of case records
     * @param oldMap map of previous case records
     */
    /*COMMENTED AS PART OF LOCATION__C TO BUILDING__C UPDATES
    public static void updateBusinessHours(List<Case> cases, Map<Id, Case> oldMap) {
        updateBusinessHours(TLTrigger.filterByFieldChanged(cases, oldMap, Case.Building_Nearest_Address__c));
    }
    */
    /**
     * @description method update Support Request businesshourId
     * @param cases list of case records
     */
    /*COMMENTED AS PART OF LOCATION__C TO BUILDING__C UPDATES
    public static void updateBusinessHours(List<Case> cases) {
        if (cases.isEmpty()) return;

        Map<Id, Id> buildingCaseIdMap = new Map<Id, Id>();
        Map<Id, Id> buildingBusinessHourMap = new Map<Id, Id>();
        BusinessHours businessHourId = queryDefaultBusinessHour();

        for (Case cs : cases) {
            if (cs.Building_Nearest_Address__c  == null) {
                cs.BusinessHoursId = businessHourId.Id;
            } else {
                buildingCaseIdMap.put(cs.Building_Nearest_Address__c , cs.Id);
            }
        }

        if (!buildingCaseIdMap.isEmpty()) {
            //fetching location detail
            for (Building__c building : queryLocationsByIds(buildingCaseIdMap.keySet())) {
                if (building.Business_Hours_Id__c != null) {
                    buildingBusinessHourMap.put(building.Id, building.Business_Hours_Id__c);
                } else {
                    buildingBusinessHourMap.put(building.Id, businessHourId.Id);
                }

            }
        }

        //update case business hour based on location
        if (!buildingBusinessHourMap.isEmpty()) {
            for (Case cs : cases) {
                if (buildingBusinessHourMap.containsKey(cs.Location__c)) {
                    cs.BusinessHoursId = buildingBusinessHourMap.get(cs.Location__c);
                }
            }
        }
    }
    */

    /**
     * @description location is changed on a case, assign it to that building's cm queue
     * @param cases list of cases
     * @param oldMap map of id to case of records old values
     * UPDATE: Updated Location__c references to Building__c
     */
    public static void changeQueueBuildingUpdated(List<Case> cases, Map<Id, Case> oldMap) {
        Set<Id> locationIds = new Set<Id>();
        List<Case> casesChangedLocation = (List<Case>) TLTrigger.filterByFieldChanged(cases, oldMap, Case.Building_Nearest_Address__c);

        Map<Id, Building__c> buildingsToIgnore = new Map<Id, Building__c>([
                SELECT Id
                FROM Building__c
                WHERE Name IN :(NEW List<String>{
                        'Not Applicable'
                })
        ]);

        /*for (Case cs : casesChangedLocation) {
            if (cs.Location__c != null && cs.Origin !='Email' && !locationsToIgnore.keySet().contains(cs.Location__c)) {
                locationIds.add(cs.Location__c);
            }
        }
        if (locationIds.isEmpty()) return;*/

        Location_Queue_Type__mdt queueType = [
                SELECT Queue_Name_Prefix__c
                FROM Location_Queue_Type__mdt
                WHERE DeveloperName = 'Community_Back_of_House_HQxWe'
        ];
        if (queueType == null) return ;

        List<Location_Queue__c> locationQueues = [
                SELECT Id,Building_Id__c,Queue_Id__c
                FROM Location_Queue__c
                WHERE Building_Id__c IN :locationIds
                AND Queue_Prefix__c = :queueType.Queue_Name_Prefix__c
        ];

        Map<String, String> locationIdToQueueId = new Map<String, String>();

        for (Location_Queue__c locationQueue : locationQueues) {
            locationIdToQueueId.put(locationQueue.Building_Id__c, locationQueue.Queue_Id__c);
        }

        for (Case cs : casesChangedLocation) {
            if (locationIdToQueueId.get(cs.Building_Nearest_Address__c) != null) {
                cs.OwnerId = locationIdToQueueId.get(cs.Building_Nearest_Address__c);
            }
        }
    }

    public static void revertCompleteResolutionTimeMilestones(List<Case> cases, Map<Id, Case> oldCases) {
        if (UserInfo.getUserType() == 'Standard') {
            List<Id> revertCases = new List<Id>();
            for (Case c : cases) {
                if(((c.isClosed != oldCases.get(c.Id).isClosed) && c.isClosed == false && c.CaseRecordTypeName__c != 'Support Request Read Only') || ((c.Status != oldCases.get(c.Id).Status) && c.Status != 'Solved' && c.CaseRecordTypeName__c != 'Support Request Read Only') && c.SlaExitDate != null){
                    revertCases.add(c.Id);

                    c.Auto_Resolution_Time_SLA__c = false;
                    system.debug('***status = ' + c.Status + ' - ' + c.ClosedDate);
                }
            }
            if (revertCases.isEmpty() == false){
                milestoneUtils.revertCompletion(revertCases, 'Resolution Time (SLA)');
            }

        }
    }

    /**
     * @description method update Case Milestone Completion date for Resolution Time milestones
     * @param cases list of cases
     * @author Shubham Jain, Traction On Demand
     */
    public static void completeResolutionTimeMilestones(List<Case> cases) {
        if (UserInfo.getUserType() == 'Standard') {
            DateTime completionDate = System.now();
            List<Id> updateCases = new List<Id>();
            List<Id> revertCases = new List<Id>();
            for (Case c : cases) {
                if (((c.isClosed == true) || (c.Status == 'Solved')) && ((c.SlaStartDate <= completionDate) && (c.SlaExitDate == null))){
                    updateCases.add(c.Id);
                }
            }
            if (updateCases.isEmpty() == false){
                milestoneUtils.completeMilestone(updateCases, 'Resolution Time (SLA)', completionDate);
            }
        }
    }

    /**
    * @description method update Case Milestone Completion date for Time In Queue milestones
    * @param cases list of cases
    * @author Shubham Jain, Traction On Demand
    */
    public static void completeTimeInQueueMilestones(List<Case> cases, Map<Id, Case> oldCases) {
        if (UserInfo.getUserType() == 'Standard') {
            DateTime completionDate = System.now();
            List<Id> updateCases = new List<Id>();
            for (Case c : cases) {
                if ((String.valueOf(oldCases.get(c.Id).OwnerId).startsWith('00G') && (c.OwnerId != oldCases.get(c.Id).OwnerId)) && String.valueOf(c.OwnerId).startsWith('005')) {
                    updateCases.add(c.Id);
                }
                //updateCases.add(c.Id);
            }
            system.debug('***updateCases Queue = ' + updateCases);
            if (updateCases.isEmpty() == false)
                milestoneUtils.completeMilestone(updateCases, 'Time in Queue', completionDate);
        }
    }

    /**
    * @description method update Case Milestone Completion date for First Response milestones
    * @param cases list of cases
    * @author Jessie Mead
    */
    public static void completeFirstResponseMilestones(List<Case> cases, Map<Id, Case> oldCases) {
        if (UserInfo.getUserType() == 'Standard') {
            DateTime completionDate = System.now();
            List<Id> updateCases = new List<Id>();
            for (Case c : cases) {
                if (c.First_Response_Time__c != NULL) {
                    updateCases.add(c.Id);
                }
                //updateCases.add(c.Id);
            }
            system.debug('***updateCases First = ' + updateCases);
            if (updateCases.isEmpty() == false)
                milestoneUtils.completeMilestone(updateCases, 'First Response Time', completionDate);
        }
    }

    /**
     * @description update the case status when the owner is changed to ace or interr queue
     * @param cases
     * @param oldMap
     */
    public static void ownerIsVendor(List<Case> cases, Map<Id, Case> oldMap) {
        List<Case> casesOwnerChanged = TLTrigger.filterByFieldChanged(cases, oldMap, Case.OwnerId);
        if (casesOwnerChanged.size() < 1) return;

        List<Object> queueIds = (List<Object>) TLList.collectIdsAsList([
                SELECT Id
                FROM Group
                WHERE Type = 'Queue'
                AND (DeveloperName = :TLOrgConstants.QUEUE_ACE_DEVNAME OR DeveloperName = :TLOrgConstants.QUEUE_INTERR_DEVNAME)
        ]);

        for (Case cs : (List<Case>) TLTrigger.filterByFieldCriteria(casesOwnerChanged, Case.OwnerId, queueIds)) {
            cs.Status = TLOrgConstants.CASE_STATUS_WAITING_ON_EXTERNAL_PARTY;
        }
    }


    //************ HELPER LOGIC ************//
    public static String getBuildingCode(String subject) {
        String deviceName = '';
        if (subject != null) {
            List<String> subjectInfo = subject.split(' ');
            deviceName = subjectInfo.get(subjectInfo.size() - 1);
        }
        return deviceName.split('-')[0];
    }


    //************ BOOLEAN HELPERS ************//
    /**
     * @description method returns a IsBusinessDay after Check if supplied date is working day or not
     * @param bHourId Id of Business Hours
     * @param startDate Start Date to verify Support Request created date
     */
    public static Boolean isWorkingDay(Id bHourId, Datetime startDate) {
        return BusinessHours.isWithin(bHourId, startDate);
    }


    /**
     * @description method returns a isHoliday after Check if supplied date is working day or not
     * @param bHourId Id of Business Hours
     * @param startDate Start Date to verify Support Request created date
     */
    public static Boolean isHoliday(Id bHourId, Datetime startDate) {
        return !BusinessHours.isWithin(bHourId, startDate);
    }


    /**
     * @description determines if a case has a status other than one of the completed statuses ie closed or solved
     * @param cs case record
     * @return boolean
     */
    public static Boolean isNotCompleteStatus(Case cs) {
        return cs.Status != TLOrgConstants.CASE_STATUS_SOLVED && cs.Status != TLOrgConstants.CASE_STATUS_CLOSED;
    }


    /**
     * @description determines if the case status is new
     * @param cs case record
     * @return boolean
     */
    public static Boolean isNewStatus(Case cs) {
        return cs.Status == TLOrgConstants.CASE_STATUS_NEW;
    }

    /**
     * @description determines if a case has a status of waiting on request submitter
     * @param cs case record
     * @return boolean
     */
    public static Boolean isWaitingStatus(Case cs) {
        return cs.Status == TLOrgConstants.CASE_STATUS_WAITING;
    }

    /**
     * @description determines if a case has a status of solved
     * @param cs case record
     * @return boolean
     */
    public static Boolean isSolvedStatus(Case cs) {
        return cs.Status == TLOrgConstants.CASE_STATUS_SOLVED;
    }


    /**
     * @description determines if a case has business hours
     * @param cs case record
     * @return boolean
     */
    public static Boolean hasBusinessHours(Case cs) {
        return cs.BusinessHoursId != null;
    }


    /**
     * @description determines if a case is a support request record type
     * @param cs case record
     * @return boolean
     */
    public static Boolean isSupportRequest(Case cs) {
        return cs.RecordTypeId == TLOrgConstants.SUPPORT_REQUEST_RECORD_TYPE_ID;
    }


    /**
     * @description determines if the case lob is one of the preconfigured we lines of business
     * @param cs case record
     * @return boolean
     */
    public static Boolean IsWeLOB(Case cs) {
        List<String> lobs = new List<String>{
                TLOrgConstants.CASE_LINE_OF_BUSINESS_WEWORK,
                TLOrgConstants.CASE_LINE_OF_BUSINESS_WELIVE
        };
        return lobs.contains(cs.WeCo_Line_of_Business__c);
    }


    /**
     * @description determines if the input value is not null or empty string
     * @param input object
     * @return boolean
     */
    public static Boolean isValue(Object input) {
        return input != null && input != '';
    }


    //************ QUERIES ************//
    /**
     * @description queries for the default busniess hours record ie. eastern daylight time
     * @return BusinessHours record
     */
    public static BusinessHours queryDefaultBusinessHour() {
        return [
                SELECT Id, Name
                FROM BusinessHours
                WHERE Name = :TLOrgConstants.BUSINESS_HOUR_EASTERN_DAYLIGHT
                LIMIT 1
        ];
    }


    /**
     * @description queries for location based on list of location ids
     * @param locationIds
     * @return list of locations
     * UPDATE: Updated Location__c references with Building__c
     */
    public static List<Building__c> queryLocationsByIds(Set<Id> buildingIds) {
        return [SELECT Id, Name, Business_Hours_Id__c FROM Building__c WHERE Id IN :buildingIds];
    }

    /**
     * @description queries for location records based on building codes (Building_Code__c)
     * @param buildingCodes list of string building codes
     * @return list of location records
     * UPDATE: Updating Location__c references with Building__c,
     * COMMENTED OUT as not needed anymore, as its calling has been removed
     */
    /* Temporarily commented
    public static List<Building__c> queryLocationsByBuildingCode(List<String> buildingCodes) {
        return [
                SELECT Id, Name, Building_Code__c
                FROM Building__c
                WHERE Building_Code__c != NULL
                AND Building_Code__c IN :buildingCodes
        ];
    }
    */
}