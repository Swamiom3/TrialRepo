/***********************************************************************************************************************
Author 		: 	Jitesh Adwani
Description : 	
History:
------------------------------------------------------------------------------------------------------------------------
VERSION     DATE           AUTHOR         Issue No        DETAIL
1       21 Feb 2020     Jitesh Adwani     ST-5829    Initial Development	 
2       09 April 2020   Krishana Tupe     ST-6115    Code optimization, find and Map User Attribute 
                                                     on Opportunity Team
3       27-Aug-2020     Ashish Sharma     ST-6640    Convert to new trigger framework.
***********************************************************************************************************************/
public class TrOppTeamMemberUpdateUserAttribute extends SObjectTriggerHandler {
    @TestVisible
    private List<OpportunityTeamMember> newOpportunityTeamMembers;
    
    public TrOppTeamMemberUpdateUserAttribute() {
        this((List<OpportunityTeamMember>) Trigger.new);
    }
    
    @TestVisible
    private TrOppTeamMemberUpdateUserAttribute(List<OpportunityTeamMember> newOpportunityTeamMembers) {
        this.newOpportunityTeamMembers = newOpportunityTeamMembers;
    }
    
    public override void beforeInsert() {
        updateUserAttributeForOppTeamMembers();
    }
    
    /*******************************************************************************************************************
        Author           : Krishana Tupe
        Description      : This method is used to find and map a User Attribute record on Opportunity Team Member
        Created Date     : 09 April 2020
        Issue No.        : ST-6115
        LastModifiedBy   : Ashish Sharma
        LastModifiedDate : 27-Aug-2020
        Issue            : ST-6640
    *******************************************************************************************************************/
    private void updateUserAttributeForOppTeamMembers() {         
        new OppTeamMemberUpdateUserAttributeHelper().updateUserAttribute(newOpportunityTeamMembers, false);
    }
}