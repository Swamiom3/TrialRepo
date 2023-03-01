/************************************************************************************************************************************
    Author         : Oleg Krasko
    Description    : This trigger is a placeholder for different triggers on the Dunning Activity object.
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION        DATE            AUTHOR             DETAIL
    1              16 Mar, 2022    Oleg Krasko        Initial Deployment
**************************************************************************************************************************************/
trigger DunningActivityTriggers on SFBD__DunningActivity__c (before insert) {
    new MetadataDrivenTriggerHandler().run();
}