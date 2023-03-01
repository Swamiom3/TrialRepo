@isTest
public with sharing class OpportunityUpdateBuildingFromGeoTrHTest {

    @isTest
    private static void testFilterOpportunities() {
        Map<Id, Opportunity> oldOpportunities = new Map<Id, Opportunity>();
        List<Opportunity> newOpportunities = UtilOpportunity.GetNewOpportunity(10, new Account(), false);
        Boolean isEven = true;
        for (Opportunity opp : newOpportunities) {
            opp.Id = TestUtility.getFakeId(Opportunity.SObjectType);
            opp.Geography__c = TestUtility.getFakeId(Geography__c.SObjectType);
            Opportunity oldOpp = opp.clone(true, true);
            if (isEven = !isEven) {
                oldOpp.Geography__c = TestUtility.getFakeId(Geography__c.SObjectType);
            }
            oldOpportunities.put(oldOpp.Id, oldOpp);
        }
        Test.startTest();
        Map <Id, List<Opportunity>> mapGeoIdToOpps = new OpportunityUpdateBuildingFromGeoTrH(newOpportunities, oldOpportunities).filterOpportunities();
        Test.stopTest();
        System.assertEquals(5, mapGeoIdToOpps.size(), 'Number of filtered opportunities is not correct');
    }

    @isTest
    private static void testUpdateBuilding() {
        List<Building__c> buildings = UtilBuilding.createBuildings(5, true);
        List<Geography__c> geographies = new List<Geography__c>();
        for (Integer i = 0; i < 10; i++) {
            Geography__c geography = UtilGeography.createGeography(1, false)[0];
            geography.Nearest_Building__c = buildings.size() > i ? buildings[i].Id : null;
            geographies.add(geography);
        }
        insert geographies;
        List<Opportunity> opportunities = UtilOpportunity.GetNewOpportunity(20, new Account(), false);
        for (Integer i = 0; i < opportunities.size(); i++) {
            opportunities[i].Geography__c = geographies.size() > i ? geographies[i].Id : null;
        }
        OpportunityUpdateBuildingFromGeoTrH oppUpdBuildFromGeoTrH = new OpportunityUpdateBuildingFromGeoTrH(opportunities, new Map<Id, Opportunity>());
        System.assertEquals(geographies[0].Id, oppUpdBuildFromGeoTrH.newOpportunities[0].Geography__c, 'Wrong value of Geography lookup field');
        System.assertEquals(null, oppUpdBuildFromGeoTrH.newOpportunities[0].Building__c, 'Building lookup must be null');
        Map <Id, List<Opportunity>> mapGeoIdToOpps = oppUpdBuildFromGeoTrH.filterOpportunities();
        System.assertEquals(10, mapGeoIdToOpps.size(), 'Filtered geographies count is incorrect');
        Test.startTest();
        oppUpdBuildFromGeoTrH.updateBuilding(mapGeoIdToOpps);
        Test.stopTest();
        System.assertEquals(null, oppUpdBuildFromGeoTrH.newOpportunities[15].Building__c, 'Building lookup must be null');
        System.assertEquals(buildings[0].Id, oppUpdBuildFromGeoTrH.newOpportunities[0].Building__c, 'Wrong value of Building lookup field');
    }

    @isTest
    private static void testRequireBuildingAssignment() {
        Opportunity newOpp = UtilOpportunity.GetNewOpportunityWithFieldMapping(1, new Account(), new Map<String, Object>{ 
            'Geography__c' => TestUtility.getFakeId(Geography__c.SObjectType)
        }, false)[0];
        System.assertEquals(true, new OpportunityUpdateBuildingFromGeoTrH(null, null).requireBuildingAssignment(newOpp, null), 'Current opportunity record must require building assignment');
    }

    @isTest
    private static void testBuildingSelectedManually() {
        Opportunity newOpp = UtilOpportunity.GetNewOpportunityWithFieldMapping(1, new Account(), new Map<String, Object>{
            'Building__c' => TestUtility.getFakeId(Building__c.SObjectType)
        }, false)[0];
        Opportunity oldOpp = UtilOpportunity.GetNewOpportunityWithFieldMapping(1, new Account(), new Map<String, Object>{
            'Building__c' => TestUtility.getFakeId(Building__c.SObjectType)
        }, false)[0];
        System.assertEquals(true, new OpportunityUpdateBuildingFromGeoTrH(null, null).buildingSelectedManually(newOpp, oldOpp), 'Current opportunity record must be indicated as manually selected');
    }
}