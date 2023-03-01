/************************************************************************************************************************************
    Author      :   Arun Vadduri 
    Description :   This trigger is a placeholder for different triggers on the Content Version object. 

    History:
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION     DATE                AUTHOR                  DETAIL
    1           01 November 2021    Arun Vadduri            Initial Developement
**************************************************************************************************************************************/
trigger ContentVersionTrigger on ContentVersion (after insert) {
    new MetadataDrivenTriggerHandler().run();
}