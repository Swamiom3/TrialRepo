/************************************************************************************************************************************
Author      :   Roshan Kankrayane
Description :   This class contain method to update Co-Prime Region(s) and Co-Prime on account (ST-8154)
----------------------------------------------------------------------------------------------------------------------------------
VERSION    DATE         AUTHOR              DETAIL
1          16/07/2021   Roshan Kankrayane   Initial version
**************************************************************************************************************************************/
public class AccTeamUpdateCoPrimeRegionOnAccTrH extends SObjectTriggerHandler{
    private static final String TERRITORY_CO_PRIME = 'Territory Co-Prime'; 
    private static final String REGIONAL_CO_PRIME = 'Regional Co-Prime';
    private static final Set<String> TEAM_MEMBER_ROLES  = new Set<String>{TERRITORY_CO_PRIME, REGIONAL_CO_PRIME};
    
    @TestVisible
    private List<AccountTeamMember> newMembers;
    @TestVisible
    private Map<Id, AccountTeamMember> oldMembersMap;
    @TestVisible
    private AccountSelector accountSelector = new AccountSelector();
    
    public AccTeamUpdateCoPrimeRegionOnAccTrH(){
        this((List<AccountTeamMember>) Trigger.new, (Map<Id, AccountTeamMember>) Trigger.oldMap);
    }
    
    @TestVisible
    private AccTeamUpdateCoPrimeRegionOnAccTrH(List<AccountTeamMember> newTeamMembers, Map<Id, AccountTeamMember> oldTeamMembersMap){
        newMembers = newTeamMembers;
        oldMembersMap = oldTeamMembersMap;
    }
    
    public override void afterInsert(){
        updateCoPrimeRegionOnAccount();
    }
    
    public override void afterUpdate(){
        updateCoPrimeRegionOnAccount();
    }
    
    public override void afterDelete(){
        Set<Id> accountIds = new Set<Id>();
        for(AccountTeamMember oldMember : oldMembersMap.values()){
            if(oldMember.TeamMemberRole == TERRITORY_CO_PRIME || oldMember.TeamMemberRole == REGIONAL_CO_PRIME){
                accountIds.add(oldMember.AccountId);
            }
        }
        updateAccounts(accountIds);
    }
    
    private void updateCoPrimeRegionOnAccount(){
        Set<Id> accountIds = new Set<Id>();  
        for (AccountTeamMember newMember : newMembers) {
            AccountTeamMember oldMember = oldMembersMap?.get(newMember.Id);
            if((newMember.TeamMemberRole == TERRITORY_CO_PRIME || newMember.TeamMemberRole == REGIONAL_CO_PRIME) && (oldMember == null || (oldMember != null && TriggerUtility.isFieldsValueChanged(newMember, oldMember, new Set<String>{'TeamMemberRole', 'Region__c'})))){
                accountIds.add(newMember.AccountId);
            }
        }
        updateAccounts(accountIds);
    }
    
    private void updateAccounts(Set<Id> accountIds){
        List<Account> accounts = getAccountsToUpdate(accountIds);
        if(accounts != null && !accounts.isEmpty()){
            update accounts;
        }    
    }
    
    private Map<Id, Region__c> getRegions(){
        return new Map<Id, Region__c>([SELECT Id, Name FROM Region__c]);
    }
    
    private List<Account> getAccountsToUpdate(Set<Id> accountIds){
        if(accountIds.isEmpty()){
            return null; 
        }
        Map<Id, Region__c> regionIdsWithRegion = getRegions();
        List<Account> accountsToUpdate = new List<Account>(accountSelector.getAccountWithAccountTeam(TEAM_MEMBER_ROLES, accountIds));
        for(Account account : accountsToUpdate){
            Set<String> regions = new Set<String>();
            for(AccountTeamMember accountTeamMember : account.AccountTeamMembers){
                regions.add(regionIdsWithRegion.get(accountTeamMember.Region__c).Name);
            }
            account.Co_Prime_Region__c = String.join(new List<String>(regions),';');
            account.Co_Prime__c = !account.AccountTeamMembers.isEmpty();
        }
        return accountsToUpdate;
    }
}