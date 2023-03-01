/************************************************************************************************************************************
    Author      : Nicholas Zozaya
    Description : Insert platform event on Account Owner change so PE trigger persists account team
    
    History:
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION     DATE                AUTHOR              ISSUE NO        DETAIL
    1           25 Oct, 2019        Nicholas Zozaya     ST-4734         Initial Development
    2           25 Nov, 2019        Nicholas Zozaya                     Use platform events instead of @future
    3           30 Sept 2020        Krishana Tupe       ST-3174         Code Optimization and Consolidated with new trigger structure
**************************************************************************************************************************************/
public without sharing class AccountPreventTeamMemberDeleteTrH extends SObjectTriggerHandler{  
    
    @TestVisible
    private List<Account> newAccounts;
    @TestVisible
    private Map<Id, Account> oldAccountsMap;
    
    @TestVisible 
    public AccountPreventTeamMemberDeleteTrH(){
        this((List<Account>) Trigger.new, (Map<Id, Account>) Trigger.oldMap);
    }
    
    @TestVisible
    private AccountPreventTeamMemberDeleteTrH(List<Account> newAccounts, Map<Id, Account> oldAccountsMap){
        this.newAccounts = newAccounts;
        this.oldAccountsMap = oldAccountsMap;            
    }
    
    public override void beforeUpdate(){
        storeAndReInsertTeamMembersOnAccountOwnerChange();
    }
    
    private void storeAndReInsertTeamMembersOnAccountOwnerChange(){
        Set<Id> ownerChangedAccountIds = new Set<Id>(); 
        for(Account newAccountRec : newAccounts){
            Account oldAccountRec = oldAccountsMap.get(newAccountRec.Id);
            if(newAccountRec.OwnerId == oldAccountRec.OwnerId){
                continue;  
            }
            ownerChangedAccountIds.add(newAccountRec.Id);
        }
        if(ownerChangedAccountIds.isEmpty()){
            return;
        }        
        List<AccountTeamMember> existingAccountTeamMembers = [SELECT Id, User_Sales_Function__c, Start_Date__c, End_Date__c,
                                                              UserId, AccountId, Region__c, Territory__c, AccountAccessLevel, 
                                                              CaseAccessLevel, OpportunityAccessLevel, ContactAccessLevel, 
                                                              TeamMemberRole, Validation_Sequence__c FROM AccountTeamMember 
                                                              WHERE AccountId IN: ownerChangedAccountIds AND User.IsActive = true
                                                             ];
        if(!existingAccountTeamMembers.isEmpty()){
            EventBus.publish(new Account_Team_Persistence__e(Serialized_Account_Team__c = JSON.serialize(existingAccountTeamMembers)));
        }
    }
}