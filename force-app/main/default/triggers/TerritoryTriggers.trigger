/************************************************************************************************************************************
	Author			:	Ajaysinh Chauhan
	Description 	:	This trigger handles the all operations after upating Territory object

	History :
	----------------------------------------------------------------------------------------------------------------------------------
	VERSION			DATE	        		 AUTHOR                     DETAIL
	1			04 December 2017	 	 Ajaysinh Chauhan           Initial Developement
	2			24-Aug-2021      		 Shobhit Gahlot             Trigger Refactor
**************************************************************************************************************************************/
trigger TerritoryTriggers on Territory__c (after update) {
    new MetadataDrivenTriggerHandler().run();
}