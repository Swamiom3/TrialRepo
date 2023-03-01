/************************************************************************************************************************************
    Author      :   Oleg Krasko 
    Description :   This trigger is a placeholder for different triggers on the CampaignMember object. 

    History:
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION     DATE                AUTHOR                  DETAIL
    1           21 January          Oleg Krasko             initial development
**************************************************************************************************************************************/
trigger CampaignMemberTriggers on CampaignMember (before insert, before update, after insert, after update) {
    new MetadataDrivenTriggerHandler().run();
}