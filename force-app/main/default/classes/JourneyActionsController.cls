/************************************************************************************************************************************
    Author      :   Jake Flynt
    Description :   

    History:
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION     DATE                AUTHOR                  DETAIL
    1           20 Sept 2019    		Jake Flynt            	Initial Developement
**************************************************************************************************************************************/
public class JourneyActionsController  {
    
    @AuraEnabled
    public static List<String> getNotSalesReadyReasons() {
        List<String> lstReasons = (List<String>)JSON.deserialize(Settings.getMetadataSettingByDevName('NotSalesReadyReasons').Data__c, List<String>.class);
        Set<String> setReasons = new Set<String>(lstReasons);
        lstReasons = new List<String>(setReasons);
        return lstReasons;
    }
    
    @AuraEnabled
    public static void updateJourney(Id recordId, String status, String notSalesReadyReason){
        Journey__c journey = new Journey__c(Id = recordId, Status__c = status, Deferred_Reason__c = notSalesReadyReason);
        try {
            update journey;
        } catch (Exception ex) {
            ApexDebugLog.logException(ex, 'journeyId==>'+recordId, 'JourneyActionsController','updateJourney');
            System.debug('Error updating journey');
        }
    }
    
    @AuraEnabled
    public static Id getListViewByName(String name, String sObjectType) {
        List<ListView> lstListViews = [SELECT Id FROM ListView WHERE Name =: name AND sObjectType =: sObjectType LIMIT 1];
        return !lstListViews.isEmpty() ? lstListViews[0].Id : NULL;        
    }
    
    @AuraEnabled
    public static String getPrimaryMemberName(Id primaryMemberId){
        if(String.isNotBlank(primaryMemberId)){
            String sobjectName = String.valueOf(primaryMemberId.getSobjectType());    
            if(String.isNotBlank(sobjectName)){
                String strQuery = 'SELECT Id, Name FROM '+sobjectName+ ' WHERE Id =: primaryMemberId LIMIT 1';
                List<sobject> lstRecords = Database.query(strQuery); 
                return !lstRecords.isEmpty() ? (String)lstRecords[0].get('Name') : NULL;
            } 
        }
        return NULL;
    }
    
}