/*************************************************************************************************************************************
    Author      :   Stepan Vardzal
    Description :   This class is selector implementation of Account Team Member
    --------------------------------------------------------------------------------------------------------------------------------------
    VERSION         DATE            AUTHOR                      DETAIL
    1.0             26 Aug, 2021    Stepan Vardzal              Initial Deployment
**************************************************************************************************************************************/
public with sharing class AccountTeamMemberSelector extends SObjectSelector {
    private final List<String> DEFAULT_FIELDS = new List<String>{   'Id',
                                                                    'AccountId',
                                                                    'UserId',
                                                                    'TeamMemberRole'};

    private final List<String> DEFAULT_CUSTOM_FIELDS = new List<String>{'User_Sales_Function__c',
                                                                        'Region__c',
                                                                        'Territory__c'};

    public AccountTeamMemberSelector() {
        super(AccountTeamMember.SObjectType);
    }

    public override Set<String> getDefaultFields() {
        return new Set<String>(DEFAULT_FIELDS);
    }

    public List<AccountTeamMember> getAccountTeamMembers (List<AccountTeamMember> newAccountTeamMembers, Set<Id> newTeamMemberAccountIds) {
        if (newAccountTeamMembers == null || newTeamMemberAccountIds == null || newTeamMemberAccountIds.isEmpty()) {
            return new List<AccountTeamMember>();
        }
        List<String> fields = new List<String>(DEFAULT_FIELDS);
        fields.addAll(DEFAULT_CUSTOM_FIELDS);
        List<Object> bindings = new List<Object>{ newAccountTeamMembers, newTeamMemberAccountIds };
        String whereClause = 'Id NOT IN: newAccountTeamMembers AND AccountId IN: newTeamMemberAccountIds AND (End_Date__c = null OR End_Date__c > TODAY)';
        return (List<AccountTeamMember>) getSObjects(fields, whereClause, bindings);
    }

    public List<AccountTeamMember> getAccountTeamMembersWithGlobalAccount (Set<Id> globalAccountIds, String teamMemberRole) {
        if (globalAccountIds == null || globalAccountIds.isEmpty()) {
            return new List<AccountTeamMember>();
        }
        List<String> fields = new List<String>(DEFAULT_FIELDS);
        fields.remove(3);
        String whereClause = 'AccountId IN :globalAccountIds AND TeamMemberRole =:teamMemberRole AND User.IsActive = TRUE';
        List<Object> bindings = new List<Object>{ globalAccountIds, teamMemberRole };
        return (List<AccountTeamMember>) getSObjects(fields, whereClause, bindings);
    }
}