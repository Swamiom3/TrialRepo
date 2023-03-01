/**********************************************************************************************************************************
    AUTHOR  : RamseySolutions
    History : --
---------------------------------------------------------------------------------------------------------------------------------
    VERSION     AUTHOR              DATE            DETAIL
    1           RamseySolutions     18/01/2016      Placeholder for different Task triggers
    2           Ishwar Shinde       17/02/2022      Migration to new trigger framework
*****************************************************************************************************************************************/

trigger TaskTriggers on Task (before insert,after insert,before update,after update) {
    new MetadataDrivenTriggerHandler().run();
}