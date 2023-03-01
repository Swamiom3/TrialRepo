/****************************************************************************************************************************************************
    Author        :  Tomasz Sadowski
    Description   :  Validates opp team member changes.
    Issue No.     :  ST-8827
    History       :
-----------------------------------------------------------------------------------------------------------------------------------------------------
    VERSION        DATE             AUTHOR              Issue       Description
    1              12 Aug 2021      Tomasz Sadowski     ST-8827     Introduces validation of Opportunity Team Member changes
****************************************************************************************************************************************************/
public with sharing class OppTeamMemberValidationTrH extends SObjectTriggerHandler {
    @TestVisible
    private List<OpportunityTeamMember> newOpportunityTeamMembers;
    @TestVisible
    private List<OpportunityTeamMember> oldOpportunityTeamMembers;
    @TestVisible
    private Map<Id, OpportunityTeamMember> oldOpportunityTeamMembersMap;
    @TestVisible
    private final static String ERROR_MSG = Label.OTM_Closed_Won_Validation_Message;
    private final static Set<String> VALIDATED_FIELDS = new Set<String> {
        'Accelerate__c', 'Assigned_Date__c', 'OpportunityId', 'OpportunityAccessLevel', 'Primary_Tour_Assist__c',
        'Split_Rep_Percentage__c', 'TeamMemberRole', 'TeamMemberCreationSource__c', 'UserId', 'User_Attribute__c'
    };
    private static Set<Id> byPassedProfiles = new Set<Id>();
    public OppTeamMemberValidationTrH() {
        this((List<OpportunityTeamMember>) Trigger.new, (List<OpportunityTeamMember>) Trigger.old, (Map<Id, OpportunityTeamMember>) Trigger.oldMap);        
    }
    
    @TestVisible
    private OppTeamMemberValidationTrH(List<OpportunityTeamMember> newOpportunityTeamMembers, List<OpportunityTeamMember> oldOpportunityTeamMembers, Map<Id, OpportunityTeamMember> oldOpportunityTeamMembersMap) {
        this.newOpportunityTeamMembers = newOpportunityTeamMembers;
        this.oldOpportunityTeamMembers = oldOpportunityTeamMembers;
        this.oldOpportunityTeamMembersMap = oldOpportunityTeamMembersMap;
    }
    
    public override void beforeInsert() {
        preventClosedWonChange();
    }
    
    public override void beforeUpdate() {
        preventClosedWonChange();
    }
    
    public override void beforeDelete() {
        preventClosedWonChange();
    }
    
    private void preventClosedWonChange() {
        if (getAllowedProfiles().contains(UserInfo.getProfileId())) {
            return;
        }
        List<OpportunityTeamMember> opportunityTeamMembers = context == TriggerContext.BEFORE_DELETE ? oldOpportunityTeamMembers : newOpportunityTeamMembers;
        Map<Id, List<OpportunityTeamMember>> oppIdToMembers = new Map<Id, List<OpportunityTeamMember>>();
        List<OpportunityTeamMember> alteredMembers = new List<OpportunityTeamMember>();
        for (OpportunityTeamMember teamMember : opportunityTeamMembers) {
            OpportunityTeamMember oldTeamMember = context == TriggerContext.BEFORE_DELETE ? teamMember : oldOpportunityTeamMembersMap?.get(teamMember.Id);
            if (context == TriggerContext.BEFORE_UPDATE && !TriggerUtility.isFieldsValueChanged(teamMember, oldTeamMember, VALIDATED_FIELDS)) {
                continue;
            }
            alteredMembers.add(teamMember);
            TriggerUtility.addSobjectValuesToMap('OpportunityId', oppIdToMembers, teamMember);
        }
        if (alteredMembers.isEmpty()) {
            return;
        }
        validateClosedWonMembers(oppIdToMembers, alteredMembers);
    }

    private Set<Id> getAllowedProfiles() {
        Set<Id> allowedProfiles = new Set<Id>();
        allowedProfiles.add(Validation_Rule_Restriction__mdt.getInstance('System_Administrator').Salesforce_Id__c);
        allowedProfiles.add(Validation_Rule_Restriction__mdt.getInstance('WeWork_System_Administrator').Salesforce_Id__c);
        allowedProfiles.add(Validation_Rule_Restriction__mdt.getInstance('WeWork_Support_and_Operations').Salesforce_Id__c);
        return allowedProfiles;
    }
        
    private void validateClosedWonMembers(Map<Id, List<OpportunityTeamMember>> oppIdToMembers, List<OpportunityTeamMember> alteredMembers) {
        if(FeatureManagement.checkPermission('Validation_Bypass_User_Integration')){
            return;
        }
        Set<Id> closedWonOpportunityIds = getClosedWonOpportunityIds(oppIdToMembers.keySet());
        for (OpportunityTeamMember teamMember : alteredMembers) {
            if (closedWonOpportunityIds.contains(teamMember.OpportunityId)) {
                teamMember.addError(ERROR_MSG);
            }
        }
    }

    private Set<Id> getClosedWonOpportunityIds(Set<Id> oppIds) {
        return new Map<Id, Opportunity>([SELECT Id
                                         FROM Opportunity
                                         WHERE Id IN :oppIds
                                               AND IsWon = TRUE])
                                       .keySet();
    }
}