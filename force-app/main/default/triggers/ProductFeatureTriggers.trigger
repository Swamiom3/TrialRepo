/************************************************************************************************************************************
    Author         : Oleg Krasko
    Description    : This trigger is a placeholder for different triggers on the Product Feature object.
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION        DATE            AUTHOR             DETAIL
    1              4 Mar, 2022     Oleg Krasko        Initial Deployment
**************************************************************************************************************************************/
trigger ProductFeatureTriggers on SBQQ__ProductFeature__c (before insert) {
    new MetadataDrivenTriggerHandler().run();
}