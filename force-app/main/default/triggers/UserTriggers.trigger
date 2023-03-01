/************************************************************************************************************************************
    Author 		: ajaysinh chauhan
    Description : ---
    History		: -- 

----------------------------------------------------------------------------------------------------------------------------------
	VERSION	 	DATE	        	AUTHOR            	  DETAIL
    1	     	17, Sep 2016		ajaysinh chauhan  	  Initial Developement
    2	     	8, March 2020		Oleksandr Vashchenko  Joined trigger frameworks
**************************************************************************************************************************************/

trigger UserTriggers on User (before insert, before update, after update,after insert) {
    new MetadataDrivenTriggerHandler().run();
}