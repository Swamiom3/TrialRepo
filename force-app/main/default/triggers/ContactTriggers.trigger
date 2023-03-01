/************************************************************************************************************************************
	Author		: Mayuresh Ghodke
	Description	: This trigger is used for all contact triggers.

	History:
	----------------------------------------------------------------------------------------------------------------------------------
	VERSION			DATE				AUTHOR				DETAIL									ISSUE
	1				27 June 2016		Mayuresh Ghodke		Initial Developement					ST-420
	2				08 April 2021		Tomasz Sadowski		Migration to new trigger framework		ST-8042
**************************************************************************************************************************************/
trigger ContactTriggers on Contact (before insert, after insert, before update, after update, after delete) {
    new MetadataDrivenTriggerHandler().run();
    
}