/************************************************************************************************************************************
    Author      :   Shubham Nandwana
    Description :   This trigger is a placeholder for different triggers on the AccountContactRelation object. 

    History:
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION     DATE                AUTHOR                  DETAIL
    1           30 August 2021    	Shubham Nandwana        Initial Developement
**************************************************************************************************************************************/
trigger AccountContactRelationTriggers on AccountContactRelation(before insert, before update, after insert, after update, before delete){
    new MetadataDrivenTriggerHandler().run();
}