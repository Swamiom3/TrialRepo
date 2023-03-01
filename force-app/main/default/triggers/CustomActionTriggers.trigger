/************************************************************************************************************************************
    Author         : Oleg Krasko
    Description    : This trigger is a placeholder for different triggers on the Custom Action object.
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION        DATE            AUTHOR             DETAIL
    1              30 Apr, 2022    Oleg Krasko        Initial Deployment
**************************************************************************************************************************************/
trigger CustomActionTriggers on SBQQ__CustomAction__c (before insert) {
    new MetadataDrivenTriggerHandler().run();
}