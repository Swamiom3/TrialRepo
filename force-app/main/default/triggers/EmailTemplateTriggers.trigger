/************************************************************************************************************************************
    Author         : Oleg Krasko
    Description    : This trigger is a placeholder for different triggers on the Email Template object.
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION        DATE            AUTHOR             DETAIL
    1              15 Feb, 2022    Oleg Krasko        Initial Deployment
**************************************************************************************************************************************/
trigger EmailTemplateTriggers on sbaa__EmailTemplate__c (before insert) {
    new MetadataDrivenTriggerHandler().run();
}