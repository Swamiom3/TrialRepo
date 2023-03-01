/************************************************************************************************************************************
Author 		: 	Pragalbha Mahajan
Description : 	This class is an helper class related to account assignment.
History		:
----------------------------------------------------------------------------------------------------------------------------------
VERSION		DATE				AUTHOR					DETAIL
1			30 Jan 2019	        Pragalbha Mahajan     	Initial Development	 
**************************************************************************************************************************************/

public class AccountAssignmentHelper {
    public class AccountAssignmentHelperException extends Exception{}
    
    public static Map<String, Schema.SObjectType> globalDescribe;
    public static Map<String, Set<String>> mapAccountMergeSetting = new Map<String, Set<String>>();
    public static List<Map<String,String>> lstRecordTypeWithCompanySize = new List<Map<String,String>>();
    public static Map<String, String> mapAPIUserSetting = new Map<String, String>();
    
    /************************************************************************************************************************************
        Author 				: 	Pragalbha Mahajan
        Description 		: 	This method is used to get getGlobalDescribe.
        Issue No.			:	ST-3391
        Created Date		:	30 Jan 2019
    **************************************************************************************************************************************/
    public static Map<String, Schema.SObjectType> getGlobalDescribe(){
        if(globalDescribe == null){
            globalDescribe = Schema.getGlobalDescribe();
        }
        return globalDescribe;
    }
    
    /************************************************************************************************************************************
        Author 				: 	Pragalbha Mahajan
        Description 		: 	This method is used to get record type name from record type Id.
        Issue No.			:	ST-3391
        Created Date		:	30 Jan 2019
    **************************************************************************************************************************************/
    public static String getRecordTypeNameById(String objectName, Id recordTypeId){
        getGlobalDescribe();
        if(String.isNotBlank(objectName) && String.isNotBlank(recordTypeId)){
           return globalDescribe.get(objectName).getDescribe().getRecordTypeInfosById().get(recordTypeId).getName(); 
        }
        return NULL;
    }
    
    /************************************************************************************************************************************
        Author 				: 	Pragalbha Mahajan
        Description 		: 	This method is used to check change account owner conditions.
        Issue No.			:	ST-3391
        Created Date		:	30 Jan 2019
    **************************************************************************************************************************************/
    public static boolean checkValidUserForAssignment(Id userId){
        if(String.isNotBlank(userId) && (!UserUtility.getUserActive(userId) || isApiUser('UserId', userId) || isValidProfileAndUserForAssignment(userId))){
            return true;
        }
        return false;
    }
    /************************************************************************************************************************************
        Author 				: 	Pragalbha Mahajan
        Description 		: 	This method is used to get check whether user is valid for assignment or not.
        Issue No.			:	ST-3391
        Created Date		:	30 Jan 2019
    **************************************************************************************************************************************/
    public static boolean isValidProfileAndUserForAssignment(String userId){
        if(String.isNotBlank(userId)){
            if(!UserUtility.getUserActive(userId)){
                return true;
            }
            if(mapAccountMergeSetting == NULL || mapAccountMergeSetting.isEmpty()){
                Sales_Console_Setting__mdt accountMergeSetting = SalesConsoleSettings.get('AccountMergeSettings');
                if(accountMergeSetting != NULL && String.isNotBlank(accountMergeSetting.Data__c)){
                    mapAccountMergeSetting = (Map<String,Set<String>>)JSON.deserialize(Settings.get('AccountMergeSettings').Data__c.toLowerCase(), Map<String,Set<String>>.class);
                }
            }
            User userRecord = UserUtility.getUserById(userId);
            if (mapAccountMergeSetting != null
                && ((mapAccountMergeSetting.get('owner') != null
                    && (mapAccountMergeSetting.get('owner').contains(userId.toLowerCase())
                       || mapAccountMergeSetting.get('owner').contains(userId.toLowerCase().substring(0, 15))))
                    || (mapAccountMergeSetting.get('profiles') != null
                        && mapAccountMergeSetting.get('profiles').contains(userRecord.Profile.Name.toLowerCase())))) {
                return true;
            }
        }
        return false;
    }
    
    /************************************************************************************************************************************
        Author 				: 	Pragalbha Mahajan
        Description 		: 	This method is used to check user is API user or not..
        Issue No.			:	ST-3391
        Created Date		:	30 Jan 2019
    **************************************************************************************************************************************/
    public static boolean isApiUser(string dataType, Id userId){
        if(getApiUserId(dataType) == userId){
            return true;
        }
        return false;
    }
    
    /************************************************************************************************************************************
        Author 				: 	Pragalbha Mahajan
        Description 		: 	This method is used to check user is API user or not..
        Issue No.			:	ST-3391
        Created Date		:	30 Jan 2019
    **************************************************************************************************************************************/
    public static Id getApiUserId(string dataType){
        if(mapAPIUserSetting == NULL || mapAPIUserSetting.isEmpty()){
            Sales_Console_Setting__mdt apiUserSetting = SalesConsoleSettings.get('APIUserContactInfo');
            if(apiUserSetting != null && String.isNotBlank(apiUserSetting.Data__c)){
                mapAPIUserSetting = (Map<String, String>)JSON.deserialize(apiUserSetting.Data__c, Map<String, String>.class);
            }
        }        
        if(mapAPIUserSetting != null && mapAPIUserSetting.containsKey(dataType)){
            return mapAPIUserSetting.get(dataType);
        }
        return NULL;
    }
    /************************************************************************************************************************************
    Author 				: 	Pragalbha Mahajan
    Description 		: 	This method is used for record type change according to ROE assignment.
    Issue No.			:	ST-3391
	Created Date		:	29 Jan 2019
    **************************************************************************************************************************************/
    public static String getRecordTypeIdFromCompanySize(Account objAccount){
        Integer companySize = getCompanySizeFromAccount(objAccount);
        String recordTypeId = getRecordTypeOfAccountUsingCompanySize((companySize != null && companySize > 0) ? companySize : 1); 
        return recordTypeId;
    }
    
    
    /************************************************************************************************************************************
        Author 				: 	Pragalbha Mahajan
        Description 		: 	This method is used to get company size from account.
        Issue No.			:	ST-3391
        Created Date		:	30 Jan 2019
    **************************************************************************************************************************************/
    public static Integer getCompanySizeFromAccount(Account objAccount){
        Integer companySize;                        
        if(objAccount.Unomy_Company_Size_Formula__c != NULL){
            companySize = getLowerSize(String.valueOf(objAccount.Unomy_Company_Size_Formula__c));
        }else if(String.isNotBlank(String.valueOf(objAccount.Number_of_Full_Time_Employees__c))){
            companySize = Integer.valueOf(objAccount.Number_of_Full_Time_Employees__c);
        }
        return companySize;
    }
    
    /************************************************************************************************************************************
        Author 				: 	Pragalbha Mahajan
        Description 		: 	This method is used to get record type of account using company size.
        Issue No.			:	ST-3391
        Created Date		:	30 Jan 2019
    **************************************************************************************************************************************/
    public static Id getRecordTypeOfAccountUsingCompanySize(Integer CompanySize){
        if(lstRecordTypeWithCompanySize == NULL || lstRecordTypeWithCompanySize.isEmpty()){
            Sales_Console_Setting__mdt accountRecordTypeSetting = SalesConsoleSettings.get('AccountRecordTypeSettings');
            if(accountRecordTypeSetting != NUll && String.isNotBlank(accountRecordTypeSetting.Data__c)){
                lstRecordTypeWithCompanySize = (List<Map<String,String>>)JSON.deserialize(Settings.get('AccountRecordTypeSettings').Data__c, List<Map<String,String>>.class);
            }
        }
        String recordTypeId;
        if(lstRecordTypeWithCompanySize != NULL){
            for(Map<String,String> mapRecordType : lstRecordTypeWithCompanySize){
                if(companySize >= getLowerSize(mapRecordType.get('Size'))){
                    recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(mapRecordType.get('RecordType')).getRecordTypeId();
                }
            }
        }
        return String.isNotBlank(recordTypeId) ? recordTypeId : Schema.SObjectType.Account.getRecordTypeInfosByName().get('Consumer').getRecordTypeId();
    }
    
    /************************************************************************************************************************************
        Author 				: 	Pragalbha Mahajan
        Description 		: 	This method is used to get lower size from range.
        Issue No.			:	ST-3391
        Created Date		:	30 Jan 2019
    **************************************************************************************************************************************/
    public static Integer getLowerSize(String size){
        try{
            Integer lowerSize;
            size = size.replaceAll('(,|desks|desk|<)','');
            size = size.deleteWhitespace();
            size = size.split('(-|\\+)')[0];
            lowerSize = Integer.valueOf(size);
            return lowerSize;    
        }catch(Exception pEx){
            ApexDebugLog.logException(pEx,size, 'AccountAssignmentHelper', 'getLowerSize');
            return NULL;
        }
    }
}