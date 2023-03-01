/************************************************************************************************************************************
    Author      :   Prashant Mane
    Description :   This class contain all aura methods related to CreateNewSalesAccount Component.
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION     DATE                AUTHOR                  DETAIL
    1           10 Jan 2019         Prashant Mane           Initial Developement
**************************************************************************************************************************************/
global without sharing class SalesAccountController {
    public static Boolean isInvoker = false;
    public static Savepoint sp {get;set;}
    static {
        isInvoker = ApexDebugLog.registerRootInvoker(ApexDebugLog.InvokerType.AURA, 'SalesAccountController' + 'getsObjectPrefix', ApexDebugLog.InvokerType.AURA);
    }
    @AuraEnabled
    public static DatabaseResult isValidForSalesAccount(String recordId){
        try{
            ValidForSalesAccountResult objValidForSalesAccountResult = new ValidForSalesAccountResult();
            objValidForSalesAccountResult.isValid = true;
            Account account = new AccountSelector().getSalesAccountsById(new Set<Id>{recordId})?.get(0);
            if (account.Account_Type__c != null && (account.Account_Type__c == GlobalConstants.ACCOUNT_TYPE_ORG || account.Account_Type__c == GlobalConstants.ACCOUNT_TYPE_SALES)) {
                if (account.OwnerId == UserInfo.getUserId()) {
                    objValidForSalesAccountResult.isValid = true;
                } else if (OrganizationHelper.getUltimateParents(new Set<Id>{account.Id}, new List<String>{'OwnerId'}).get(account.Id).OwnerId == UserInfo.getUserId()){
                    objValidForSalesAccountResult.isValid = true;
                } else {
                    List<CustomPermission> lstCustomPermissions = [SELECT Id, DeveloperName, (SELECT Id, Parent.Name, Parent.Profile.Name FROM SetupEntityAccessItems WHERE Parent.Profile.Id =: UserInfo.getProfileId()) FROM CustomPermission WHERE DeveloperName = 'Can_Create_Sales_Account'];
                    if(lstCustomPermissions != null && lstCustomPermissions.size() > 0 && lstCustomPermissions[0].SetupEntityAccessItems != null && lstCustomPermissions[0].SetupEntityAccessItems.size()>0){
                        objValidForSalesAccountResult.isValid = true;
                    }else{
                        objValidForSalesAccountResult.isValid = false;
                        objValidForSalesAccountResult.errorMessage = 'You can not create Sales Account as you are not the owner of the Account.';
                    }
                }
            }else{
                objValidForSalesAccountResult.isValid = false;
                objValidForSalesAccountResult.errorMessage = 'Sales account can only be created under Org or Sales accounts.';
            }
            if(objValidForSalesAccountResult.isValid){
                return getAccountDetails(recordId, objValidForSalesAccountResult);
            }else{
              return new DatabaseResult(JSON.serialize(objValidForSalesAccountResult));  
            }
            
        }catch(Exception pEx){
            ApexDebugLog.logException(pEx,'AccountId==> '+ recordId, 'SalesAccountController', 'isValidForSalesAccount');
            return new DatabaseResult(pEx);
        }
    }
    
    public static DatabaseResult getAccountDetails(String recordId, ValidForSalesAccountResult objValidForSalesAccountResult ){
        Sales_Console_Setting__mdt objSalesAccountSetting = SalesConsoleSettings.get('SalesAccountSetting');
        Map<String,Object> mapSalesAccountSetting = new Map<String,Object>();
        if(objSalesAccountSetting != null){
            objValidForSalesAccountResult.settingData = objSalesAccountSetting; 
            mapSalesAccountSetting = (Map<String,Object>) JSON.deserializeUntyped(objSalesAccountSetting.Data__c);
            List<String> fieldsToQuery = (List<String>) (JSON.deserialize(JSON.serialize(mapSalesAccountSetting.get('AccountFields')), List<String>.class));
            objValidForSalesAccountResult.lstAccounts = new AccountSelector().getAccountsAndFieldsById(fieldsToQuery, new Set<Id>{recordId});
            return new DatabaseResult(JSON.serialize(objValidForSalesAccountResult));
        }else{
            objValidForSalesAccountResult.isValid = false;
            objValidForSalesAccountResult.errorMessage = 'Something went wrong please contact your system admin.';
            return new DatabaseResult(JSON.serialize(objValidForSalesAccountResult)); 
        }
    }
    

 /****************************************************************************************************************************
    Author              :   Krishana Tupe
    Description         :   This method is used to find ultimate org for Lead record and returns its related sales account records
    Created Date        :   23 July 2018
    Issue No.           :   ST-2669
 *********************************************************************************************************************************/
     
    @AuraEnabled
    public static DatabaseResult getRelatedAccounts(String leadId,String parentId){
        try {
            String ultimateOrgId;
            if (String.isBlank(parentId)) {
                Lead leadRecord = [SELECT Id, FirstName, Email_Domain_Text__c, Interested_in_Number_of_Desks_Min__c, Interested_in_Number_of_Desks__c, LastName, Name, OwnerId, Email_Domain__c, Company, Account__c, Account__r.Account_Type__c, Referrer__c, Cleansed_Unomy_Company_Name__c, Cleansed_Company_Name__c, Email, Unomy_Company_Id_Formula__c, Unomy_Company_Name_Formula__c, LeadSource, Lead_Source_Detail__c, Generate_Journey__c, By_Pass_Journey_Creation_Criteria__c, Building_Interested_In__c, Building_Interested_In__r.City__c,Locations_Interested__c, Number_of_Full_Time_Employees__c FROM  Lead WHERE Id=:leadId];
                ultimateOrgId =  OrganizationHelper.findRelatedOrg(leadRecord);
            } else {
                ultimateOrgId = parentId;
            }
            Map<String,List<Account>> mapAccount = new Map<String,List<Account>>();
            if (String.isNotBlank(ultimateOrgId)) {
                AccountSelector accSel = new AccountSelector();
                List<Account> accounts = accSel.getSalesAccountsById(new Set<Id>{ultimateOrgId});
                if (!accounts.isEmpty()) {
                    mapAccount.put('OrgAccount', accounts);
                    List<Account> salesAccounts;
                    if(String.isNotBlank(accounts[0].Parent_Org_Id__c)) {
                        salesAccounts = accSel.getAccountsByParentIdsAndIdAndSalesOrgType(String.valueOf(accounts[0].Parent_Org_Id__c).substring(0, 15), accounts[0].Parent_Org_Id__c, accounts[0].Parent_Org_Id__c);
                    }else if(accounts[0].Account_Type__c =='Org'){
                        salesAccounts = accSel.getAccountsByParentIdsAndSalesOrgType(String.valueOf(accounts[0].Id).substring(0, 15), accounts[0].Id);
                    }
                    mapAccount.put('SalesAccounts', salesAccounts);
                    return new DatabaseResult(mapAccount);
                } else {
                    return null;
                }
            }
            return null;
        } catch(Exception pEx) {
            ApexDebugLog.logException(pEx,'LeadId==>'+leadId+' AccountId==>'+parentId, 'SalesAccountController', 'getRelatedAccounts');
            return new DatabaseResult(pEx);
        }
    }

    @AuraEnabled
    public static DatabaseResult isValisUserToShowAccountSelector(){
        try{
            Boolean showPage = false;
            User loggedInUser = UserUtility.getUserById(UserInfo.getUserId());
            Sales_Console_Setting__mdt accountSelectorSettings = SalesConsoleSettings.get('AccountSelectorSettings');
            Map<String,set<String>> mapExcludedProfiles;
            if(accountSelectorSettings != null){
                mapExcludedProfiles  = (Map<String,set<String>>)JSON.deserialize(accountSelectorSettings.Data__c.toLowerCase(), Map<String,set<String>>.class);
                if(mapExcludedProfiles != null && !mapExcludedProfiles.get('profiles').contains(String.valueOf(loggedInUser.Profile.Name).toLowerCase())){
                    showPage = true;
                }
            }
            return new DatabaseResult(showPage);
        }catch(Exception pEx){
            ApexDebugLog.logException(pEx,'', 'SalesAccountController', 'isValisUserToShowAccountSelector');
            return new DatabaseResult(pEx);
        }
    }

    public class ValidForSalesAccountResult {
        public Boolean isValid {get;set;}
        public String errorMessage {get;set;}
        public Sales_Console_Setting__mdt settingData {get;set;}
        public List<Account> lstAccounts {get;set;}
    }
}