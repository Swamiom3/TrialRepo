/************************************************************************************************************************************
Author      :   Roshan kankrayane 	
Description :   This class will contain all the test method of TrJourneyUpdateMQLIdentifiedon.
Issue No    : 	ST-5550
History		:
----------------------------------------------------------------------------------------------------------------------------------
VERSION     DATE                AUTHOR                        DETAIL
1           20 March 2020     Roshan kankrayane             Initial Developement
2           12 August, 2021    	Andrei Dedovets             Refactored to SObjectTriggerHandler
**************************************************************************************************************************************/
@isTest
public class JourneyUpdateMQLIdentifiedOnTrHTest {

    @isTest
    private static void setMqlIdentifiedOnTest() {
        User driftApiUser = [SELECT Id from User WHERE Name = :GlobalConstants.DRIFT_API_USER_NAME LIMIT 1];
        
        List<Journey__c> journeys = getJourney();
        Map<Id, Journey__c> journeysMap = new Map<Id, Journey__c>(journeys);

        Test.startTest();
        System.runAs(driftApiUser) {
            JourneyUpdateMQLIdentifiedOnTrH instance = new JourneyUpdateMQLIdentifiedOnTrH();
            instance.newJourneys = journeys;
            instance.oldJourneysMap = journeysMap;
            instance.beforeInsert();
        }
        Test.stopTest();

        System.assertEquals(Date.today(), journeys[0].MQL_Identified_On__c, 'MQL_Identified_On__c should not be null'); 
    }

    @isTest
    private static void setMqlIdentifiedOnNegativeTest() {
        User driftApiUser = [SELECT Id from User WHERE Name = :GlobalConstants.DRIFT_API_USER_NAME LIMIT 1];
        
        List<Journey__c> journeys = getJourney();
        Map<Id, Journey__c> journeysMap = new Map<Id, Journey__c>(journeys);

        Test.startTest();
        JourneyUpdateMQLIdentifiedOnTrH instance = new JourneyUpdateMQLIdentifiedOnTrH();
        instance.newJourneys = journeys;
        instance.oldJourneysMap = journeysMap;
        instance.beforeInsert();
        Test.stopTest();

        System.assertEquals(null, journeys[0].MQL_Identified_On__c, 'MQL_Identified_On__c should be null'); 
    }

    @isTest
    private static void updateMQLIdentifiedonJourneyTest() {
        List<Journey__c> journeys = getJourney();
        Map<Id, Journey__c> journeysMap = new Map<Id, Journey__c>(journeys.deepClone(true, false, false));
        journeysMap.values()[0].Status__c = 'known';
        journeys[0].Status__c = 'working';
        
        Test.startTest();
        JourneyUpdateMQLIdentifiedOnTrH instance = new JourneyUpdateMQLIdentifiedOnTrH();
        instance.oldJourneysMap = journeysMap;
        instance.newJourneys = journeys;
        instance.beforeUpdate();
        Test.stopTest();

        System.assertEquals(Date.today(), journeys[0].MQL_Identified_On__c, 'MQL_Identified_On__c should not be null');
    }

    @isTest
    private static void updateMQLIdentifiedonJourneyNegativeTest() {
        List<Journey__c> journeys = getJourney();
        Map<Id, Journey__c> journeysMap = new Map<Id, Journey__c>(journeys.deepClone(true, false, false));
        journeysMap.values()[0].Status__c = 'known';
        
        Test.startTest();
        JourneyUpdateMQLIdentifiedOnTrH instance = new JourneyUpdateMQLIdentifiedOnTrH();
        instance.oldJourneysMap = journeysMap;
        instance.newJourneys = journeys;
        instance.beforeUpdate();
        Test.stopTest();

        System.assertEquals(null, journeys[0].MQL_Identified_On__c, 'MQL_Identified_On__c should be null');
    }

    private static List<Journey__c> getJourney() {
        return new List<Journey__c>{
            new Journey__c(
                Id = TestUtility.getFakeId(Journey__c.getSObjectType()),
                OwnerId = UserInfo.getUserId(),
                Name = 'test',
                Primary_Email__c = 'testJourneyEmail@example.com',
                Product_Interests__c = JourneyUpdateMQLIdentifiedOnTrH.WORKSPACE
            )
        };
    }
}