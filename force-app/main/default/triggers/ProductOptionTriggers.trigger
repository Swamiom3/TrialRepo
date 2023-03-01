/************************************************************************************************************************************
    Author         : Oleg Krasko
    Description    : This trigger is a placeholder for different triggers on the Product Option object.
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION        DATE            AUTHOR             DETAIL
    1              3 Mar, 2022     Oleg Krasko        Initial Deployment
**************************************************************************************************************************************/
trigger ProductOptionTriggers on SBQQ__ProductOption__c (before insert) {
    new MetadataDrivenTriggerHandler().run();
}