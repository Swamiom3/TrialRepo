/************************************************************************************************************************************
	Author 		: Amol Darekar
	Description : This trigger is used for all contact triggers.

	History		:
	----------------------------------------------------------------------------------------------------------------------------------
	VERSION			DATE				AUTHOR					DETAIL							ISSUE
	1				-		            Amol Darekar	        Initial Developement		    -
**************************************************************************************************************************************/
trigger ReferralTriggers on Referral__c (before insert) {   
    new MetadataDrivenTriggerHandler().run();
}