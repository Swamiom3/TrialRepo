/************************************************************************************************************************************
    Author      :   Salesforce
    Description :   This trigger is a placeholder for different triggers on the ServiceResource object.

    History:
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION     DATE                AUTHOR                  DETAIL
    1           09 Nov 2021        Salesforce             Initial Developement
**************************************************************************************************************************************/
trigger ServiceResourceTrigger on ServiceResource (after update) {
    new MetadataDrivenTriggerHandler().run();
}