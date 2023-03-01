/************************************************************************************************************************************
    Author      : Sunil Bhosale
    Description : This is trigger for Region, API name is Region__c

    History     :
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION     DATE                AUTHOR              DETAIL
    1           10 November 17      Sunil Bhosale       Initial Developement
    1           10 August   21      Ashish Sharma       Trigger Refactor
**************************************************************************************************************************************/
trigger RegionTriggers on Region__c (before insert, before update, after insert, after update) {
    new MetadataDrivenTriggerHandler().run();
}