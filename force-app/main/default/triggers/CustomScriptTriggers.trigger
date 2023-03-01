/************************************************************************************************************************************
    Author         : Oleg Krasko
    Description    : This trigger is a placeholder for different triggers on the Custom Script object.
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION        DATE            AUTHOR             DETAIL
    1              17 May, 2022    Oleg Krasko        Initial Deployment
**************************************************************************************************************************************/
trigger CustomScriptTriggers on SBQQ__CustomScript__c (before insert) {
    new MetadataDrivenTriggerHandler().run();
}