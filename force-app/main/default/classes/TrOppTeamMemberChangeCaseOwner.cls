/***********************************************************************************************************************
    Author        :  Ashish Sharma
    Description   :  Contains the logic to update the split percent on opp team members.
    Issue No.     :  ST-6640
    History       :
------------------------------------------------------------------------------------------------------------------------
    VERSION        DATE          AUTHOR           DETAIL
      1         27-Aug-2020    Ashish Sharma      ST-6640
***********************************************************************************************************************/
public with sharing class TrOppTeamMemberChangeCaseOwner extends SObjectTriggerHandler {
    @TestVisible
    private List<OpportunityTeamMember> newOpportunityTeamMembers;
    @TestVisible
    private Map<Id, OpportunityTeamMember> oldOpportunityTeamMembersMap;
    private static Map<Id, OpportunityTeamMember> preservedOpportunityIdToTeamMember = new Map<Id, OpportunityTeamMember>();
    private Map<Id, Id> oldUserIdToNewUserId;
    public TrOppTeamMemberChangeCaseOwner() {
        this((List<OpportunityTeamMember>) Trigger.new, (Map<Id, OpportunityTeamMember>) Trigger.oldMap);        
    }
    
    @TestVisible
    private TrOppTeamMemberChangeCaseOwner(List<OpportunityTeamMember> newOpportunityTeamMembers, Map<Id, OpportunityTeamMember> oldOpportunityTeamMembersMap) {
        this.newOpportunityTeamMembers = newOpportunityTeamMembers;
        this.oldOpportunityTeamMembersMap = oldOpportunityTeamMembersMap;
        oldUserIdToNewUserId = new Map<Id, Id>();
    }
    
    public override void afterInsert() {
        changeCaseOwner();
    }
    
    public override void beforeDelete() {
        preserveTeamMembers();
    }
    
    /*******************************************************************************************************************
        Author        : Ashish Sharma
        Description   : This method will change the open case owner with new owner.
        Created Date  : 27-Aug-2020
        Issue         : ST-6640
    *******************************************************************************************************************/
    private void changeCaseOwner() {
        if(preservedOpportunityIdToTeamMember.isEmpty()) {
            return;
        }
        Set<Id> deletedUsersIds = new Set<Id>();
        Set<Id> opportunityIds = new Set<Id>();
        checkValidTeamMembersToUpdateCase(opportunityIds, deletedUsersIds);
                
        if(opportunityIds.isEmpty()) {
            return;
        }
        
        List<Case> casesToUpdate = new List<Case>();
        for(Case openCase : [SELECT Id, OwnerId FROM Case 
                             WHERE IsClosed = false AND OwnerId IN :deletedUsersIds AND Opportunity__c IN :opportunityIds]) {
            setCaseOwner(openCase, casesToUpdate);
        }
        if(!casesToUpdate.isEmpty()){
            update casesToUpdate;
        }
    }
    
    private void checkValidTeamMembersToUpdateCase(Set<Id> opportunityIds, Set<Id> deletedUsersIds) {
        for(OpportunityTeamMember newTeamMember : newOpportunityTeamMembers) {
            if(preservedOpportunityIdToTeamMember.containsKey(newTeamMember.OpportunityId) 
               		&& preservedOpportunityIdToTeamMember.get(newTeamMember.OpportunityId).teamMemberRole == newTeamMember.TeamMemberRole ) {
                Id preservedTeamMemberId = preservedOpportunityIdToTeamMember.get(newTeamMember.OpportunityId).userId;
                opportunityIds.add(newTeamMember.OpportunityId);
                deletedUsersIds.add(preservedTeamMemberId);
                oldUserIdToNewUserId.put(preservedTeamMemberId, newTeamMember.UserId);
            }
        }
    }
    
    private void setCaseOwner(Case openCase, List<Case> casesToUpdate) {
        if(openCase.OwnerId != oldUserIdToNewUserId.get(openCase.OwnerId) && oldUserIdToNewUserId.containsKey(openCase.OwnerId)) {
            openCase.OwnerId = oldUserIdToNewUserId.get(openCase.OwnerId);
            casesToUpdate.add(openCase);
        }
    }
    
    /*******************************************************************************************************************
       Author        : Ashish Sharma
       Description   : This will store the deleted team members to be used in changeCaseOwner().
       Created Date  : 27-Aug-2020
       Issue         : ST-6640
    *******************************************************************************************************************/
    private void preserveTeamMembers() {
        for(OpportunityTeamMember oldTeamMember : oldOpportunityTeamMembersMap.values()){
            OpportunityTeamMember teamMember = new OpportunityTeamMember();
            teamMember.userId = oldTeamMember.UserId;
            teamMember.teamMemberRole = oldTeamMember.TeamMemberRole;
            preservedOpportunityIdToTeamMember.put(oldTeamMember.OpportunityId, teamMember);
        }
    }
}