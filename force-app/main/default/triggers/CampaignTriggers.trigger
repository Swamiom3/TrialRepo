/************************************************************************************************************************************
    Author      :   Jitesh Adwani 
    Description :   This trigger is a placeholder for different triggers on the campaign object. 

    History:
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION     DATE                AUTHOR                  DETAIL
    1           28 November 2018    Jitesh Adwani             Initial Developement
    2           09 December 2021    Krishna Somwanshi         New Trigger CampaignInsertCampaignMemberStatusTrH
**************************************************************************************************************************************/
trigger CampaignTriggers on Campaign (before insert, before update, after Insert) {
    new MetadataDrivenTriggerHandler().run();
}