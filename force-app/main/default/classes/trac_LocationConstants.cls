/**
 * @description constants for the location sobject
 * @name trac_LocationConstants
 * @author Daniel Labonte, Traction on Demand
 * @date 2019-08-07
 */

public with sharing class trac_LocationConstants {
    public static final Map<String,Schema.RecordTypeInfo> RTINFO_LOCATION = Schema.SObjectType.Location__c.getRecordTypeInfosByDeveloperName();
    public static final String RTID_DESK = RTINFO_LOCATION.get('Desk').getRecordTypeId();
    public static final String RTID_ROOM = RTINFO_LOCATION.get('Room').getRecordTypeId();
    public static final String RTID_FLOOR = RTINFO_LOCATION.get('Floor').getRecordTypeId();
    public static final String RTID_BUILDING = RTINFO_LOCATION.get('Building').getRecordTypeId();
    public static final String RTID_PORTFOLIO = RTINFO_LOCATION.get('Portfolio').getRecordTypeId();
    public static final String RTID_TERRITORY = RTINFO_LOCATION.get('Territory').getRecordTypeId();
    public static final String RTID_REGION = RTINFO_LOCATION.get('Region').getRecordTypeId();

    /* ---------------------- ERRORS ----------------- */
    public static final String LOCATION_NAME_TOO_LONG = 'Location name too long';
}