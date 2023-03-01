/************************************************************************************************************************************
    Author      : Salesforce Professional Services
    Description : Insert account team member with 'Account Manager' role based on Account Manager field on account record.
    
    History:
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION     DATE                AUTHOR              ISSUE NO        DETAIL                                         
    1           8 July, 2021        SPS         TWSPG-196       Initial Development                               
**************************************************************************************************************************************/
public class AccountSyncManagerTeamMemberTrH extends SObjectTriggerHandler{
    private static final String ACC_ACCESS_LEVEL = 'Edit';
    private static final String ACC_MNGR_ROLE = 'Account Manager';
    
    @TestVisible
    private List<Account> newAccounts;
    
    @TestVisible
    private Map<Id, Account> oldAccountsMap;
    
    @TestVisible 
    public AccountSyncManagerTeamMemberTrH(){
        this((List<Account>) Trigger.new, (Map<Id, Account>) Trigger.oldMap);
    }
    
    @TestVisible
    private AccountSyncManagerTeamMemberTrH(List<Account> newAccounts, Map<Id, Account> oldAccountsMap){
        this.newAccounts = newAccounts;
        this.oldAccountsMap = oldAccountsMap;            
    }
    
    public override void afterinsert(){
        insertTeamMemberOnAccountcreation();
    }
    
    public override void afterUpdate(){
        syncTeamMembersOnAccountManagerChange();
    }
    
    @TestVisible
    private void insertTeamMemberOnAccountCreation(){
        List<AccountTeamMember> newAccountManagerMember = new List<AccountTeamMember>(); 
        for(Account newAccountRec : newAccounts){
            if(newAccountRec.Account_Manager_Lookup__c  != null ){
                AccountTeamMember newAccountTeamRec = new AccountTeamMember();
                newAccountTeamRec.AccountId = newAccountRec.Id;
                newAccountTeamRec.UserId = newAccountRec.Account_Manager_Lookup__c;
                newAccountTeamRec.AccountAccessLevel = ACC_ACCESS_LEVEL;
                newAccountTeamRec.TeamMemberRole  = ACC_MNGR_ROLE;               
                newAccountManagerMember.add(newAccountTeamRec); 
            }            
        }
        
        addManagerTeamMember(newAccountManagerMember);     
    }
    
    @TestVisible
    private void syncTeamMembersOnAccountManagerChange(){
        List<AccountTeamMember> removeManagerTeamMember = new List<AccountTeamMember>(); 
        Map<Id, Id> changedAccountToManagerIds = new Map<Id, Id>();
        for(Account newAccountRec : newAccounts){
            Account oldAccountRec = oldAccountsMap.get(newAccountRec.Id);
            if(newAccountRec.Account_Manager_Lookup__c  != oldAccountRec.Account_Manager_Lookup__c ){ 
               changedAccountToManagerIds.put(newAccountRec.Id, newAccountRec.Account_Manager_Lookup__c);
            }
        }
        
        if(changedAccountToManagerIds.isEmpty()){
            return;
        }        
        
        List<AccountTeamMember> existingAccountTeamMembers = [SELECT Id, UserId, AccountId, AccountAccessLevel, 
                                                              TeamMemberRole FROM AccountTeamMember 
                                                              WHERE AccountId IN: changedAccountToManagerIds.keySet()
                                                             ];
        if(existingAccountTeamMembers.isEmpty()){
            insertTeamMemberOnAccountcreation();
            return;                 
        } else {          
            for(AccountTeamMember AccountTeamRec : existingAccountTeamMembers){
                if(AccountTeamRec.TeamMemberRole  == ACC_MNGR_ROLE){
                    removeManagerTeamMember.add(AccountTeamRec);
                }   
            }
            deleteManagerTeamMember(removeManagerTeamMember);
            insertTeamMemberOnAccountcreation(); 
        }        
    }
    
    @TestVisible
    private static void deleteManagerTeamMember(List<AccountTeamMember> accountTeamMemberToRemove){
        if(accountTeamMemberToRemove == null || accountTeamMemberToRemove.isEmpty()){
            return;
        }       
        try{
             Database.delete(accountTeamMemberToRemove, false);
        }catch(DMLException pEx){
            ApexDebugLog.logException(pEx, '', 'AccountSyncManagerTeamMemberTrH', 'deleteManagerTeamMember'); 
        }  
    }
    
    @TestVisible
    private static void addManagerTeamMember(List<AccountTeamMember> accountTeamMemberToUpdate){
        if(accountTeamMemberToUpdate == null || accountTeamMemberToUpdate.isEmpty()){
            return;
        }       
        try{
             Database.insert(accountTeamMemberToUpdate, false);
        }catch(DMLException pEx){
            ApexDebugLog.logException(pEx, '', 'AccountSyncManagerTeamMemberTrH', 'addManagerTeamMember'); 
        }   
    }
}