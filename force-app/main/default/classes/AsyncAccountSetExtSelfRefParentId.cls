/************************************************************************************************************************************
    Author      :   Mikolaj Juras
    @Description :  Async class to set the self reference Id (External_Parent_Org_Id__c) with 18 digits ID on insert of new account
    Issue No    :     ST-7574
    History        :
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION     DATE                AUTHOR              ISSUE NO        DETAIL
    1           28 January 2021     Mikolaj Juras       ST-7574         Initial Developement
    2           5 Feb 2021          Mikolaj Juras       ST-7693         Fix too many quables issue
    3           18 Feb 2021         Mikołaj Juras       ST-7781         Fix feature from feture error
**************************************************************************************************************************************/
public without sharing class AsyncAccountSetExtSelfRefParentId implements Queueable, Callable {
    @testVisible
    private Set<Id> accountsIds;
    public AsyncAccountSetExtSelfRefParentId() {}

    private AsyncAccountSetExtSelfRefParentId(Set<Id> accountsIds) {
        this.accountsIds = accountsIds;
    }

    public AsyncAccountSetExtSelfRefParentId call(String action, Map<String, Object> args) {
        return new AsyncAccountSetExtSelfRefParentId((Set<Id>)args.get('accountsIds'));
    }

    public void setExtSelfRefParentOrgId(Set<Id> accountsIds){
        if(System.isFuture()) {
            setExtSelfRefParentOrg(accountsIds);
            return;
        }
        if(System.isQueueable() || Test.isRunningTest()) {
            setExtSelfRefParentOrgIdFuture(accountsIds);
            return;
        }
        setExtSelfRefParentOrgIdQueueable(accountsIds);
    }

    public void execute(QueueableContext context){
        List <Account> accountsToUpdate = getUpdatedAccounts(accountsIds);
        MetadataDrivenTriggerHandler.disableExecution();
        try {
            update accountsToUpdate;
        } catch(Exception e){
            ApexDebugLog.logException(e, JSON.serialize(accountsToUpdate), 'AsyncAccountSetExtSelfRefParentId', 'execute');
        }
        MetadataDrivenTriggerHandler.enableExecution();
    }

    public static void setExtSelfRefParentOrg(Set<Id> accountsIds) {
        List <Account> accountsToUpdate = getUpdatedAccounts(accountsIds);
        MetadataDrivenTriggerHandler.disableExecution();
        try {
            update accountsToUpdate;
        } catch(Exception e){
            ApexDebugLog.logException(e, JSON.serialize(accountsToUpdate), 'AsyncAccountSetExtSelfRefParentId', 'future');
        }
        MetadataDrivenTriggerHandler.enableExecution();
    }

    @future
    public static void setExtSelfRefParentOrgIdFuture(Set<Id> accountsIds) {
        setExtSelfRefParentOrg(accountsIds);
    }

    @testVisible
    private void setExtSelfRefParentOrgIdQueueable(Set<Id> accountsIds) {
        AsyncsExecutor asyncsExecutor = new AsyncsExecutor(AsyncAccountSetExtSelfRefParentId.class, new Map<String, Object>{'accountsIds'=> accountsIds});
        asyncsExecutor.execute();
    }

    @testVisible
    private static List<Account> getUpdatedAccounts(Set<Id> accountsIds) {
        List <Account> accountsToUpdate = new List<Account>();
        for (Account account : new AccountSelector().getSalesAccountsById(accountsIds)) {
            if (account.Parent_Org_Id__c == null) {
                continue;
            }
            account.External_Parent_Org_Id__c = Id.valueOf(account.Parent_Org_Id__c);
            if(account.Account_Type__c == 'Sales'){
                 account.Ultimate_Parent_Org__c = Id.valueOf(account.Parent_Org_Id__c);
            }
            accountsToUpdate.add(account);
        }
        return accountsToUpdate;
    }
}