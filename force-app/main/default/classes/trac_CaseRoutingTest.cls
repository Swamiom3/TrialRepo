/**
 * @description unit tests for the case routing
 * @name trac_CaseRoutingTest
 * @author Daniel Labonte, Traction on Demand
 * @date 2019-08-20
 */

@IsTest
public with sharing class trac_CaseRoutingTest {
    static final TLTestFactory factory = new TLTestFactory();

    static final String REGION_NAME = 'My Region';
    static final String TERRITORY_NAME = 'My Territory';
    static final String BUILDING_NAME = 'My Building';

    @TestSetup
    static void setup() {
        Location__c region = (Location__c) factory.createSObject(new Location__c(Name=REGION_NAME,RecordTypeId=trac_LocationConstants.RTID_REGION),true);
        Location__c territory = (Location__c) factory.createSObject(new Location__c(Name=TERRITORY_NAME,RecordTypeId=trac_LocationConstants.RTID_TERRITORY,Region__c=region.Id),true);
        Location__c building = (Location__c) factory.createSObject(new Location__c(Name=BUILDING_NAME,RecordTypeId=trac_LocationConstants.RTID_BUILDING,Territory__c=territory.Id),true);
    }

    @IsTest
    static void testRoutingOnEscalate() {
        String buildingId = [SELECT Id FROM Location__c WHERE Name = :BUILDING_NAME LIMIT 1].Id;
        Case cs = (Case) factory.createSObject(new Case(Route__c=false,Location__c=buildingId),true);

        Test.startTest();
        cs.Category__c = 'Cleaning';
        cs.Route__c = true;
        update cs;
        Test.stopTest();

        Case updatedCase = [SELECT OwnerId, Route__c, Routing_Log__c FROM Case WHERE Id = :cs.Id];

        System.assert(!updatedCase.Route__c,'The route flag was not reversed, therefore case was not routed');
        System.assert(updatedCase.Routing_Log__c != null,'The routing logic was not hit');
    }

    @IsTest
    static void testRoutingMany() {
        String buildingId = [SELECT Id FROM Location__c WHERE Name = :BUILDING_NAME LIMIT 1].Id;
        List<Case> css = (List<Case>) factory.createSObjects(new Case(Route__c=false,Location__c=buildingId),100,false);

        Test.startTest();
        for(Case cs : css) {
            cs.Category__c = 'Cleaning';
            cs.Route__c = true;
            cs.Escalate__c = true;
        }
//        update css;
        Test.stopTest();
        trac_CaseRouting.route(css);
//        Case updatedCase = [SELECT OwnerId, Route__c FROM Case WHERE Id = :cs.Id];

    }
}