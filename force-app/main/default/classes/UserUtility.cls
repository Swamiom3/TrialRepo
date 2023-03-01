/*********************************************************************************************************
    Author        :  Rohit Nimase
    Description   :  Contains User related methods to get data.
    Issue No.     :  ST-8836
    History       :
-----------------------------------------------------------------------------------------------------------
    VERSION        DATE            AUTHOR             DETAIL
    1              17-Sept-2021    Rohit Nimase       Optimize/Cleanup Setting Class Methods
**********************************************************************************************************/
public class UserUtility {

    private static Map<String, Id> validationRuleDeveloperNameToProfileId;
    private static Set<Id> validationRuleAdminProfileIds;
    public static Map<Id, User> idToUser = new Map<Id, User>();
	public static Map<String, User> nameToUser = new Map<String, User>();
	public static Map<String, User> emailToUser = new Map<String, User>();
    @TestVisible
    private static UserSelector userSelector = new UserSelector();
    
    public static Boolean isSystemAdministrator {
        get {
            if (isSystemAdministrator == null) {
                fetchValidationRules();
                isSystemAdministrator = validationRuleAdminProfileIds.contains(UserInfo.getProfileId());
            }
            return isSystemAdministrator;
        }
        private set;
    }

    public static Boolean isMuleSoftUser {
        get {
            if (isMuleSoftUser == null) {
                isMuleSoftUser = !([SELECT Salesforce_Id__c FROM Validation_Rule_Restriction__mdt 
                                        WHERE Salesforce_Id__c = :UserInfo.getUserId()]).isEmpty();
            }
            return isMuleSoftUser;
        }
        private set;
    }
    
    public static Id getValidationRuleRestrictionSalesforceId(String developerName){
        fetchValidationRules();
        return getValidationRuleIdByDeveloperName(developerName);
    }

    public static Id getValidationRuleIdByDeveloperName(String developerName){
        return validationRuleDeveloperNameToProfileId.get(developerName);
    }
    
    public static void fetchValidationRules(){
        if(validationRuleDeveloperNameToProfileId != null) {
           return;
        }
        validationRuleDeveloperNameToProfileId = new Map<String, Id>();
        validationRuleAdminProfileIds = new Set<Id>();
        List<String> adminProfileNames = new List<String> {GlobalConstants.SYSTEM_ADMINISTRATOR_PROFILE_NAME, GlobalConstants.WEWORK_SYSTEM_ADMINISTRATOR_PROFILE_NAME };
        for (Validation_Rule_Restriction__mdt validationRuleRecord : [SELECT Salesforce_Id__c, DeveloperName, Label FROM Validation_Rule_Restriction__mdt]) {
            validationRuleDeveloperNameToProfileId.put(validationRuleRecord.DeveloperName, validationRuleRecord.Salesforce_Id__c);
            if(adminProfileNames.contains(validationRuleRecord.Label)) {
                validationRuleAdminProfileIds.add(validationRuleRecord.Salesforce_Id__c);
            }
        }
    }
    
    /************************************************************************************************************************************
        Author              :   Shobhit Gahlot
        Description         :   This method is used to get salesforce Id from Salesforce_Id__c of Validation_Rule_Restriction__mdt metadata.
        Created Date  		:   June 19 2020			 
    **************************************************************************************************************************************/    
	public static Id getApiUserId(){
        return getValidationRuleRestrictionSalesforceId('Susie_Romero_API_User');
    } 
    
    public static void fetchUsers(){
        fetchAllUsers();
    }
    
    /*****************************************************************************************************************************************
        Author              :   Pragalbha Mahajan
        Description         :   This method is used to fetch all(Active/Inactive) Users.
        Created Date        :   01 October 2018
        Issue No            :   ST-2795
    ******************************************************************************************************************************************/
    public static List<User> fetchAllUsers(){
        if(idToUser == null || idToUser.isEmpty()){
            for(User u : userSelector.getAllActiveUsers()) {
                idToUser.put(u.Id, u);
                nameToUser.put(u.Name, u);
                emailToUser.put(u.Email, u);
            }
        }
        return idToUser?.values();
    }
    
    public static User getUserById(Id userId){        
        fetchUsers();      
        return idToUser.containsKey(userId) ? idToUser.get(userId) : null;
    }
    
    public static User getUserByName(String userName){
        fetchUsers();
        return nameToUser.containsKey(userName) ? nameToUser.get(userName) : null;
    }
    
    public static User getUserByEmail(String userEmail){
        fetchUsers();
        return emailToUser.containsKey(userEmail) ? emailToUser.get(userEmail) : null;
    }
    
    public static Boolean getUserActive(Id userId){
        fetchUsers();
        if(String.isNotBlank(userId) && (String.valueOf(userId).toLowerCase().startsWith('00g') || idToUser.containsKey(userId))){
            return true;
        }else{
            return false;
        }
    }
    
    public static List<User> getAllUsers(){
        fetchUsers();
        return idToUser?.values();
    }
    
    public static void refreshUsers() {
        idToUser = new Map<Id, User>();
        nameToUser = new Map<String, User>();
        emailToUser = new Map<String, User>();
        fetchAllUsers();
    }
}