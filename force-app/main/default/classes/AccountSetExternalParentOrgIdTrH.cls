/************************************************************************************************************************************
    Author      :   Mikolaj Juras    
    @Description :  Account handler to upade 18 digits Id for parent Account.
                    On Insert call queueable class AsyncAccountSetExtSelfRefParentId
    Issue No    :     ST-7574
    History        :
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION     DATE                AUTHOR              ISSUE NO        DETAIL
    1         28 January 2021       Mikolaj Juras       ST-7574         Initial Developement 
    2         5 Feb      2021       Mikolaj Juras       ST-7693         Fix too many queueble issue   
    3         18 Feb     2021       Mikołaj Juras       ST-7781         fix future from futre error                  
**************************************************************************************************************************************/
public without sharing class AccountSetExternalParentOrgIdTrH extends SObjectTriggerHandler {

    private List<Account> newAccounts;
    private Map<Id, Account> oldAccountsMap;

    public AccountSetExternalParentOrgIdTrH() {
        this((List<Account>) Trigger.new, (Map<Id, Account>) Trigger.oldMap);
    }

    @TestVisible
    private AccountSetExternalParentOrgIdTrH(List<Account> newAccounts, Map<Id, Account> oldAccountsMap) {
        this.newAccounts = newAccounts;
        this.oldAccountsMap = oldAccountsMap;
    }

    public override void afterInsert() {
        AsyncAccountSetExtSelfRefParentId asyncAccountSetExtSelfRefParentId = new AsyncAccountSetExtSelfRefParentId();
        asyncAccountSetExtSelfRefParentId.setExtSelfRefParentOrgId(new Map<Id, Account>(newAccounts).keySet());
    }

    public override void beforeUpdate() {
        for(Account newAccountRec : newAccounts){
            if(TriggerUtility.isFieldValueChanged(newAccountRec, oldAccountsMap.get(newAccountRec.Id), 'Parent_Org_Id__c')){
                newAccountRec.External_Parent_Org_Id__c = Id.valueOf(newAccountRec.Parent_Org_Id__c);
                if(newAccountRec.Account_Type__c == 'Sales'){
                    newAccountRec.Ultimate_Parent_Org__c = Id.valueOf(newAccountRec.Parent_Org_Id__c);
                }
            }
        }
    }
}