/************************************************************************************************************************************
    Author         : Oleg Krasko
    Description    : This trigger is a placeholder for different triggers on the Configuration Rule object.
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION        DATE            AUTHOR             DETAIL
    1              16 Mar, 2022    Oleg Krasko        Initial Deployment
**************************************************************************************************************************************/
trigger ConfigurationRuleTriggers on SBQQ__ConfigurationRule__c (before insert) {
    new MetadataDrivenTriggerHandler().run();
}