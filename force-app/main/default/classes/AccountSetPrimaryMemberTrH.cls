/************************************************************************************************************************************
    Author      :   Mayuresh Ghodke	
    Description :   This method is used to set primary member of Account. 
    				First created contact under the account will be populated as primary contact for that account.
    Issue No    : 	-
    History		:	
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION		DATE				AUTHOR				ISSUE NO		DETAIL
    1           05 July 2016      	Mayuresh Ghodke	             		Initial Developement 
    2			01 Oct 2020			Krishana Tupe		ST-3174			Code Optimization and Consolidated with new trigger structure
**************************************************************************************************************************************/
public inherited sharing class AccountSetPrimaryMemberTrH extends SObjectTriggerHandler{  
    
    @TestVisible
    private List<Account> newAccounts;
    @TestVisible
    Map<Id, Account> newAccountsMap;
    @TestVisible
    private Map<Id, Account> oldAccountsMap;
    
    @TestVisible 
    public AccountSetPrimaryMemberTrH(){
        this((List<Account>) Trigger.new, (Map<Id, Account>) Trigger.newMap, (Map<Id, Account>) Trigger.oldMap);
    }
    
    @TestVisible
    private AccountSetPrimaryMemberTrH(List<Account> newAccounts, Map<Id, Account> newAccountsMap, Map<Id, Account> oldAccountsMap){
        this.newAccounts = newAccounts;
        this.newAccountsMap = newAccountsMap;
        this.oldAccountsMap = oldAccountsMap;            
    }
    
    public override void beforeUpdate(){
        setAccountPrimaryMember();
    }
    
    private  void setAccountPrimaryMember(){
        Set<Id> accsToProcessIds = new Set<Id>();
        for(Account newAccountRec : newAccounts){
            if(String.isNotBlank(newAccountRec.Primary_Member__c)){
                continue;
            }
            accsToProcessIds.add(newAccountRec.Id);
        }
        if(accsToProcessIds.isEmpty()){
            return;   
        }
        //Get Accounts and first contacts   
        for(Account accountRec : [SELECT Id, (SELECT Id FROM Contacts ORDER BY CreatedDate LIMIT 1) FROM Account WHERE Id IN :accsToProcessIds]){
            if(accountRec.Contacts.isEmpty()){
                continue;
            }                   
            Account newAccountRec = newAccountsMap.get(accountRec.Id);
            newAccountRec.Primary_Member__c = accountRec.Contacts[0].Id;
        }
    }
}