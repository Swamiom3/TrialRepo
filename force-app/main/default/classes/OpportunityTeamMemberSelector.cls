/*************************************************************************************************************************************
    Author      :   Liubomyr Mishchykha
    Description :   This class is selector implementation of Opportunity Team Member
    --------------------------------------------------------------------------------------------------------------------------------------
    VERSION         DATE            AUTHOR                      DETAIL
    1.0             12 Jul, 2021    Liubbomyr Mishchykha        Initial Deployment
**************************************************************************************************************************************/
public with sharing class OpportunityTeamMemberSelector extends SObjectSelector {
    private final List<String> DEFAULT_FIELDS = new List<String>{   'Id',
                                                                    'OpportunityId',
                                                                    'UserId',
                                                                    'TeamMemberRole',
                                                                    'OpportunityAccessLevel' };

    private final List<String> DEFAULT_CUSTOM_FIELDS = new List<String>{'Primary_Tour_Assist__c',
                                                                        'User_Attribute__c',
                                                                        'Assigned_Date__c'};

    public OpportunityTeamMemberSelector() {
        super(OpportunityTeamMember.SObjectType);
    }

    public override Set<String> getDefaultFields() {
        return new Set<String>(DEFAULT_FIELDS);
    }

    public List<OpportunityTeamMember> getOpportunityTeamMembersOnAccOwnerChange(Set<Id> opportunityIds, Set<Id> ownerChangedAccountIds) {
        if (opportunityIds == null || ownerChangedAccountIds == null) {
            return new List<OpportunityTeamMember>();
        }
        List<String> fields = new List<String>(DEFAULT_FIELDS);
        fields.addAll(DEFAULT_CUSTOM_FIELDS);
        List<Object> bindings = new List<Object>{ opportunityIds, ownerChangedAccountIds };
        String whereClause = 'OpportunityId IN :opportunityIds AND Opportunity.AccountId IN :ownerChangedAccountIds';
        return (List<OpportunityTeamMember>) getSObjects(fields, whereClause, bindings);
    }

    public List<OpportunityTeamMember> getExistingOpportunityTeamMemberIds(Set<Id> opportunityIds) {
        if (opportunityIds == null || opportunityIds.isEmpty()) {
            return new List<OpportunityTeamMember>();
        }
        List<String> fields = new List<String>{'Id'};
        List<Object> bindings = new List<Object>{opportunityIds};
        String whereClause = 'OpportunityId IN :opportunityIds';
        return (List<OpportunityTeamMember>) getSObjects(fields, whereClause, bindings);
    }
}