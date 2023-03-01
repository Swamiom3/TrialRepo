/*************************************************************************************************************************************
    Author      :   Rashad Saeed
    Description :   Class for set and submit the Rollbar request.
    --------------------------------------------------------------------------------------------------------------------------------------
    VERSION    DATE            AUTHOR            DETAIL
    1          31 Dec, 2018    Rashad Saeed      Initial Deployment - WeWork SF-Rollbar Integration Google Doc
    2          29 Nov, 2021    Pawel Biszczak    Commented out code as a part of ST-9386, waiting for Rollbar integration
**************************************************************************************************************************************/
public class Rollbar {

    public static HttpResponse submitItem(RollbarItem item, String project) {
        String itemMessage = setRollbarMessage(item, project);
        APIConnection srv = new APIConnection(project);
        HttpResponse resp = srv.sendRequest(itemMessage);
        return resp; 
    }

    private static String setRollbarMessage(RollbarItem item, String project) {
        String API_KEY = Integration_Data__mdt.getInstance(project).ApiKey__c;
        String organizationEnvironment;

        if ([ SELECT IsSandbox
              FROM Organization ].IsSandbox) {
            organizationEnvironment = 'orgc-development';
        } else {
            organizationEnvironment = 'orgc-production';
        }
        Map<String, Object> messageMap = item.buildRollbarItemMessage(API_KEY, organizationEnvironment);
        return JSON.serialize(messageMap);
    }
}