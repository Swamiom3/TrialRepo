/************************************************************************************************************************************
    Author      :   Shubham Nandwana
    Description :   This trigger is a starting point for different triggers on the OpportunityContactRole object. 

    History:
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION     DATE                AUTHOR                  DETAIL
    1           27 August 2021    	Shubham Nandwana        Initial Developement
**************************************************************************************************************************************/
trigger OpportunityContactRoleTriggers on OpportunityContactRole(before insert, before update, after insert, after update, before delete){
    new MetadataDrivenTriggerHandler().run();
}