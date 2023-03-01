/************************************************************************************************************************************
    Author         : Oleg Krasko
    Description    : This trigger is a placeholder for different triggers on the Lookup Query object.
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION        DATE            AUTHOR             DETAIL
    1              15 Feb, 2022    Oleg Krasko        Initial Deployment
**************************************************************************************************************************************/
trigger LookupQueryTriggers on SBQQ__LookupQuery__c (before insert) {
    new MetadataDrivenTriggerHandler().run();
}