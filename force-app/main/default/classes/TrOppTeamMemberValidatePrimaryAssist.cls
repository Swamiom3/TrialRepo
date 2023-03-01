/***********************************************************************************************************************
    Author        :  Ashish Sharma
    Description   :  Add Opportunity Team Member on Opportunity Creation.
    Issue No.     :  ST-6640
    History       :
------------------------------------------------------------------------------------------------------------------------
    VERSION        DATE          AUTHOR           DETAIL
      1         27-Aug-2020    Ashish Sharma      ST-6640
***********************************************************************************************************************/
public with sharing class TrOppTeamMemberValidatePrimaryAssist extends SObjectTriggerHandler {
    @TestVisible
    private List<OpportunityTeamMember> newOpportunityTeamMembers;
    private Map<Id, Set<OpportunityTeamMember>> opportunityIdToTeamMembers;
    private final String PRIMARY_ASSIST_ERROR_MESSAGE = Label.Team_Member_Primary_Assist_Validation_Message;
    
    public TrOppTeamMemberValidatePrimaryAssist() {
        this((List<OpportunityTeamMember>) Trigger.new);        
    }
    
    @TestVisible
    private TrOppTeamMemberValidatePrimaryAssist(List<OpportunityTeamMember> newOpportunityTeamMembers) {
        this.newOpportunityTeamMembers = newOpportunityTeamMembers;
        opportunityIdToTeamMembers = new Map<Id, Set<OpportunityTeamMember>>();
    }
    
    public override void beforeInsert() {
        validatePrimaryAssistOnInsert();
    }
    
    public override void beforeUpdate() {
        validatePrimaryAssistOnUpdate();
    }
    
    /*******************************************************************************************************************
        Author      : Ashish Sharma
        Description : Validating the primary assist on insert.
        Issue No.   : ST-6640
    *******************************************************************************************************************/
    private void validatePrimaryAssistOnInsert() {
        setOpportunityIdToTeamMembers();
        if(opportunityIdToTeamMembers.isEmpty()) {
            return;
        }
        Set<Id> validOpportunities = new Set<Id>();        
        for(Id oppId: opportunityIdToTeamMembers.keyset()) {
            if(opportunityIdToTeamMembers.get(oppId).size() < 2){
                validOpportunities.add(oppId);
            } 
        }
        
        Map<Id, Opportunity> queriedOpportunities = getOpportunities(validOpportunities);        
        for(OpportunityTeamMember newTeamMember: newOpportunityTeamMembers){
            if(opportunityIdToTeamMembers.containsKey(newTeamMember.OpportunityId)
                    && opportunityIdToTeamMembers.get(newTeamMember.OpportunityId).size() > 1) {
                newTeamMember.addError(PRIMARY_ASSIST_ERROR_MESSAGE);
            } else {
                validatePrimaryAssist(newTeamMember, queriedOpportunities);
            }
        }
    }
    
    /*******************************************************************************************************************
        Author      : Ashish Sharma
        Description : Validating the primary assist on update.
        Issue No.   : ST-6640
    *******************************************************************************************************************/
    private void validatePrimaryAssistOnUpdate() {
        Set<Id> validOpportunities = getValidOpportunities();
        if(validOpportunities.isEmpty()) {
            return;
        }      
        
        Map<Id, Opportunity> queriedOpportunities = getOpportunities(validOpportunities);
        for(OpportunityTeamMember newTeamMember: newOpportunityTeamMembers) {
            validatePrimaryAssist(newTeamMember, queriedOpportunities);
        }
    }
    
    private Set<Id> getValidOpportunities() {
        Set<Id> validOpportunities = new Set<Id>();
        for(OpportunityTeamMember newTeamMember :newOpportunityTeamMembers) {
            if(newTeamMember.Primary_Tour_Assist__c) {
                validOpportunities.add(newTeamMember.OpportunityId);
            }
        }
        return validOpportunities;
    }
    
    private void setOpportunityIdToTeamMembers() {
        for(OpportunityTeamMember newTeamMember :newOpportunityTeamMembers) {
            if(newTeamMember.Primary_Tour_Assist__c) {
                addTeamMemberToMap(newTeamMember);
            }
        }
    }
    
    private void addTeamMemberToMap(OpportunityTeamMember newTeamMember) {
        Set<OpportunityTeamMember> opportunityTeamMembers = new Set<OpportunityTeamMember>();
        Id opportunityId = newTeamMember.OpportunityId;
        if(opportunityIdToTeamMembers.containsKey(opportunityId)) {                    
            opportunityTeamMembers = opportunityIdToTeamMembers.get(opportunityId);
            opportunityTeamMembers.add(newTeamMember);
            opportunityIdToTeamMembers.put(opportunityId, opportunityTeamMembers);
        } else {
            opportunityIdToTeamMembers.put(opportunityId, new Set<OpportunityTeamMember>{newTeamMember});
        }
    }
    
    private Map<Id, Opportunity> getOpportunities(Set<Id> validOpportunities) {
        return new Map<Id, Opportunity>([SELECT Id, (SELECT Id, OpportunityId, UserId, TeamMemberRole, OpportunityAccessLevel 
                                                     FROM OpportunityTeamMembers WHERE Primary_Tour_Assist__c = true) 
                                         FROM Opportunity WHERE Id IN :validOpportunities]);
    }
    
    public void validatePrimaryAssist(OpportunityTeamMember newTeamMember, Map<Id, Opportunity> queriedOpportunities){
        Opportunity queriedOpportunity = queriedOpportunities.get(newTeamMember.OpportunityId);
        if(queriedOpportunity == null || !newTeamMember.Primary_Tour_Assist__c){
            return;
        }
        List<OpportunityTeamMember> opportunityTeamMembers = queriedOpportunity.OpportunityTeamMembers;
        if(opportunityTeamMembers.isEmpty() || opportunityTeamMembers[0].UserId == newTeamMember.UserId) {
            return;
        }
        newTeamMember.addError(PRIMARY_ASSIST_ERROR_MESSAGE);
    }
}