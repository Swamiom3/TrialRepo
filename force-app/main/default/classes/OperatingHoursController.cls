/************************************************************************************************************************************
Author      :   Salesforce
Description :   This class is used to retrieve the Operating Hours and Time Slots associated with Building and other related objects.
----------------------------------------------------------------------------------------------------------------------------------
VERSION     DATE                AUTHOR                DETAIL
1           01 Aug 2021         Salesforce            Initial Developement
**************************************************************************************************************************************/
public with sharing class OperatingHoursController {
   
    @AuraEnabled
    public static String getBuildingOperatingHours(String buildingId){
        return JSON.serialize([SELECT Id, Name, TimeZone, 
                                    (SELECT Id, DayOfWeek, StartTime, EndTime
                                     FROM TimeSlots ORDER BY Sort_Order__c ASC) 
                               FROM OperatingHours
                               WHERE Building_Id__c =: buildingId
                                   AND Host_Id__c = null 
                               LIMIT 1]);
        }
}