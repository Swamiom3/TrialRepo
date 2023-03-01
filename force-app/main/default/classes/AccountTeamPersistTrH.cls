/*************************************************************************************************************************************
    Author      :   Stepan Vardzal
    Description :   Persists Account Team Member records through Account ownership change
    History     :   Changed trigger framework and refactored class "TrAccountTeamPersist"
    Test Class  :   This TrH is covered on 100% by AccountPreventTeamMemberDeleteTrHTest
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION         DATE            AUTHOR                      DETAIL                                                      ISSUE
    1.0             01 Nov, 2021    Stepan Vardzal              Refactor triggers: Account Owner Change                     ST-9301
**************************************************************************************************************************************/
public with sharing class AccountTeamPersistTrH extends SObjectTriggerHandler {

    private List<Account_Team_Persistence__e> newAccountTeamMembers;

    public AccountTeamPersistTrH() {
        this((List<Account_Team_Persistence__e>) Trigger.new);
    }

    private AccountTeamPersistTrH(List<Account_Team_Persistence__e> newAccountTeamMembers) {
        this.newAccountTeamMembers = newAccountTeamMembers;
    }

    public override void afterInsert() {
        persistAccountTeam();
    }

    private void persistAccountTeam(){
        Database.SaveResult[] serializedAccountTeamMemberList = Database.insert(((List<AccountTeamMember>) JSON.deserialize(newAccountTeamMembers[0].Serialized_Account_Team__c, List<AccountTeamMember>.class)).deepClone(false, true, false), false);
        for(Database.SaveResult serializedAccountTeamMember : serializedAccountTeamMemberList){
            if(serializedAccountTeamMember.isSuccess()){
                continue;
            }
            for(Database.Error err : serializedAccountTeamMember.getErrors()){
                ApexDebugLog.logException(new AccountTeamPersistTrHException(err.getMessage()), 'Serialized Account Team ==> ' + newAccountTeamMembers[0].Serialized_Account_Team__c, 'AccountTeamPersistTrH', 'persistAccountTeam');          
            }
        }
    }
    private class AccountTeamPersistTrHException extends Exception{}
}