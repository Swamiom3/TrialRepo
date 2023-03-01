/************************************************************************************************************************************
    Author         : Oleg Krasko
    Description    : This trigger is a placeholder for different triggers on the Revenue Recognition Rule object.
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION        DATE            AUTHOR             DETAIL
    1              17 May, 2022    Oleg Krasko        Initial Deployment
**************************************************************************************************************************************/
trigger RevenueRecognitionTriggers on blng__RevenueRecognitionRule__c (before insert) {
    new MetadataDrivenTriggerHandler().run();
}