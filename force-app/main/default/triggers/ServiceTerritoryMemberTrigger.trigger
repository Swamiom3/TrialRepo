/************************************************************************************************************************************
    Author      :   Salesforce
    Description :   This trigger is a placeholder for different triggers on the ServiceTerritoryMember object.

    History:
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION     DATE                AUTHOR                  DETAIL
    1           27 Oct 2021    Salesforce             Initial Developement
**************************************************************************************************************************************/
trigger ServiceTerritoryMemberTrigger on ServiceTerritoryMember (after insert, after update) {
    new MetadataDrivenTriggerHandler().run();
}