/************************************************************************************************************************************
    Author         : Oleg Krasko
    Description    : This trigger is a placeholder for different triggers on the Price Book object.
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION        DATE            AUTHOR             DETAIL
    1              17 May, 2022    Oleg Krasko        Initial Deployment
**************************************************************************************************************************************/
trigger PriceBookTriggers on Pricebook2 (before insert) {
    new MetadataDrivenTriggerHandler().run();
}