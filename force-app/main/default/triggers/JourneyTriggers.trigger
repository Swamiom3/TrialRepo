/************************************************************************************************************************************
    Author         : Amol Darekar
    Description : ---

    History        :
----------------------------------------------------------------------------------------------------------------------------------
    VERSION      DATE           AUTHOR               DETAIL
    1         17,May 2016    Amol Darekar       Initial Developement
    2         09-Sept-2021   Shobhit Gahlot     Trigger Refactor
**************************************************************************************************************************************/

trigger JourneyTriggers on Journey__c (before insert,before update,after insert,after update) {    
    new MetadataDrivenTriggerHandler().run();
}