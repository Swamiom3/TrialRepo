/**
 * @description unit tests for the org constants class
 * @name TLOrgConstantsTest
 * @author Daniel Labonte, Traction on Demand
 * @date 2019-09-11
 */
@IsTest
public with sharing class TLOrgConstantsTest {
    @IsTest
    static void testConstants() {
        System.assertEquals(TLOrgConstants.PROFILE_SYSTEM_ADMIN,'System Administrator');

        System.assertEquals(TLOrgConstants.QUEUE_ACE_DEVNAME, 'Ace_Team', 'Constant was changed without test being updated');
        System.assertEquals(TLOrgConstants.QUEUE_INTERR_DEVNAME, 'Interr_Team', 'Constant was changed without test being updated');

        System.assertEquals(TLOrgConstants.CASE_CATEGORY_BILL_PAY_ADD,'Billing, Payments and Add-ons');
        System.assertEquals(TLOrgConstants.CASE_CATEGORY_IT_SUPPORT,'Technology Hardware Support');
        System.assertEquals(TLOrgConstants.CASE_CATEGORY_REPAIR_MAINT,'Repair and Maintenance');
        System.assertEquals(TLOrgConstants.CASE_CATEGORY_SECURITY,'Security');
        System.assertEquals(TLOrgConstants.CASE_CATEGORY_KEYCARD,'KeyCard');
        System.assertEquals(TLOrgConstants.CASE_CATEGORY_APP_DIGITAL_PROD,'Apps and Digital Products');
        System.assertEquals(TLOrgConstants.CASE_CATEGORY_FOOD_BEV,'Food and Beverage');
        System.assertEquals(TLOrgConstants.CASE_CATEGORY_CLEANING,'Cleaning');
        System.assertEquals(TLOrgConstants.CASE_CATEGORY_EVENTS_BENEFITS,'Events and benefits');
        System.assertEquals(TLOrgConstants.CASE_CATEGORY_MAN_CONTR_UPLOAD_REQ,'Manual Contract Upload Request (HP)');
        System.assertEquals(TLOrgConstants.CASE_CATEGORY_FFNE_INSTAL,'FF&E Installations');
        System.assertEquals(TLOrgConstants.CASE_CATEGORY_LEGAL,'Legal');
        System.assertEquals(TLOrgConstants.CASE_CATEGORY_MIMO,'MIMO');
        System.assertEquals(TLOrgConstants.CASE_CATEGORY_GROWTH_PARTNER,'Growth and Partnership');

        System.assertEquals(TLOrgConstants.CASE_TYPE_PRINT_ISSUE,'Print Issue');

        System.assertEquals(TLOrgConstants.CASE_ORIGIN_PHONE,'Phone');
        System.assertEquals(TLOrgConstants.CASE_ORIGIN_EMAIL,'Email');
        System.assertEquals(TLOrgConstants.CASE_ORIGIN_WEB,'Web');

        System.assertEquals(TLOrgConstants.CASE_STATUS_NEW,'New');
        System.assertEquals(TLOrgConstants.CASE_STATUS_CLOSED,'Closed');
        System.assertEquals(TLOrgConstants.CASE_STATUS_SOLVED,'Solved');
        System.assertEquals(TLOrgConstants.CASE_STATUS_WAITING,'Waiting_on_Support_Request_Submitter');
        System.assertEquals(TLOrgConstants.CASE_STATUS_WAITING_ON_EXTERNAL_PARTY, 'Waiting_on_Vendor/Contractor', 'Constant was changed without test being updated');

        System.assertEquals(TLOrgConstants.BUSINESS_HOUR_EASTERN_DAYLIGHT,'Eastern Daylight (America/New York)');

        System.assertEquals(TLOrgConstants.SUPPORT_REQUEST_RECORD_TYPE_ID,Schema.SObjectType.Case.getRecordTypeInfosByName().get('Support Request').getRecordTypeId());
        System.assertEquals(TLOrgConstants.BUILDING_RECORD_TYPE_ID,Schema.SObjectType.Location__c.getRecordTypeInfosByName().get('Building').getRecordTypeId());
        System.assertEquals(TLOrgConstants.OPPORTUNITY_STAGE_NAME_CLOSED_WON,'Closed Won');
        System.assertEquals(TLOrgConstants.OPPORTUNITY_STAGE_NAME_CLOSED_LOST,'Closed Lost');
        System.assertEquals(TLOrgConstants.LOCATION_NAME_TOO_LONG,'Location name too long');
//        System.assertEquals(TLOrgConstants.CATEGORY_ICON_MAP,'TODO');
        System.assertEquals(TLOrgConstants.AGENT_SESSION_ICON,'utility:agent_session');
        System.assertEquals(TLOrgConstants.CALL_ME_BACK_NAMED_CREDENTIALS,'CallMeBack');
        System.assertEquals(TLOrgConstants.CASE_LINE_OF_BUSINESS_WEWORK,'WeWork');
        System.assertEquals(TLOrgConstants.CASE_LINE_OF_BUSINESS_WELIVE,'WeLive');
        System.assertEquals(TLOrgConstants.CASE_LINE_OF_BUSINESS_HQXWE,'HQxWe');
        System.assertEquals(TLOrgConstants.CHECKLIST_SUPPORT_REQUEST_SUBJECT,'Checklist');
        System.assertEquals(TLOrgConstants.PRODUCT_NAMES_PHYSICAL,new List<String>{'Physical'});
        System.assertEquals(TLOrgConstants.PRODUCT_NAMES_VIRTUAL,new List<String>{'HotDesk'});
        System.assertEquals(TLOrgConstants.MEMBERSHIP_TYPE_PHYSICAL,'Physical');
        System.assertEquals(TLOrgConstants.MEMBERSHIP_TYPE_VIRTUAL,'Virtual');
    }
}