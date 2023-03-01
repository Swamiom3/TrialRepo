/***********************************************************************************************************************
    Author        :  Ashish Sharma
    Description   :  Contains the logic to update the split percent on opp team members.
    Issue No.     :  ST-6640
    History       :
------------------------------------------------------------------------------------------------------------------------
    VERSION        DATE          AUTHOR           DETAIL
      1         27-Aug-2020    Ashish Sharma      ST-6640
***********************************************************************************************************************/
public with sharing class TrOppTeamMemberUpdateSplitPercent extends SObjectTriggerHandler {
    @TestVisible
    private List<OpportunityTeamMember> newOpportunityTeamMembers;
    @TestVisible
    private Map<Id, OpportunityTeamMember> newOpportunityTeamMembersMap; 
    
    public TrOppTeamMemberUpdateSplitPercent() {
        this((List<OpportunityTeamMember>) Trigger.new, (Map<Id, OpportunityTeamMember>) Trigger.newMap);
    }
    
    @TestVisible
    private TrOppTeamMemberUpdateSplitPercent(List<OpportunityTeamMember> newOpportunityTeamMembers, Map<Id, OpportunityTeamMember> newOpportunityTeamMembersMap) {
        this.newOpportunityTeamMembers = newOpportunityTeamMembers;
        this.newOpportunityTeamMembersMap = newOpportunityTeamMembersMap;
    }
    
    public override void beforeInsert() {
        WithoutSharingUtilityController.updateSplitPercentage(newOpportunityTeamMembers, newOpportunityTeamMembersMap);
    }
    
    public override void beforeUpdate() {
        WithoutSharingUtilityController.updateSplitPercentage(newOpportunityTeamMembers,  newOpportunityTeamMembersMap);    
    }
}