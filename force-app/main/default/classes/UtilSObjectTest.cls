/************************************************************************************************************************************
    Author       :     Mikolaj Juras    
    Description  :     Test class for Class to Support sObect operations
    Issue No     :     ST-7780
    History      :
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION     DATE                AUTHOR              ISSUE NO        DETAIL
    1           9 April 2021       Mikolaj Juras        ST-7780         Initial Developement 
**************************************************************************************************************************************/
@isTest
public with sharing class UtilSObjectTest {
    @isTest
    private static void trimTooLongPicklistTest() {
        Opportunity oppRec1 = new Opportunity(Locations_Interested__c = 'AMS-Labs;AMS-Metropool;AMS-Strawinskylaan');
        UtilSObject.trimTooLongPicklist(oppRec1, new List<Schema.sObjectField>{Opportunity.Locations_Interested__c});
        System.assertEquals(3,  oppRec1.Locations_Interested__c.split(';').size(), 'Current size of picklist should be 3 no change applied');
        for (Integer i = 0; i < 107; i++) {
            oppRec1.Locations_Interested__c = oppRec1.Locations_Interested__c + ';' + 'test' + i;
        }
        System.assertEquals(110,  oppRec1.Locations_Interested__c.split(';').size(), 'Current size of picklist should be 110');
        UtilSObject.trimTooLongPicklist(oppRec1, new List<Schema.sObjectField>{Opportunity.Locations_Interested__c});
        System.assertEquals(100,  oppRec1.Locations_Interested__c.split(';').size(), 'Current size of picklist should be 100');
    }
}