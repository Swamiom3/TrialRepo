/************************************************************************************************************************************
    Author      :   Nicholas Zozaya
    Description :   This class is used to store opportunity related to the account while account owner gets changed.
    Issue No    :   -
    History     :
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION     DATE                AUTHOR              ISSUE NO        DETAIL
    1           06 Oct 2018         Pragalbha Mahajan   ST-2696         Initial Development 
    2           -                   Chandra Teja        ST-3686         -
    3           05 Oct 2020         Krishana Tupe       ST-3174         Code Optimization and Consolidated with new trigger structure
    4           15 Jan 2021         Liubomyr Mishchykha ST-7552         Refactored query to avoid error
                                                                            "Aggregate query has too many rows for direct assignment"
**************************************************************************************************************************************/
public inherited sharing class AccountStoreRelOppForEmailAlertTrH extends SObjectTriggerHandler {  
    public static Map<Id, Opportunity> accRelatedOpportunityOnAccOwnerChange = new Map<Id, Opportunity>();
    @TestVisible
    private List<Account> newAccounts;
    @TestVisible
    private Map<Id, Account> oldAccountsMap;
    @TestVisible
    private AccountSelector accountSelector = new AccountSelector();
    
    @TestVisible 
    public AccountStoreRelOppForEmailAlertTrH() {
        this((List<Account>) Trigger.new, (Map<Id, Account>) Trigger.oldMap);
    }
    
    @TestVisible
    private AccountStoreRelOppForEmailAlertTrH(List<Account> newAccounts, Map<Id, Account> oldAccountsMap) {
        this.newAccounts = newAccounts;
        this.oldAccountsMap = oldAccountsMap;            
    }
    
    public override void beforeUpdate() {
        Set<Id> validAccountIds = new Set<Id>();
        for (Account newAccount : newAccounts) {
            if (TriggerUtility.isFieldValueChanged(newAccount, oldAccountsMap.get(newAccount.Id), 'OwnerId')) {
                validAccountIds.add(newAccount.Id);
            }
        }
        if (validAccountIds.isEmpty()) {
            return;
        }
        for (Account existingAccWithRelOpp : accountSelector.getAccountWithOpportunities(validAccountIds)) {
            accRelatedOpportunityOnAccOwnerChange.putAll(existingAccWithRelOpp.Opportunities);
        }
    }
}