/************************************************************************************************************************************
Author      :   Salesforce
Description :   This class is a utility class for Salesforce Scheduler which will be invoked form Flows.
----------------------------------------------------------------------------------------------------------------------------------
VERSION     DATE                AUTHOR                DETAIL
1           1 Sep 2021          Salesforce            Initial Developement
**************************************************************************************************************************************/
global with sharing class SalesforceSchedulerUtility {
    /**
     * This method is invoked from Flows (Book a Tour Flows) to retieve and return the worktype Id to the flow
     */
    @InvocableMethod(label='Get Building WorkType' description='This action returns Building Work Type ID based on Building Id and Tour Format')
    public static List<FlowResponseWrapper> getBuildingWorkType(List<FlowRequestWrapper> flowRequests) {
        FlowRequestWrapper sflowRequest = flowRequests[0];
        FlowResponseWrapper flowResponse = new FlowResponseWrapper();
        flowResponse.workTypeId = getBuildingTourFormatWorkTypeId(sflowRequest.buildingId, sflowRequest.tourFormat);
        return new List<FlowResponseWrapper> {flowResponse};
    }

    public static String getBuildingTourFormatWorkTypeId(String buildingId, String tourFormat) {
        String workTypeId;
        for (WorkType workTypeRecord : [SELECT Id, Name, Parent_Id__c, Next_Day_Touring_Cutoff__c 
                                       FROM WorkType 
                                       WHERE Building_Id__c =: buildingId 
                                           AND Tour_Format__c =: tourFormat
                                       ORDER BY Next_Day_Touring_Cutoff__c DESC]) {  
            if (String.isNotBlank(workTypeRecord.Next_Day_Touring_Cutoff__c)) { 
                DateTime currentTime = DateTime.newInstanceGMT(System.now().year(), System.now().month(), System.now().day(), System.now().hour() , System.now().minute() , System.now().second());
                if(currentTime > convert12To24HourTime(workTypeRecord.Next_Day_Touring_Cutoff__c)) {
                    workTypeId = workTypeRecord.Id;
                    break;
                } else {
                    continue;
                }
            } else {
                workTypeId = workTypeRecord.Id;
            }
        }
        return workTypeId;
    }

    private static DateTime convert12To24HourTime(String timeString) {
        String regex = '(\\d{1,2}):(\\d{1,2})([PA]M)';
        Pattern p = Pattern.compile( regex );
        Matcher m = p.matcher( timeString );
        if ( m.matches() ){
            Integer Hours = Integer.valueOf( m.group(1) )
                , Minutes = Integer.valueOf( m.group(2) )
                , Seconds = 0
                , PmShift = m.group(3) == 'PM' ? 12 : 0;
           
            return DateTime.newInstanceGMT(System.now().year(), System.now().month(), System.now().day(), Hours + PmShift , Minutes , Seconds);
        }
        return null;
    }

    global class FlowRequestWrapper {
        @InvocableVariable
        global String buildingId;

        @InvocableVariable
        global String tourFormat;
    }

    global class FlowResponseWrapper {
        @InvocableVariable
        global String workTypeId;
    }
}