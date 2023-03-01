/************************************************************************************************************************************
    Author      :   Alex Vashchenko
    Description :   This class should contain global constants that are not related to any business domain 
----------------------------------------------------------------------------------------------------------------------------------   
**************************************************************************************************************************************/
public with sharing class CPQConstants {
    public static final String ADDONS_PRODUCTFAMILY = 'addons';
    public static final String ERROR_MESSAGE = 'Commitment term should be selected before adding promos.';
    public static final String ERROR_MESSAGE_STARTDATE = 'Start date should be selected before adding promos.';
    public static final String CLIENTID = 'client_id';
    public static final String CLIENTSECRET = 'client_secret';
    public static final String DISCOUNTS_API = 'MulesoftGetDiscountsAPI';
    public static final String CONTENT_TYPE = 'application/json;charset=UTF-8';
    public static final String COMMITMENT = 'Physical';
    public static final String MONTH = 'Month';
    public static final String ACTUAL_SOURCE = 'AddCommitmentTerm';
    public static final String ALL_ACCESS = 'All Access';
    public static final String SUBSCRIPTION_M2M = 'Month-to-Month';
    public static final String WORKSPACE = 'Workspace';
    public static final String PRODUCTCODE_COMMIT = 'PHYS-MBRSHP';
    public static final String PRODUCTCODE_M2M = 'M2M-WRKSPC';
    public static final String CHANGE_MOVEIN_DATE_ACTION = 'Change Move in Date';
    public static final String AMEND_TERM = 'Extend Term';
    public static final String ADD_ON = 'addons';
    public static final String PRODUCT_COMMIT = 'Physical Membership';
    public static final String TECH_BUNDLE = 'Technology Bundle';
    public static final String AMENDMENT_CLONE = 'Amendment Clone';
    public static final String PRODUCTCODE_CONF_ROOM_CREDIT = 'Conference Room Credit';
   
    public CPQConstants(){}
}