/************************************************************************************************************************************
    Author      :   Mayuresh Ghodke	
    Description :   This class is used to set primary member of Account. 
    First created contact under the account will be populated as primary contact for that account.
    Issue No    : 	-
    History		:	
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION		DATE				AUTHOR				ISSUE NO		DETAIL
    1           05 July 2016      	Mayuresh Ghodke	             		Initial Developement 
    2			05 Oct 2020			Krishana Tupe		ST-3174			Code Optimization and Consolidated with new trigger structure
**************************************************************************************************************************************/
public without sharing class AccountPreventDuplicateOrgNameTrH extends SObjectTriggerHandler{  
    private static final String DUPLICATE_ORG_NAME_ERROR_MSG = ' Organization already exists with the same name';
    private static final String ORG_ACCOUNT_TYPE = 'Org';
    @TestVisible
    private List<Account> newAccounts;
    @TestVisible
    private Map<Id, Account> oldAccountsMap;
    @TestVisible
    private AccountSelector accountSelector = new AccountSelector();
    
    @TestVisible 
    public AccountPreventDuplicateOrgNameTrH(){
        this((List<Account>) Trigger.new, (Map<Id, Account>) Trigger.oldMap);
    }
    
    @TestVisible
    private AccountPreventDuplicateOrgNameTrH(List<Account> newAccounts, Map<Id, Account> oldAccountsMap){
        this.newAccounts = newAccounts;
        this.oldAccountsMap = oldAccountsMap;            
    }
    
    public override void beforeInsert(){
        preventDuplicateOrgName();
    }
    
    public override void beforeUpdate(){
        preventDuplicateOrgName();
    }
    
    private void preventDuplicateOrgName(){
        Map<String, Account> newOrgAccountByName = new Map<String, Account> ();       
        Boolean isInsert = (oldAccountsMap == null || oldAccountsMap.isEmpty());        
        for(Account newAccount : newAccounts ){
            if(String.isBlank(newAccount.Name) || newAccount.Account_Type__c != ORG_ACCOUNT_TYPE){
                continue;
            }
            String newAccountName = newAccount.Name.toLowerCase();
            if(!FeatureManagement.checkPermission('Validation_Bypass_User_Integration') && 
               isDuplicateOrgAccountByName(newAccount, isInsert, newAccountName)){
                if(newOrgAccountByName.containsKey(newAccountName)){
                    newAccount.Name.addError(newAccount.Name + DUPLICATE_ORG_NAME_ERROR_MSG);
                }else{
                    newOrgAccountByName.put(newAccountName, newAccount);
                }
            }
        }
        if(newOrgAccountByName.isEmpty()){
            return;
        }        
        for (Account existingAccount : accountSelector.getAccountsByNameAndAccType(newOrgAccountByName.keySet(), ORG_ACCOUNT_TYPE)) {
            String existingAccountName = existingAccount.Name.toLowerCase();          
            Account newAccount = newOrgAccountByName.get(existingAccountName);
            if(!FeatureManagement.checkPermission('Validation_Bypass_User_Integration')){
                newAccount.Name.addError(newAccount.Name + DUPLICATE_ORG_NAME_ERROR_MSG);
            }
        }
    }   
    
    private Boolean isDuplicateOrgAccountByName(Account newAccount, Boolean isInsert, String newAccountName){
        if(isInsert){
            return true;  
        }
        Account oldAccount = oldAccountsMap.get(newAccount.Id);
        return (newAccountName != oldAccount.Name.toLowerCase() || oldAccount.Account_Type__c != 'Org');    
    }
}