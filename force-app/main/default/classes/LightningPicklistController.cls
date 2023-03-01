/************************************************************************************************************************************
Author      :   Salesforce
Description :   Apex controller for LWC territoryApprovalGroup, provides list of Public Groups; TWSPG-9211
----------------------------------------------------------------------------------------------------------------------------------
    VERSION      DATE         AUTHOR              DETAIL
    1            03/28/2022   Salesforce          Initial creation
**************************************************************************************************************************************/
public with sharing class LightningPicklistController {

    @AuraEnabled(cacheable=true)
    public static List<Group> getGroupOptions(){
        List<Group> groupList =  new List<Group>([SELECT Id, Name, Type FROM Group WHERE Type = 'Regular']);
        return groupList;
    }
}