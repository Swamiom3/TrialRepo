/************************************************************************************************************************************
    Author         : Oleg Krasko
    Description    : This trigger is a placeholder for different triggers on the Consumption Schedule object.
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION        DATE            AUTHOR             DETAIL
    1              17 May, 2022    Oleg Krasko        Initial Deployment
**************************************************************************************************************************************/
trigger ConsumptionScheduleTriggers on ConsumptionSchedule (before insert) {
    new MetadataDrivenTriggerHandler().run();   
}