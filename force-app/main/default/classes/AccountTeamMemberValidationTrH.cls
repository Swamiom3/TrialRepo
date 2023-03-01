/*************************************************************************************************************************************
    Author      :   Stepan Vardzal
    Description :   Validation handler which validates each new AccountTeamMember record against every other new AccountTeamMember 
                    records and proceeding to validate those records against the Account's existing AccountTeamMember records.
    History:        Changed trigger framework and refactored class "TrAccountTeamValidation"
    --------------------------------------------------------------------------------------------------------------------------------------
    VERSION         DATE            AUTHOR                      DETAIL							                            ISSUE
    1.0             24 Aug, 2021    Stepan Vardzal              Refactor triggers: AccountTeamMember                        ST-8430
**************************************************************************************************************************************/
public with sharing class AccountTeamMemberValidationTrH extends SObjectTriggerHandler {
    private static final User LOGGED_IN_USER_INFO = UserUtility.getUserById(userInfo.getUserId());
    private static final Boolean IS_PLATFORM_USER = LOGGED_IN_USER_INFO?.Profile.Name == null && UserInfo.getSessionId() == null;

    @TestVisible
    private List<AccountTeamMember> newAccountTeamMembers;
    @TestVisible
    private Map<Id, AccountTeamMember> oldAccountTeamMembersMap;
    private List<String> validatedRoles;
    @TestVisible
    private AccountTeamMemberSelector accountTeamMemberSelector = new AccountTeamMemberSelector();
    @TestVisible
    private AccountSelector accountSelector = new AccountSelector();

    @TestVisible
    public AccountTeamMemberValidationTrH() {
        this((List<AccountTeamMember>) Trigger.new, (Map<Id, AccountTeamMember>) Trigger.oldMap);
    }

    @TestVisible
    private AccountTeamMemberValidationTrH(List<AccountTeamMember> newAccountTeamMembers, Map<Id, AccountTeamMember> oldAccountTeamMembersMap) {
        this.newAccountTeamMembers = newAccountTeamMembers;
        this.oldAccountTeamMembersMap = oldAccountTeamMembersMap;
        validatedRoles = (List<String>) JSON.deserialize(MetadataSetting__mdt.getInstance('Non_Duplicated_Account_Team_Roles').Data__c, List<String>.class);
    }

    public override void beforeInsert() {
        validateAccountTeamMember(newAccountTeamMembers);
        validateUniqueRole();
        validateAgainstExistingRecords();
    }

    public override void beforeUpdate() {
        validateAccountTeamMember(newAccountTeamMembers);
        validateAgainstExistingRecords();
    }

    public override void beforeDelete() {
        validateAccountTeamMember((List<AccountTeamMember>) oldAccountTeamMembersMap.values());
    }
    
     public override void afterDelete() {
        validateAccountTeamMember((List<AccountTeamMember>) oldAccountTeamMembersMap.values());
    }

    public void validateAccountTeamMember(List<AccountTeamMember> accountTeamMembers) {
        MetadataSetting__mdt metadataRecord = Settings.getMetadataSetting('AccountTeamMemberInsertDeltPermission');
        if (metadataRecord?.Data__c == null) {
            return;
        }
        AccountTeamMemberValidation accountTeamOwnerSetting = (AccountTeamMemberValidation)JSON.deserialize(metadataRecord.Data__c, AccountTeamMemberValidation.class);
        if (accountTeamOwnerSetting == null) {
            return;
        }
        Set<Id> allowedProfileIds = new Set<Id>(accountTeamOwnerSetting.allowedProfileId.values());
        Set<Id> permissionSetIds = new Set<Id>(accountTeamOwnerSetting.allowedPermissionId.values());
        Set<String> sealesFunctions = accountTeamOwnerSetting.salesFunction;
        User currentUser = LOGGED_IN_USER_INFO;
        validateAccountManagerTeamMember(accountTeamMembers);
        
        String permSetId = PermissionSetService.getPermissionSetId(userInfo.getUserId());
        for (AccountTeamMember accountTeamMember : accountTeamMembers) {
            if (!sealesFunctions.isEmpty() && String.isNotBlank(currentUser?.Sales_Role__c) && sealesFunctions.contains(currentUser?.Sales_Role__c)) {
                continue;
            } else if (accountTeamMember.TeamMemberRole == null) {
                accountTeamMember.addError('Team Member should have a role');
                continue;
            } else if (!IS_PLATFORM_USER && !allowedProfileIds.isEmpty()  && !allowedProfileIds.contains(currentUser?.ProfileId) && !permissionSetIds.contains(permSetId)) {
                String errorMessage = this.context == TriggerContext.BEFORE_INSERT ? accountTeamOwnerSetting.insertError : this.context == TriggerContext.BEFORE_UPDATE ? accountTeamOwnerSetting.updateError : accountTeamOwnerSetting.deleteError;
                accountTeamMember.addError(errorMessage);
            }
        }
    }

    @TestVisible
    private void validateUniqueRole() {
        Map<Id, List<AccountTeamMember>> accountIdsToAccountTeamMember = mapAccountIdsToAccountTeamMembers(newAccountTeamMembers);
        Map<Id, Map<String, AccountTeamMember>> accountIdsToUniqueRole = new Map<Id, Map<String, AccountTeamMember>>();
        for (Id accountId : accountIdsToAccountTeamMember.keyset()) {
            for (AccountTeamMember newTeamMember : accountIdsToAccountTeamMember.get(accountId)) {
                if (accountIdsToUniqueRole.containsKey(newTeamMember.AccountId) 
                    && accountIdsToUniqueRole.get(newTeamMember.AccountId).containsKey(newTeamMember.TeamMemberRole)) {
                    newTeamMember.addError(Label.ATM_Nmd_Mlb_Role_Validation_Msessage);
                    accountIdsToUniqueRole.get(newTeamMember.AccountId).get(newTeamMember.TeamMemberRole).addError(Label.ATM_Nmd_Mlb_Role_Validation_Msessage);
                } else if (accountIdsToUniqueRole.containsKey(newTeamMember.AccountId) && !accountIdsToUniqueRole.get(newTeamMember.AccountId).isEmpty() 
                            && validatedRoles.contains(newTeamMember.TeamMemberRole.toLowerCase())) {
                    accountIdsToUniqueRole.get(newTeamMember.AccountId).put(newTeamMember.TeamMemberRole, newTeamMember);
                } else if (validatedRoles.contains(newTeamMember.TeamMemberRole?.toLowerCase())) {
                    accountIdsToUniqueRole.put(newTeamMember.AccountId, new Map<String, AccountTeamMember>{ newTeamMember.TeamMemberRole => newTeamMember });
                }
            }
        }
    }

    @TestVisible
    private void validateAgainstExistingRecords() { 
        Set<Id> newTeamMemberAccountIds = new Set<Id>();
        for (AccountTeamMember newAccountTeamMember : newAccountTeamMembers) {
            newTeamMemberAccountIds.add(newAccountTeamMember.AccountId);
        }
        Map<Id, List<AccountTeamMember>> accountIdsToAccountTeamMember = mapAccountIdsToAccountTeamMembers(accountTeamMemberSelector.getAccountTeamMembers(newAccountTeamMembers, newTeamMemberAccountIds));
        for (AccountTeamMember newAccountTeamMember : newAccountTeamMembers) {
            if (!accountIdsToAccountTeamMember.containsKey(newAccountTeamMember.AccountId) 
                || !validatedRoles.contains(newAccountTeamMember.TeamMemberRole?.toLowerCase())) {
                continue;
            }
            for (AccountTeamMember existingMember : accountIdsToAccountTeamMember.get(newAccountTeamMember.AccountId)) {
                if (existingMember.TeamMemberRole?.equals(newAccountTeamMember.TeamMemberRole)) {
                    newAccountTeamMember.addError(Label.ATM_Nmd_Mlb_Role_Validation_Msessage);
                }
            }
        }
    }

    private Map<Id, List<AccountTeamMember>> mapAccountIdsToAccountTeamMembers(List<AccountTeamMember> teamMembersToMap) {
        Map<Id, List<AccountTeamMember>> accountIdsToAccountTeamMember = new Map<Id, List<AccountTeamMember>>();
        for (AccountTeamMember accountTeamMember : teamMembersToMap) {
            if (accountIdsToAccountTeamMember.containsKey(accountTeamMember.AccountId)) {
                accountIdsToAccountTeamMember.get(accountTeamMember.AccountId).add(accountTeamMember);
                continue;
            }
            accountIdsToAccountTeamMember.put(accountTeamMember.AccountId, new List<AccountTeamMember>{ accountTeamMember });
        }
        return accountIdsToAccountTeamMember;
    }
    @TestVisible
    private void validateAccountManagerTeamMember(List<AccountTeamMember> accountTeamMembers) {
        if (FeatureManagement.checkPermission('Bypass_Validation_Rule')) {
            return;
        }
        Set<Id> accountIds = new Set<Id>();
        for (AccountTeamMember accountTeamMember : accountTeamMembers) {
            accountIds.add(accountTeamMember.AccountId);
        }
        
        Map<Id, Account> accountsMap = new Map<Id, Account>(accountSelector.getAccountManagerByAccId(new List<Id>(accountIds)));

        for (AccountTeamMember accountTeamMember : accountTeamMembers) {
            Boolean isThrowErrorInsert = this.context == TriggerContext.BEFORE_INSERT
                && accountTeamMember.TeamMemberRole == GlobalConstants.ACCOUNT_MANAGER_TEAM_MEMBER_ROLE
                && accountsMap.get(accountTeamMember.AccountId)?.Account_Manager_Lookup__c != accountTeamMember.UserId;
            
            Boolean isThrowErrorUpdate = this.context == TriggerContext.BEFORE_UPDATE
                && ((TriggerUtility.isFieldsValueChanged(oldAccountTeamMembersMap.get(accountTeamMember.Id), accountTeamMember, new Set<String>{'TeamMemberRole', 'AccountAccessLevel','CaseAccessLevel', 'ContactAccessLevel', 'OpportunityAccessLevel'})
                        && oldAccountTeamMembersMap.get(accountTeamMember.Id)?.TeamMemberRole == GlobalConstants.ACCOUNT_MANAGER_TEAM_MEMBER_ROLE)
                    || (accountTeamMember.TeamMemberRole == GlobalConstants.ACCOUNT_MANAGER_TEAM_MEMBER_ROLE
                        && accountsMap.get(accountTeamMember.AccountId)?.Account_Manager_Lookup__c != accountTeamMember.UserId));
            
            Boolean isThrowErrorDelete = (this.context == TriggerContext.BEFORE_DELETE || this.context == TriggerContext.AFTER_DELETE)
                && accountTeamMember.TeamMemberRole == GlobalConstants.ACCOUNT_MANAGER_TEAM_MEMBER_ROLE
                && accountsMap.get(accountTeamMember.AccountId)?.Account_Manager_Lookup__c == accountTeamMember.UserId;
            if (isThrowErrorInsert || isThrowErrorUpdate || isThrowErrorDelete) {
                accountTeamMember.addError(Label.AccountManagerTeamMemberValidation);
            }
        }
    }
    
    public class AccountTeamMemberValidation {
        public Map<String, Id> allowedProfileId;
        public Map<String, Id> allowedPermissionId;
        public Set<String> salesFunction;
        public String insertError;
        public String deleteError;
        public String updateError;
    }
}