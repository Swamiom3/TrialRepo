/********************************************************************************************************************************
    Author 		: Milanjeet Singh
    Description : Add Opportunity Team Member on Opportunity Creation.
    History		: --
    
    Issue No. 	: ST-1599
----------------------------------------------------------------------------------------------------------------------------------
   VERSION      DATE             AUTHOR            DETAIL
      1       --             Milanjeet Singh   Initial Developement
      2       27-Aug-2020    Ashish Sharma     ST-6640
***************************************************************************************************************************************************/
trigger OpportunityTeamMemberTriggers on OpportunityTeamMember (before insert, before update,after insert, after update,before delete) {
    System.debug('In OpportunityTeamMemberTriggers Limits.getQueries() start :: '+Limits.getQueries());
    new MetadataDrivenTriggerHandler().run();
    System.debug('In OpportunityTeamMemberTriggers Limits.getQueries() end :: '+Limits.getQueries());
}