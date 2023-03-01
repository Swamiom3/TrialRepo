/************************************************************************************************************************************
    Author		: 	Mayuresh Ghodke
    Description	: 	AccountTriggers
    
    History	:
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION		DATE	        	AUTHOR              ISSUE NO       		DETAIL
    1	    	05 July 2016		Mayuresh Ghodke     -       			Initial Developement
	2			30 Sept 2020		Krishana Tupe		ST-3174				Code Optimization and Consolidated with new trigger structure
**************************************************************************************************************************************/
trigger AccountTriggers on Account (before insert, before update, after update, after insert, before delete, after delete, after undelete) {
    System.debug('trigger calling....');
    new MetadataDrivenTriggerHandler().run();
}