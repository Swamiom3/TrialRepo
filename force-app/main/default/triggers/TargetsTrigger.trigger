/************************************************************************************************************************************
    Author      :   Chandra Teja 
    Description :   This trigger intiates the operations on targets object. 

    History:
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION     DATE                AUTHOR                  DETAIL
    1           23 April 2020       Chandra Teja            Initial Developement
    2           28 September 2021   Krishna Somwanshi       Refactor
**************************************************************************************************************************************/
trigger TargetsTrigger on Targets__c (before insert, before update, after insert, after update) {
    new MetadataDrivenTriggerHandler().run();
}