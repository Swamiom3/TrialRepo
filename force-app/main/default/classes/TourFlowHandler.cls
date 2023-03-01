/**********************************************************************************************************
Author        :  Salesforce
Description   :  This class is used in the Flows to get object name based on recordId.
-----------------------------------------------------------------------------------------------------------
VERSION        DATE            AUTHOR           DETAIL
1              15-Sep-2021     Salesforce       
**********************************************************************************************************/
global class TourFlowHandler {
    @InvocableMethod
    public static List<String> returnObjectName(List<String> recordIdStrings){
        if(recordIdStrings==null || recordIdStrings.isEmpty()){
            return null;
        }
        Id recordId = Id.valueOf(recordIdStrings[0]);
        return new List<String> {recordId.getSobjectType().getDescribe().getName()};
    }
}