/************************************************************************************************************************************
Author      :   Salesforce
Description :   Apex Test class for controller: LightningPicklistController ; TWSPG-9211
----------------------------------------------------------------------------------------------------------------------------------
    VERSION      DATE         AUTHOR              DETAIL
    1            03/28/2022   Salesforce          Initial creation
**************************************************************************************************************************************/
@isTest
public with sharing class LightningPicklistControllerTest {
    @isTest
    public static void getGroupOptions(){
        List<Group> groupList = LightningPicklistController.getGroupOptions();
        System.assert(groupList.size() > 0, 'Found Groups');
    }
}