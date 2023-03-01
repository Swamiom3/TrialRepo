/************************************************************************************************************************************
    Author         : Oleg Krasko
    Description    : This trigger is a placeholder for different triggers on the Price Rule object.
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION        DATE            AUTHOR             DETAIL
    1              17 May, 2022    Oleg Krasko        Initial Deployment
**************************************************************************************************************************************/
trigger PriceRuleTriggers on SBQQ__PriceRule__c (before insert) {
    new MetadataDrivenTriggerHandler().run();
}