/************************************************************************************************************************************
    Author       :   Mikolaj Juras
    Description  :   This class should contain method for Api user Susie Romero
    LastModifedBy:   Ashish Sharma
    Issue        :   ST-9185
----------------------------------------------------------------------------------------------------------------------------------   
**************************************************************************************************************************************/
public with sharing class ApiUsersUtils {                             
    @TestVisible
    private static UserSelector userSelector = new UserSelector();
    
    public static User apiUser {
        get {
            if (apiUser == null) {
                apiUser = UserUtility.getUserById(apiUserId);
                if (apiUser == null) {
                    throw new ApiUserUtilException('ApiUsersUtils.apiUser User not found with Id: ' + apiUserId);
                }                
            }
            return apiUser;
        }
        private set;
    }

    public static Id apiUserId {
        get {
            if (apiUserId == null) {
                apiUserId = userSelector.getUsersByProfileId(Validation_Rule_Restriction__mdt.getInstance('Integration_Profile').Salesforce_Id__c)[0].Id;
                if (apiUserId == null) {
                    throw new ApiUserUtilException('ApiUsersUtils.apiUserId User not found in Validation_Rule_Restriction__mdt - Integration_Profile');
                }
            }
            return apiUserId;
        }
        private set;
    }

    public static Id apiUserContactId {
        get {
            if(apiUserContactId == null) {
                String apiUserEmail = !Test.isRunningTest() ? apiUser.Email.substringBefore('.invalid') : apiUser.Email;
                apiUserContactId = [SELECT Id FROM Contact WHERE Email = :apiUserEmail]?.Id;
            }
            return apiUserContactId;
        }
        private set;
    }

    public static Boolean isUserAnApiUser(Id userId) {
        return userId == apiUserId;
    }
    
    public ApiUsersUtils(){}
    public class ApiUserUtilException extends Exception{}
}