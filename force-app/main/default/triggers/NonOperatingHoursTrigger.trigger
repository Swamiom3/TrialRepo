/************************************************************************************************************************************
    Author      :   Salesforce
    Description :   This trigger is a placeholder for different triggers on the Non_Operating_Hours__c object.

    History:
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION     DATE                AUTHOR                  DETAIL
    1           27 Oct 2021    Salesforce             Initial Developement
**************************************************************************************************************************************/
trigger NonOperatingHoursTrigger on Non_Operating_Hours__c (after insert, before delete) {
    new MetadataDrivenTriggerHandler().run();
}