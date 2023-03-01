/************************************************************************************************************************************
    Author      :   Rohit Nimase    
    Description :   This class is used to validate Originating Rep Opportunity Team Members.
    History     :   
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION     DATE                AUTHOR              ISSUE NO        DETAIL
    1           24 Nov 2020         Rohit Nimase        ST-7301         Initial Developement converting validation rule into trigger 
**************************************************************************************************************************************/
public class OppTeamMemberValidateOriginatingRepTrH extends SObjectTriggerHandler{

    private static final Set<String> BYPASS_OPP_TEAM_MEM_CREATION_SOURCE = new Set<String>{'OnOpportunityOwnerChange', 'OnAccountOwnerChange'};
    private static final Id LOGGED_IN_USER_ID = UserInfo.getUserID();
    private static final Id LOGGED_IN_USER_PROFILE_ID = UserInfo.getProfileId();
    private static final String ORIGINATING_REP_ERROR_MESSAGE = Label.Originating_Rep_Team_Member_Validation_Message;
    @TestVisible
    private List<OpportunityTeamMember> newOpportunityTeamMembers;
    private List<OpportunityTeamMember> validOppTeamMembers = new List<OpportunityTeamMember>();
    
    public OppTeamMemberValidateOriginatingRepTrH() {
        this((List<OpportunityTeamMember>) Trigger.new);        
    }
    
    @TestVisible
    private OppTeamMemberValidateOriginatingRepTrH(List<OpportunityTeamMember> newOpportunityTeamMembers) {
        this.newOpportunityTeamMembers = newOpportunityTeamMembers;        
    }
    
    public override void beforeInsert() {
        validateOriginatingRepOppTeamMembers();
    }
    
    /*******************************************************************************************************************
        Author      : Rohit Nimase
        Description : This method is used to validate Originating Rep on insert.
        Issue No.   : ST-7301
    *******************************************************************************************************************/
    @TestVisible
    private void validateOriginatingRepOppTeamMembers() {
        Set<Id> validOppIds = new Set<Id>();
        String originatingRepRole = Settings.getTeamRoleConfigSettings('OppTeamMemberValidateOriginatingRepTrH#2');
        for(OpportunityTeamMember newTeamMember : newOpportunityTeamMembers) {           
            if(newTeamMember.TeamMemberRole == originatingRepRole && !BYPASS_OPP_TEAM_MEM_CREATION_SOURCE.contains(newTeamMember.TeamMemberCreationSource__c)) {              
                validOppTeamMembers.add(newTeamMember);
                validOppIds.add(newTeamMember.OpportunityId);
            }
        }
        if(validOppIds.isEmpty()) {
            return;
        }
        Map<Id, Opportunity> validOpportunities = getValidOpportunities(validOppIds);        
        validateOriginatingRep(validOpportunities);
    }
    @TestVisible
    private Map<Id, Opportunity> getValidOpportunities(Set<Id> validOppIds) {
        return new Map<Id, Opportunity>([SELECT Id, OwnerId, 
                                         (SELECT Id, OpportunityId, UserId, TeamMemberRole FROM OpportunityTeamMembers WHERE TeamMemberRole =: Settings.getTeamRoleConfigSettings('OppTeamMemberValidateOriginatingRepTrH#1')) 
                                         FROM Opportunity WHERE Id IN :validOppIds]);
    }
    @TestVisible
    private void validateOriginatingRep(Map<Id, Opportunity> validOpportunities){
        Boolean isUserAllowedToCreateOriginatingRep = FeatureManagement.checkPermission('Allow_To_Create_Originating_Rep_Opp_Team_Member');
        for( OpportunityTeamMember newOppTeamMember : validOppTeamMembers){
            Opportunity oppRec = validOpportunities.get(newOppTeamMember.OpportunityId);
            if(isUserAllowedToCreateOriginatingRep || oppRec.OwnerId == LOGGED_IN_USER_ID){
                continue;
            }
            if(!oppRec.OpportunityTeamMembers.isEmpty() && isLoggedInUserCoOwner(oppRec.OpportunityTeamMembers)){
                continue;
            }
            newOppTeamMember.addError(ORIGINATING_REP_ERROR_MESSAGE);
        }
    }  
    @TestVisible
    private Boolean isLoggedInUserCoOwner(List<OpportunityTeamMember> oppCoOwners){
        for(OpportunityTeamMember oppCoOwner : oppCoOwners){
            if(oppCoOwner.UserId == LOGGED_IN_USER_ID){
                return true;
            }
        }
        return false;
    } 
}