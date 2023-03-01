/************************************************************************************************************************************
    Author         : Oleg Krasko
    Description    : This trigger is a placeholder for different triggers on the Product Action object.
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION        DATE            AUTHOR             DETAIL
    1              15 Feb, 2022    Oleg Krasko        Initial Deployment
**************************************************************************************************************************************/
trigger ProductActionTriggers on SBQQ__ProductAction__c (before insert) {
    new MetadataDrivenTriggerHandler().run();
}