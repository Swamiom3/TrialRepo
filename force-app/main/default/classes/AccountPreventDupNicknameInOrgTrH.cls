/************************************************************************************************************************************
    Author      :   Milanjeet Singh
    Description :  	This class is used to avoid Duplicate nickname under perticular org.				 	
    
    Issue No    : 	-
    History		:	
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION		DATE				AUTHOR				ISSUE NO		DETAIL
    1           07 March 2018      	Krishana Tupe	    ST-2080         Initial Developement 
    2			05 Oct 2020			Krishana Tupe		ST-3174			Code Optimization and Consolidated with new trigger structure
**************************************************************************************************************************************/
public inherited sharing class AccountPreventDupNicknameInOrgTrH extends SObjectTriggerHandler { 
    private final static String SALES_ACCOUNT_TYPE = 'Sales';
    @TestVisible
    private List<Account> newAccounts;
    @TestVisible
    private Map<Id, Account> oldAccountsMap;
    @TestVisible
    private Set<String> accountNicknames;
    @TestVisible
    private Map<String, Map<String, Account>> parentOrgIdToNicknameWithAccount;
    @TestVisible
    private Boolean VALIDATION_BYPASS_USER_INTEGRATION = FeatureManagement.checkPermission('Validation_Bypass_User_Integration');
    
    @TestVisible 
    public AccountPreventDupNicknameInOrgTrH(){
        this((List<Account>) Trigger.new, (Map<Id, Account>) Trigger.oldMap);
    }
    
    @TestVisible
    private AccountPreventDupNicknameInOrgTrH(List<Account> newAccounts, Map<Id, Account> oldAccountsMap){
        this.newAccounts = newAccounts; 
        this.oldAccountsMap = oldAccountsMap;
    }
    
    public override void beforeInsert(){
        preventDuplicateNicknameInSameOrgHierarchy();
    }

    public override void beforeUpdate(){
        preventDuplicateNicknameInSameOrgHierarchy();
    }
    @TestVisible
    private void preventDuplicateNicknameInSameOrgHierarchy(){
        accountNicknames = new Set<String>();
        parentOrgIdToNicknameWithAccount = new Map<String, Map<String, Account>>();
        Boolean isInsert = (oldAccountsMap == null || oldAccountsMap.isEmpty());

        for(Account newAccount : newAccounts){            
            String accountType = newAccount.Account_Type__c;            
            if(String.isBlank(accountType) || accountType != 'Sales' || String.isBlank(newAccount.Parent_Org_Id__c)){
                continue;
            }           
            Account oldAccount;
            if(!isInsert){
                oldAccount = oldAccountsMap.get(newAccount.Id);
            }             
            if(String.isBlank(newAccount.Nickname__c)){
                continue;   
            }
            if(isValidToCheckDuplicateNickname(newAccount, oldAccount, isInsert)){
                checkNewInsertionDupNicknameUnderSameOrgHierarchy(newAccount);
            }
        }
        if(parentOrgIdToNicknameWithAccount.isEmpty()){
            return;
        }
        for(Account existingAccount : [ SELECT Id, Nickname__c, Parent_Org_Id__c, ParentId, Parent.ParentId, Parent.Parent.ParentId,
                                               Parent.Parent.Parent.ParentId, Parent.Parent.Parent.Parent.ParentId
                                        FROM Account
                                        WHERE (ParentId IN :parentOrgIdToNicknameWithAccount.keySet()
                                                   OR Parent.ParentId IN :parentOrgIdToNicknameWithAccount.keySet()
                                                   OR Parent.Parent.ParentId IN :parentOrgIdToNicknameWithAccount.keySet()
                                                   OR Parent.Parent.Parent.ParentId IN :parentOrgIdToNicknameWithAccount.keySet()
                                                   OR Parent.Parent.Parent.Parent.ParentId IN :parentOrgIdToNicknameWithAccount.keySet()
                                              )
                                              AND Account_Type__c =:SALES_ACCOUNT_TYPE
                                              AND Nickname__c IN :accountNicknames ]){
                                                   checkExistingDupNicknameUnderSameOrgHierarchy(existingAccount);
                                       }
    }
    @TestVisible
    private void checkNewInsertionDupNicknameUnderSameOrgHierarchy(Account newAccount){
        String accNickName = newAccount.Nickname__c.toLowerCase();
        String accountParentOrgId = newAccount.Parent_Org_Id__c;
        if(parentOrgIdToNicknameWithAccount.containsKey(accountParentOrgId)){
            Map<String, Account> newAccountNicknameWithAccount = parentOrgIdToNicknameWithAccount.get(accountParentOrgId);
            if(!VALIDATION_BYPASS_USER_INTEGRATION &&
               newAccountNicknameWithAccount.keySet().contains(accNickName)){
                newAccount.Nickname__c.addError('Sales Account with same Nickname "'+newAccount.Nickname__c+'" already exists under the organization. Please choose another nickname.');
            }
        }else{
            parentOrgIdToNicknameWithAccount.put(accountParentOrgId, new Map<String, Account>{accNickName => newAccount});
            accountNicknames.add(accNickName);
        }
    }

    @TestVisible
    private Id getParentOrgIdForSingleRecord(Account accountRecord) {
        if(accountRecord.ParentId == null) {
            return accountRecord.Id;
        } else if (accountRecord.Parent.ParentId == null) {
            return accountRecord.ParentId;
        } else if (accountRecord.Parent.Parent.ParentId == null) {
            return accountRecord.Parent.ParentId;
        } else if (accountRecord.Parent.Parent.Parent.ParentId == null) {
            return accountRecord.Parent.Parent.ParentId;
        } else if (accountRecord.Parent.Parent.Parent.Parent.ParentId == null) {
            return accountRecord.Parent.Parent.Parent.ParentId;
        } else {
            return accountRecord.Parent.Parent.Parent.Parent.ParentId;
        }
    }

    @TestVisible
    private void checkExistingDupNicknameUnderSameOrgHierarchy(Account existingAccount){
        if(VALIDATION_BYPASS_USER_INTEGRATION) {
            return;
        }
        String accNickName = existingAccount.Nickname__c.toLowerCase();
        String accountParentOrgId = existingAccount.Parent_Org_Id__c;
        if(String.isBlank(accountParentOrgId)){
            return;
        }
        if(parentOrgIdToNicknameWithAccount.containsKey(accountParentOrgId)){
            Map<String, Account> newAccountNicknameWithAccount = parentOrgIdToNicknameWithAccount.get(accountParentOrgId);
            if(newAccountNicknameWithAccount.keySet().contains(accNickName)){
                Account newAccount = newAccountNicknameWithAccount.get(accNickName);
                newAccount.Nickname__c.addError('Sales Account with same Nickname "'+newAccount.Nickname__c+'" already exists under the organization. Please choose another nickname.');
            }
        }
    }
    @TestVisible
    private Boolean isValidToCheckDuplicateNickname(Account newAccount, Account oldAccount, Boolean isInsert){
        if(isInsert){
            return true;
        }
        return Settings.isChanged(newAccount.Nickname__c, oldAccount.Nickname__c);         
    }
    
}