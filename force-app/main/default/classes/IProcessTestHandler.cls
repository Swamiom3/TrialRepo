/************************************************************************************************************************************
    Author 		: 	Shobhit Gahlot
    Description : 	This Interface will be used by all the test classes.

    History		:
	----------------------------------------------------------------------------------------------------------------------------------
	VERSION		DATE				AUTHOR					DETAIL
	1			10 October 2019		Shobhit Gahlot			Initial Developement
**************************************************************************************************************************************/
public interface IProcessTestHandler {
    

     /************************************************************************************************************************************
		Author 				: 	Shobhit Gahlot
		Description 		: 	This virtual method need to override in test classes.
		Created Date		:	10 October 2019
	**************************************************************************************************************************************/
    void handleTest(List<sObject> triggerNew, Map<Id, sObject> triggerOldMap, Map<String, sobject> mapsObjectForUpdate, String event);
}