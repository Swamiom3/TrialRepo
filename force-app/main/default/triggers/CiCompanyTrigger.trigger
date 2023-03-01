/************************************************************************************************************************************
    Author      :   Salesforce
    Description :   This trigger is a placeholder for different triggers on the CI_Company__c object.

    History:
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION     DATE                AUTHOR                  DETAIL
    1           27 Jan 2022       Salesforce             Initial Developement
**************************************************************************************************************************************/
trigger CiCompanyTrigger on CI_Company__c (after update) {
    new MetadataDrivenTriggerHandler().run();
}