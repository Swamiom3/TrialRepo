/************************************************************************************************************************************
    Author         : Oleg Krasko
    Description    : This trigger is a placeholder for different triggers on the Approval Condition object.
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION        DATE            AUTHOR             DETAIL
    1              15 Feb, 2022    Oleg Krasko        Initial Deployment
**************************************************************************************************************************************/
trigger ApprovalConditionTriggers on sbaa__ApprovalCondition__c (before insert, after insert) {
    new MetadataDrivenTriggerHandler().run();
}