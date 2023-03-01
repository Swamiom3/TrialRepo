/************************************************************************************************************************************
    Author      :   Alex Vashchenko
    Description :   This class should contain global constants that are not related to any business domain 
----------------------------------------------------------------------------------------------------------------------------------   
**************************************************************************************************************************************/
public with sharing class GlobalConstants {
    public static final String WEWORK = 'WeWork'; 
    public static final String WW = 'WW';
    public static final String GROUP_ID_PREFIX = '00G';
    public static final String USER_ID_PREFIX = '005';
    public static final String MIXED_TYPE = 'Mixed';
    public static final String ACCESS = 'Access';
    public static final String ALL_ACCESS = 'All Access';
    public static final String ALL_ACCESS_FREE_TRIAL = 'All Access Free Trial';
    public static final String ALL_ACCESS_DYNAMIC = 'All Access Dynamic';
    public static final String ALL_ACCESS_PAY_PER_USE = 'All Access Pay-per-Use';
    public static final String SAKSWORKS_MEMBERSHIP_MOTHLY = 'SaksWorks Membership - The Monthly';
    public static final String SAKSWORKS_LEAD_SOURCE_DETAIL = 'Self Serve SaksWorks Checkout';
    public static final Set<String> ALL_ACCESS_ALL = new Set<String>{ALL_ACCESS, ALL_ACCESS_FREE_TRIAL, ALL_ACCESS_DYNAMIC, ALL_ACCESS_PAY_PER_USE, SAKSWORKS_MEMBERSHIP_MOTHLY};
    public static final String PRIVATE_EVENT = 'Private Event';
    public static final String PX_WE = 'PxWe';
    public static final String SAAS_TYPE = 'SaaS';
    public static final String WORKPLACE = 'Workplace';
    public static final String OPP_CONTACT_ROLE_MAIN_CONTACT = 'Main Contact';
    public static final String OPP_CONTACT_ROLE_BUSINESS_USER = 'Business User';
    public static final String OPP_CONTACT_ROLE_AGENCY_BROKER = 'Agency Broker';
    public static final String ACCESS_PRODUCT_TYPE_UNIT_OF_MEASURE = 'Memberships/Month';
    public static final String SYSTEM_ADMINISTRATOR_PROFILE_NAME = 'System Administrator';
    public static final String WEWORK_SYSTEM_ADMINISTRATOR_PROFILE_NAME = 'WeWork System Administrator';
    public static final String CONSUMER = 'Consumer';
    public static final String DEFERRED = 'Deferred';
    public static final String UNOMY = 'Unomy';
    public static final String DEFAULT_OPP_CURRENCY = 'USD';
    public static final Decimal DEFAULT_OPP_SALES_PRICE = 0;
    public static final String YES = 'Yes';

    public static final String TASK_STATUS_COMPLETED = 'Completed';
    public static final String TASK_STATUS_DEFERRED = 'Deferred';
    public static final String TASK_SUBJECT_QUOTE = 'Quote';
    public static final String TASK_SUBJECT_ENGAGE_CAMPAIGN = 'Engage Campaign:';
    public static final String TASK_TYPE_SALES_INQUIRY = 'Sales Inquiry';
    public static final String TASK_TYPE_PROACTIVE_CHECKIN = 'Proactive Check-In';
    public static final String TASK_TYPE_CALL = 'Call';
    public static final String TASK_CALL_DISPOSITION_DO_NOT_CALL = 'DO NOT CALL';
    public static final String TASK_CALL_DISPOSITION_COVID19 = 'COVID-19';
    //TODO: DELETE below as they are standard API names
    public static final String OPPORTUNITY_STAGE_API_NAME = 'StageName';
    public static final String OWNER_API_NAME = 'OwnerId';
    
    public static final String JOURNEY_STATUS_ACCEPTED = 'Accepted';
    public static final String JOURNEY_STATUS_WORKING = 'Working';
    public static final String JOURNEY_STATUS_CONVERTED = 'Converted';
    public static final String JOURNEY_STATUS_KNOWN = 'Known';
    public static final String JOURNEY_STATUS_MQL = 'MQL';
    public static final String JOURNEY_STATUS_DEFERRED = 'Deferred';
    public static final String JOURNEY_STATUS_DEFERRED_REASON_AUTO = 'Auto-Complete / Expiration';

    public static final String LEAD_STATUS_WORKING = 'Working';

    public static final String ACCOUNT_TYPE_ORG = 'Org';
    public static final String ACCOUNT_TYPE_SALES = 'Sales';
    public static final String ACCOUNT_BILLING_ACCOUNT_RECORD_TYPE_DEV_NAME = 'Billing_Account';

    public static final String ACCOUNT_CONTACT_RELATION_ROLE_PRIMARY_MEMBER = 'Primary Member';
    public static final String ACCOUNT_MANAGER_TEAM_MEMBER_ROLE = 'Account Manager';

    public static final String CONTACT_TYPE_BROKER = 'Broker';
    public static final String CONTACT_LEAD_SOURCE_OUT_EMAIL_COLD_CALL = 'Outbound Email/Cold Call';

    public static final String OPPORTUNITY_FULL_MOVE_OUT_STATUS = 'Full Move-Out';
    public static final String OPPORTUNITY_PARTIAL_MOVE_OUT_STATUS = 'Partial Move-Out';
    public static final String OPPORTUNITY_STAGE_SELLING = 'Selling';
    public static final String OPPORTUNITY_STAGE_NEGOTIATING = 'Negotiating';
    public static final String OPPORTUNITY_STAGE_QUALIFYING = 'Qualifying';
    public static final String OPP_RT_NAME_RENEWAL = 'Renewal';
    public static final String OPP_CLOSED_WON_STAGE_NAME = 'Closed Won';
    public static final String OPP_CLOSED_LOST_STAGE_NAME = 'Closed Lost';
    public static final String OPP_CLOSING_STAGE_NAME = 'Closing';
    public static final String OPP_MERGED_STAGE_NAME = 'Merged';
    public static final String FROM_ADD_OPPORTUNITY = 'From Add Opportunity';
    public static final String OPPORTUNITY_CREATION_SOURCE_FROM_TOUR = 'From Manage/Book Tour';
    public static final String OPPORTUNITY_CREATION_SOURCE_VTS = 'VTS';
    public static final String OPP_REFERRAL_PORTAL_EVENT_MANUAL_CREATION = 'Manual Opportunity Creation';
    public static final String OPP_LEAD_SOURCE_BROKER_REF = 'Broker Referral';
    public static final String OPP_LEAD_SOURCE_REFERRAL = 'Referral';

    public static final String CASE_RT_NAME_REA = 'REA';
    public static final String CASE_STATUS_CLOSED = 'Closed';
    public static final String USER_ATTRIBUTE_REA = 'Real Estate Advisory';
    public static final String ACCESS_LEVEL_READ = 'Read';
    public static final Set<String> CASE_SALES_RECORDTYPE_DEV_NAMES = new Set<String>{ 'Support_Unomy', 'REA', 'Support', 'Enterprise_Finance_Strategy' };

    public static final String DATE_FORMAT_GMT = 'yyyy-MM-dd\'T\'HH:mm:ssZ';

    public static final String TOUR_COMPLETED = 'Completed';
    public static final String TOUR_NO_SHOW = 'No Show';
    public static final String TOUR_CONVERTED = 'Converted';
    public static final String TOUR_CANCELLED = 'Cancelled';
    public static final String TOUR_SCHEDULED = 'Scheduled';
    public static final String TOUR_NOT_RESCHEDULED = 'Not Rescheduled';
    public static final String TOUR_REASON_CANCELLED = 'Tour - Cancelled';
    public static final String TOUR_REASON_NO_SHOW = 'Tour - No Show';
    public static final String TOUR_SOURCE_WWDC = 'WeWork.com';

    public static final List<Schema.sObjectField> OPPORTUNITY_MULTIPICKLIST_FIELDS = new List<Schema.SObjectField>{Opportunity.Locations_Interested__c};

    public static final String EMAIL_CHARSET_UTF_8 = 'UTF-8';
    public static final String EMAIL_NO_REPLY_ORG_WIDE_ADDRESS_NAME = 'Do Not Reply';

    public static final String ACCEPT_HEADER = 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8';
    public static final String ACCEPT_ENCODING_HEADER = 'gzip, deflate, br';
    
    public static final Integer REFERRAL_RESUBMISSION_INTERVAL = 90;

    public static final String DRIFT_API_USER_NAME = 'Drift API';

    public GlobalConstants(){}
}