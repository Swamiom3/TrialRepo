/************************************************************************************************************************************
    Author         : Oleg Krasko
    Description    : This trigger is a placeholder for different triggers on the Approval Chain object.
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION        DATE            AUTHOR             DETAIL
    1              17 May, 2022    Oleg Krasko        Initial Deployment
**************************************************************************************************************************************/
trigger ApprovalChainTriggers on sbaa__ApprovalChain__c (before insert) {
    new MetadataDrivenTriggerHandler().run();
}