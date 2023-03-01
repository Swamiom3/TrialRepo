/************************************************************************************************************************************
Author      :   Salesforce
Description :   This class contain all aura methods related to View and Select Term Based Discounts.
----------------------------------------------------------------------------------------------------------------------------------
VERSION     DATE                AUTHOR                  DETAIL
1           10 Jun 2021         Salesforce            Initial Developement
**************************************************************************************************************************************/
public class IMSInvSearchController{
    @AuraEnabled
    public static String loadIFrameURL(String buildingId){
        //MM TODO: fix url for production!
        //why buildingId is passed, but not used?
        String url = 'https://spacestation-staging.wework.com/#/locations/inventory/search';
        return url;
    }
}