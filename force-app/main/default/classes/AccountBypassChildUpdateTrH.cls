/************************************************************************************************************************************
    Author      :   Krishana Tupe	
    Description :   This Trigger is used in before update for by passing the child owner change trigger depending on the threshold 
					value set in the setting.
	Issue No    : 	-
    History:
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION     DATE                AUTHOR              Issue    		DETAIL
    1           18 Feb 2019    		Shobhit Gahlot      -    			Initial Developement
	2			30 Sept 2020		Krishana Tupe		ST-3174			Code Optimization and Consolidated with new trigger structure
**************************************************************************************************************************************/
public without sharing class AccountBypassChildUpdateTrH extends SObjectTriggerHandler{

    @TestVisible
    private List<Account> newAccounts;
    @TestVisible
    private Map<Id, Account> newAccountsMap;
    @TestVisible
    private Map<Id, Account> oldAccountsMap;
    
    @TestVisible 
    public AccountBypassChildUpdateTrH(){
        this((List<Account>) Trigger.new, (Map<Id, Account>) Trigger.newMap, (Map<Id, Account>) Trigger.oldMap);
    }
    
    @TestVisible
    private AccountBypassChildUpdateTrH(List<Account> newAccounts, Map<Id, Account> newAccountsMap, Map<Id, Account> oldAccountsMap){
        this.newAccounts = newAccounts; 
        this.newAccountsMap = newAccountsMap;
        this.oldAccountsMap = oldAccountsMap;            
    }
    
    public override void beforeUpdate(){        
        handleAccountChildRecordsUpdate(); 
    }
    
    private void handleAccountChildRecordsUpdate() {
        MetadataDrivenTriggerHandler.clearLoopCount('AccountBypassChildUpdateTrH');
    }
}