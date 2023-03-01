/**
 * @description lass to hold all constant data / values such as picklists, record types, formats,
 *              response codes for callouts, error messages etc. that are specific to this org.
 * @name TLOrgConstants
 * @author Daniel Labonte, Traction on Demand
 * @date 2019-07-31
 */

public class TLOrgConstants {

    /* ---------------------- GENERAL ----------------- */

    // Profiles
    public static final String PROFILE_SYSTEM_ADMIN = 'System Administrator';

    // Queues
    public static final String QUEUE_ACE_DEVNAME = 'Ace_Team';
    public static final String QUEUE_INTERR_DEVNAME = 'Interr_Team';

    // Public Groups
    public static final String GROUP_MEMBER_SUPPORT_TEAM = 'Member_Support_Team';


    /* ---------------------- CASE ----------------- */
    //Case type values
    public static final String CASE_TYPE_PRINT_ISSUE = 'Print Issue';

    // Origin Values
    public static final String CASE_ORIGIN_PHONE = 'Phone';
    public static final String CASE_ORIGIN_PRINTER_EMAIL = 'Printer Email';
    public static final String CASE_ORIGIN_EMAIL = 'Email';
    public static final String CASE_ORIGIN_WEB = 'Web';

    // Status Values
    public static final String CASE_STATUS_NEW = 'New';
    public static final String CASE_STATUS_INPROGRESS = 'In Progress';
    public static final String CASE_STATUS_CLOSED = 'Closed';
    public static final String CASE_STATUS_SOLVED = 'Solved';
    public static final String CASE_STATUS_WAITING = 'Waiting_on_Support_Request_Submitter';
    public static final String CASE_STATUS_WAITING_ON_EXTERNAL_PARTY = 'Waiting_on_Vendor/Contractor';

    // category values
    public static final String CASE_CATEGORY_BILL_PAY_ADD = 'Billing, Payments and Add-ons';
    public static final String CASE_CATEGORY_IT_SUPPORT = 'Technology Hardware Support';
    public static final String CASE_CATEGORY_TECHNOLOGY_SERVICES = 'Technology Services';
    public static final String CASE_CATEGORY_REPAIR_MAINT = 'Repair and Maintenance';
    public static final String CASE_CATEGORY_SECURITY = 'Security';
    public static final String CASE_CATEGORY_KEYCARD = 'KeyCard';
    public static final String CASE_CATEGORY_APP_DIGITAL_PROD = 'Apps and Digital Products';
    public static final String CASE_CATEGORY_FOOD_BEV = 'Food and Beverage';
    public static final String CASE_CATEGORY_CLEANING = 'Cleaning';
    public static final String CASE_CATEGORY_EVENTS_BENEFITS = 'Events and benefits';
    public static final String CASE_CATEGORY_MAN_CONTR_UPLOAD_REQ = 'Manual Contract Upload Request (HP)';
    public static final String CASE_CATEGORY_FFNE_INSTAL = 'FF&E Installations';
    public static final String CASE_CATEGORY_LEGAL = 'Legal';
    public static final String CASE_CATEGORY_MIMO = 'MIMO';
    public static final String CASE_CATEGORY_GROWTH_PARTNER = 'Growth and Partnership';
    public static final String CASE_CATEGORY_WALKTHROUGH_COMPLETED ='Walkthrough Completed';
    //Default BusinessHour
    public static final String BUSINESS_HOUR_EASTERN_DAYLIGHT = 'Eastern Daylight (America/New York)';

    //Case RecordType
    public static final Id SUPPORT_REQUEST_RECORD_TYPE_ID = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Support Request').getRecordTypeId();

    //Location Record Type
    public static final Id BUILDING_RECORD_TYPE_ID = Schema.SObjectType.Location__c.getRecordTypeInfosByName().get('Building').getRecordTypeId();

    //Case RecordType
    public static final Id PERSON_ACCOUNT_RECORD_TYPE_ID = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Person Account').getRecordTypeId();

    /* ---------------------- OPPORTUNITY ----------------- */
    // StageName Values
    // TODO add values
    public static final String OPPORTUNITY_STAGE_NAME_CLOSED_WON = 'Closed Won';
    public static final String OPPORTUNITY_STAGE_NAME_CLOSED_LOST = 'Closed Lost';

    /* ---------------------- ERRORS ----------------- */
    public static final String LOCATION_NAME_TOO_LONG = 'Location name too long';


    /* -------------------------- CATEGORY ICONS ----------------------- */
    public static final Map<String, String> CATEGORY_ICON_MAP =
            new Map<String, String>{
                    CASE_CATEGORY_BILL_PAY_ADD => 'utility:currency',
                    CASE_CATEGORY_IT_SUPPORT => 'utility:dialing',
                    CASE_CATEGORY_REPAIR_MAINT => 'utility:settings',
                    CASE_CATEGORY_SECURITY => 'utility:lock',
                    CASE_CATEGORY_KEYCARD => 'utility:pinned',
                    CASE_CATEGORY_APP_DIGITAL_PROD => 'utility:apps',
                    CASE_CATEGORY_FOOD_BEV => 'utility:food_and_drink',
                    CASE_CATEGORY_CLEANING => 'utility:bucket',
                    CASE_CATEGORY_EVENTS_BENEFITS => 'utility:event',
                    CASE_CATEGORY_MAN_CONTR_UPLOAD_REQ => 'utility:upload',
                    CASE_CATEGORY_FFNE_INSTAL => 'utility:apex_plugin',
                    CASE_CATEGORY_LEGAL => 'utility:quote',
                    CASE_CATEGORY_MIMO => 'utility:move',
                    CASE_CATEGORY_GROWTH_PARTNER => 'utility:groups',
                    CASE_CATEGORY_TECHNOLOGY_SERVICES => 'utility:dialing',
                    CASE_CATEGORY_WALKTHROUGH_COMPLETED => 'utility:settings'
            };

    public static final String AGENT_SESSION_ICON = 'utility:agent_session';

    public static final String CALL_ME_BACK_NAMED_CREDENTIALS = 'CallMeBack';

    public static final String CASE_LINE_OF_BUSINESS_WEWORK = 'WeWork';
    public static final String CASE_LINE_OF_BUSINESS_WELIVE = 'WeLive';
    public static final String CASE_LINE_OF_BUSINESS_HQXWE = 'HQxWe';

    public static final String CHECKLIST_SUPPORT_REQUEST_SUBJECT = 'Checklist';

    public static final String WEWORK_SUPPORT_ORG_WIDE = 'WeWork Support';

    public static final String ROOTCAUSE = 'Not Applicable';
    /* ---------------------- ASSET/MEMBERSHIP ----------------- */
    public static final List<String> PRODUCT_NAMES_PHYSICAL = new List<String>{'Physical'};
    public static final List<String> PRODUCT_NAMES_VIRTUAL = new List<String>{'HotDesk'};
    public static final String MEMBERSHIP_TYPE_PHYSICAL = 'Physical';
    public static final String MEMBERSHIP_TYPE_VIRTUAL = 'Virtual';

    /* ----------------------- String Separator --------------------------- */
    public static final String SEPARATOR = ' *** ';
}