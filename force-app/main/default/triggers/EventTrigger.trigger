/**********************************************************************************************************************************
AUTHOR	: Chitti Veer Raju D
History : --
---------------------------------------------------------------------------------------------------------------------------------
VERSION 	AUTHOR				DATE			DETAIL											
1			Chitti Veer Raju D	Oct 14 2020		Placeholder for different Event triggers
*****************************************************************************************************************************************/
trigger EventTrigger on Event (before insert, before update, after update, after insert, before delete, after delete, after undelete ) {
    new MetadataDrivenTriggerHandler().run();    
}