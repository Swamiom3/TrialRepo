/************************************************************************************************************************************
    Author         : Oleg Krasko
    Description    : This trigger is a placeholder for different triggers on the Price Condition object.
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION        DATE            AUTHOR             DETAIL
    1              15 Feb, 2022    Oleg Krasko        Initial Deployment
**************************************************************************************************************************************/
trigger PriceConditionTriggers on SBQQ__PriceCondition__c (before insert) {
    new MetadataDrivenTriggerHandler().run();
}