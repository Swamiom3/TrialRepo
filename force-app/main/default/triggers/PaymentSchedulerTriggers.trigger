/************************************************************************************************************************************
    Author         : Oleg Krasko
    Description    : This trigger is a placeholder for different triggers on the Payment Scheduler object.
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION        DATE            AUTHOR             DETAIL
    1              25 May, 2022    Oleg Krasko        Initial Deployment
**************************************************************************************************************************************/
trigger PaymentSchedulerTriggers on blng__PaymentScheduler__c (before insert) {
    new MetadataDrivenTriggerHandler().run();
}