/***********************************************************************************************************************
    Author 		: Nikhil Mehta
    Description : This trigger is used to restrict co-owner.
    Issue No. 	: ST-3704
------------------------------------------------------------------------------------------------------------------------
    VERSION     DATE            AUTHOR          DETAIL
     1       15 April 2019   Nikhil Mehta   Initial Developement
     2       27-Aug-2020     Ashish Sharma  ST-6640
***********************************************************************************************************************/
public class TrOpportunityTeamMemberRestrictCoOwner extends SObjectTriggerHandler {
    @TestVisible
    private List<OpportunityTeamMember> newOpportunityTeamMembers;
    @TestVisible
    private Map<Id, OpportunityTeamMember> oldOpportunityTeamMembersMap;
    private Map<Id, Integer> opportunitiesToCoOwnerCount;
    private final String ERROR_MESSAGE = 'Only two co-owners are permitted per opportunity team.';
    private final Integer MAX_ALLOWED = 2;
    private String coOwnerErrorMessage;
    private Set<Id> opportunitiesId;
    
    public TrOpportunityTeamMemberRestrictCoOwner() {
        this((List<OpportunityTeamMember>) Trigger.new, (Map<Id, OpportunityTeamMember>) Trigger.oldMap);
    }
    
    @TestVisible
    private TrOpportunityTeamMemberRestrictCoOwner(List<OpportunityTeamMember> newOpportunityTeamMembers, Map<Id, OpportunityTeamMember> oldOpportunityTeamMembersMap) {
        this.newOpportunityTeamMembers = newOpportunityTeamMembers;
        this.oldOpportunityTeamMembersMap = oldOpportunityTeamMembersMap;
        opportunitiesToCoOwnerCount = new Map<Id, Integer>();
        coOwnerErrorMessage = getCoOwnerErrorMessage();
        opportunitiesId = new Set<Id>();
    }
    
    public override void beforeInsert() {
        restrictCoOwner();
    }
    
    public override void beforeUpdate() {
        restrictCoOwner();
    }
    
    /*******************************************************************************************************************
        Author        : Ashish Sharma
        Description   : This method will limit 2 team members with co-owner role.
        Created Date  : 27-Aug-2020
        Issue         : ST-6640	
    *******************************************************************************************************************/
    private void restrictCoOwner() {
        String coOwnerRole = Settings.getTeamRoleConfigSettings('TrOpportunityTeamMemberRestrictCoOwner#1');
        for(OpportunityTeamMember newTeamMember : newOpportunityTeamMembers) {
            Boolean isTeamRoleCoOwner = isTeamRoleCoOwner(newTeamMember, coOwnerRole);
            Boolean isUpdate = (this.context == TriggerContext.BEFORE_UPDATE);
            if(!isTeamRoleCoOwner) {
                continue;
            }
            if(isUpdate && !isTeamRoleChanged(newTeamMember)) {
                continue;
            }
            opportunitiesId.add(newTeamMember.OpportunityId);
            if(opportunitiesToCoOwnerCount.containsKey(newTeamMember.OpportunityId)) {
                Integer count = opportunitiesToCoOwnerCount.get(newTeamMember.OpportunityId);
                count += 1;
                opportunitiesToCoOwnerCount.put(newTeamMember.OpportunityId, count);
                if(hasAllowedCoOwnerReachedLimit(count)) {
                    newTeamMember.addError(coOwnerErrorMessage);
                }
            } else {
                opportunitiesToCoOwnerCount.put(newTeamMember.OpportunityId, 1);
            }
        }
        
        if(opportunitiesId.isEmpty()) {
            return;
        }       
        Map<Id, Opportunity> queriedOpportunities = getOpportunities();
        String coOwnerRole3 = Settings.getTeamRoleConfigSettings('TrOpportunityTeamMemberRestrictCoOwner#3');
        for(OpportunityTeamMember newTeamMember : newOpportunityTeamMembers) {
            if(hasAllowedCoOwnerReachedLimit(newTeamMember, queriedOpportunities, coOwnerRole3)) {
                newTeamMember.addError(coOwnerErrorMessage);
            }
        }
    }
    
    private Boolean isTeamRoleCoOwner(OpportunityTeamMember newTeamMember, String coOwnerRole) {
        return (newTeamMember.TeamMemberRole == coOwnerRole);
    }
    
    private Boolean isTeamRoleChanged(OpportunityTeamMember newTeamMember) {
        if(oldOpportunityTeamMembersMap == null || oldOpportunityTeamMembersMap.isEmpty()) {
            return false;
        }
        OpportunityTeamMember oldTeamMember = oldOpportunityTeamMembersMap.get(newTeamMember.Id);
        return (oldTeamMember.TeamMemberRole != newTeamMember.TeamMemberRole);
    }
    
    private String getCoOwnerErrorMessage() {
        MetadataSetting__mdt restrictCoOwnerMetaData = Settings.getMetadataSetting('Allowed_CoOwner');
        Map<String, Object> restrictCoOwner;
        if(restrictCoOwnerMetaData != null && String.isNotBlank(restrictCoOwnerMetaData.Data__c)) {
            restrictCoOwner = (Map<String, Object>)JSON.deserializeUntyped(restrictCoOwnerMetaData.Data__c);
        }
        Map<String, Object> mapErrorsMessages = restrictCoOwner.get('errorMessages') != null ? (Map<String, Object>) restrictCoOwner.get('errorMessages') 
            																				 : null;
        return (mapErrorsMessages != null && mapErrorsMessages.get('Co-OwnerExist') != null)
            		? String.format(String.valueOf(mapErrorsMessages.get('Co-OwnerExist')), new List<Object> {MAX_ALLOWED}) 
            		: ERROR_MESSAGE;
    }
    
    private Boolean hasAllowedCoOwnerReachedLimit(Integer count) {
        return (count > MAX_ALLOWED);
    }
    
    private Boolean hasAllowedCoOwnerReachedLimit(OpportunityTeamMember newTeamMember, Map<Id, Opportunity> queriedOpportunities, String coOwnerRole) {
        Opportunity queriedOpp = queriedOpportunities.get(newTeamMember.OpportunityId);
        if(!newTeamMember.TeamMemberRole.equalsIgnoreCase(coOwnerRole) || queriedOpp == null) {
            return false;
        }
        List<OpportunityTeamMember> oppTeamMembers = queriedOpp.OpportunityTeamMembers;
        if(oppTeamMembers.isEmpty()) {
            return false;
        }
        Integer totalCoOwnerCount = oppTeamMembers.size() + opportunitiesToCoOwnerCount.get(newTeamMember.OpportunityId);
        return hasAllowedCoOwnerReachedLimit(totalCoOwnerCount);
    }
    
    private Map<Id, Opportunity> getOpportunities() {
        String coOwner = Settings.getTeamRoleConfigSettings('TrOpportunityTeamMemberRestrictCoOwner#2');
        return new Map<Id, Opportunity>([SELECT Id, OwnerId, 
                                                (SELECT Id, TeamMemberRole FROM OpportunityTeamMembers 
                                                 WHERE TeamMemberRole = :coOwner) 
                                         FROM Opportunity WHERE Id IN : opportunitiesId]);
    }   
}