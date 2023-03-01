/************************************************************************************************************************************
    Author      :   Jake Flynt 
    Description :   This trigger is a placeholder for different triggers on the interest object. 

    History     :
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION     DATE                  AUTHOR                  DETAIL
    1           04 February 2020      Jake Flynt             Initial Developement
    2           29 September 2021     Vipul Chaudhari        Trigger Refactor
**************************************************************************************************************************************/
trigger InterestTriggers on Interest__c(before insert, before update, after insert, after update, before delete){
    new MetadataDrivenTriggerHandler().run();
}