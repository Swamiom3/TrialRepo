/**********************************************************************************************************
    Author        :  Ashish Sharma
    Description   :  Validates opp team members.
    Issue No.     :  ST-8013
    History       :
-----------------------------------------------------------------------------------------------------------
    VERSION        DATE          AUTHOR           DETAIL
      1         26-Mar-2021    Ashish Sharma      ST-8013
**********************************************************************************************************/
public with sharing class OppTeamMemberValidateMembersTrH extends SObjectTriggerHandler {
    @TestVisible
    private List<OpportunityTeamMember> newOpportunityTeamMembers;
    @TestVisible
    private Map<Id, OpportunityTeamMember> newOpportunityTeamMembersMap;
    @TestVisible
    private Map<Id, OpportunityTeamMember> oldOpportunityTeamMembersMap;
    @TestVisible
    private final static String ERROR_MSG = Label.OTM_All_Access_Validation_Message;
    private final static String ALL_ACCESS_TEAM_ROLE = Settings.getTeamRoleConfigSettings('OppTeamMemberValidateMembersTrH#1');
    private static final Set<String> BYPASSED_CREATION_SOURCE = new Set<String>{'OnOpportunityOwnerChange', 'OnAccountOwnerChange'};
    private static Set<Id> byPassedProfiles = new Set<Id>();
    public OppTeamMemberValidateMembersTrH() {
        this((List<OpportunityTeamMember>) Trigger.new, (Map<Id, OpportunityTeamMember>) Trigger.newMap, (Map<Id, OpportunityTeamMember>) Trigger.oldMap);        
    }
    
    @TestVisible
    private OppTeamMemberValidateMembersTrH(List<OpportunityTeamMember> newOpportunityTeamMembers,
                                            Map<Id, OpportunityTeamMember> newOpportunityTeamMembersMap,
                                            Map<Id, OpportunityTeamMember> oldOpportunityTeamMembersMap) {
        this.newOpportunityTeamMembers = newOpportunityTeamMembers;
        this.newOpportunityTeamMembersMap = newOpportunityTeamMembersMap;
        this.oldOpportunityTeamMembersMap = oldOpportunityTeamMembersMap;
    }
    
    public override void beforeInsert() {
        validateMembers();
    }
    
    public override void beforeUpdate() {
        validateMembers();
    }
    
    @testVisible
    private void validateMembers() {
        if(getByPassedProfiles().contains(UserInfo.getProfileId()) && !Test.isRunningTest()) {
            return;
        }
        
        Map<Id, List<OpportunityTeamMember>> oppIdToMembers = new Map<Id, List<OpportunityTeamMember>>();
        List<OpportunityTeamMember> validMembers = new List<OpportunityTeamMember>();
        for(OpportunityTeamMember newTeamMember : newOpportunityTeamMembers) {
            if(newTeamMember.TeamMemberRole != ALL_ACCESS_TEAM_ROLE || BYPASSED_CREATION_SOURCE.contains(newTeamMember.TeamMemberCreationSource__c)) {
                continue;
            }
            OpportunityTeamMember oldTeamMember = oldOpportunityTeamMembersMap?.get(newTeamMember.Id);
            if(oldTeamMember != null && !TriggerUtility.isFieldValueChanged(newTeamMember, oldTeamMember, 'TeamMemberRole')) {
                continue;
            }
            validMembers.add(newTeamMember);
            TriggerUtility.addSobjectValuesToMap('OpportunityId', oppIdToMembers, newTeamMember);
        }
        if(validMembers.isEmpty()) {
            return;
        }
        validateAllAccessMembers(oppIdToMembers, validMembers);
    }
    
    private Set<Id> getByPassedProfiles() {
        if(!byPassedProfiles.isEmpty()) {
            return byPassedProfiles;
        }
        for(Validation_Rule_Restriction__mdt profileMDT : [SELECT Salesforce_Id__c FROM Validation_Rule_Restriction__mdt
                                                           WHERE DeveloperName IN ('WeWork_NMD_Admin', 'WeWork_GrowthOps', 'WeWork_Support_and_Operations', 'System_Administrator', 'WeWork_System_Administrator')]) {
            byPassedProfiles.add(profileMDT.Salesforce_Id__c);
        }
        return byPassedProfiles;
    }

    @testVisible
    private void validateAllAccessMembers(Map<Id, List<OpportunityTeamMember>> oppIdToMembers, List<OpportunityTeamMember> validMembers) {
        if(FeatureManagement.checkPermission('Validation_Bypass_User_Integration')){
            return;
        }
        Map<Id, List<OpportunityTeamMember>> queriedMembers = getTeamMembers(oppIdToMembers.keySet());
        for(OpportunityTeamMember newTeamMember : validMembers) {
            List<OpportunityTeamMember> newMembers = oppIdToMembers.get(newTeamMember.OpportunityId);
            if(newMembers.size() > 1) {
                newTeamMember.addError(ERROR_MSG);
                continue;
            }
            
            List<OpportunityTeamMember> existingMembers = queriedMembers.get(newTeamMember.OpportunityId);
            if(existingMembers != null && existingMembers.size() > 0) {
                newTeamMember.addError(ERROR_MSG);
            }
        }
    }
    
    @testVisible
    private Map<Id, List<OpportunityTeamMember>> getTeamMembers(Set<Id> oppIds) {
        Map<Id, List<OpportunityTeamMember>> oppIdToteamMembers = new Map<Id, List<OpportunityTeamMember>>();
        for(OpportunityTeamMember teamMember : [SELECT Id, OpportunityId FROM OpportunityTeamMember 
                                                WHERE OpportunityId IN :oppIds AND TeamMemberRole = :ALL_ACCESS_TEAM_ROLE]) {
            OpportunityTeamMember newMember = newOpportunityTeamMembersMap?.get(teamMember.Id);
            if(newOpportunityTeamMembersMap?.get(teamMember.Id) == null) {
                TriggerUtility.addSobjectValuesToMap('OpportunityId', oppIdToteamMembers, teamMember);
            }
        }
        return oppIdToteamMembers;
    }
}