/************************************************************************************************************************************
    Author      :   Samadhan kadam	
    Description :  	This class having a logic to update Cleansed Company Name and Cleansed Unomy Company Name.				 	
					Note: This class will be coverd by "AccountUpdateMarketTrHTest" test class.
	Issue No    : 	-
    History		:	
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION		DATE				AUTHOR				ISSUE NO		DETAIL
    1           17 Jan 2018      	Krishana Tupe	    ST-1246         Initial Developement 
	2			05 Oct 2020			Krishana Tupe		ST-3174			Code Optimization and Consolidated with new trigger structure
**************************************************************************************************************************************/
public inherited sharing class AccountUpdateCleansedNameTrH extends SObjectTriggerHandler { 
    private  static MetadataSetting__mdt accountHierarchySuffixMDTSetting = Settings.getMetadataSettingByDevName('Account_Hierarchy_Naming_Convention');
    @TestVisible
    private List<Account> newAccounts;
    @TestVisible
    private Map<Id, Account> oldAccountsMap;
    
    @TestVisible 
    public AccountUpdateCleansedNameTrH(){
        this((List<Account>) Trigger.new, (Map<Id, Account>) Trigger.oldMap);
    }
    
    @TestVisible
    private AccountUpdateCleansedNameTrH(List<Account> newAccounts, Map<Id, Account> oldAccountsMap){
        this.newAccounts = newAccounts; 
        this.oldAccountsMap = oldAccountsMap;
    }
    
    public override void beforeInsert(){
        updateCleansedNameAndOverrideAccountFields();
    }
    
    public override void beforeUpdate(){
        updateCleansedNameAndOverrideAccountFields();
    }
    
    private void updateCleansedNameAndOverrideAccountFields(){
        for(Account newAccount : newAccounts){
            if(String.isNotBlank(newAccount.Name)){
                newAccount.Cleansed_Account_Name__c = OrganizationHelper.getCleansedName(newAccount.Name);
            }
            if(String.isNotBlank(newAccount.Unomy_Company_Name_Formula__c)){
                newAccount.Cleansed_Unomy_Company_Name__c = OrganizationHelper.getCleansedName(newAccount.Unomy_Company_Name_Formula__c);
            }
            overrideAccountFTE(newAccount);
            overrideAccountAnnualRevenue(newAccount);
            overrideAccountWebsite(newAccount);
        }
    }
    
    private void overrideAccountFTE(Account newAccount){
        if(newAccount.Unomy_Company_Size_Formula__c == null || newAccount.Number_of_Full_Time_Employees__c != null){
            return; 
        }        
        newAccount.Number_of_Full_Time_Employees__c = newAccount.Unomy_Company_Size_Formula__c;
    }
    
    private void overrideAccountAnnualRevenue(Account newAccount){
        if(newAccount.Unomy_Estimated_Revenue_Formula__c == null || newAccount.AnnualRevenue != null){
            return; 
        }        
        newAccount.AnnualRevenue = newAccount.Unomy_Estimated_Revenue_Formula__c;
    }
    
    private void overrideAccountWebsite(Account newAccount){
        if(String.isBlank(newAccount.Unomy_Company_Website_Formula__c) || String.isNotBlank(newAccount.Website)){
            return; 
        }        
        newAccount.Website = newAccount.Unomy_Company_Website_Formula__c;
    }
}