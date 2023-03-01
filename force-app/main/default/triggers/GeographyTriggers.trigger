/************************************************************************************************************************************
    Author         : Priyanka Ambre
    Description    : GeographyTriggers
    History        :
----------------------------------------------------------------------------------------------------------------------------------
    VERSION          DATE                AUTHOR                   DETAIL
    1             07, Mar 2017        Priyanka Ambre          Initial Developement
**************************************************************************************************************************************/
trigger GeographyTriggers on Geography__c (before insert, before update) {
    new MetadataDrivenTriggerHandler().run();
}