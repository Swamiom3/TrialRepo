@isTest
public class TrOpportunityAddInterestsTest {

    @testSetup
    static void setup() {
        Account testAccount1 = TestingUtility.createAccount('testAccount1', true);
		List<Map<String,String>> lstMapTestBuildings = new List<Map<String,String>>();
        OperatingHours objOpHour = new OperatingHours(Name = 'EDT: Standard 9AM - 5PM Weekday');
        insert objOpHour;
        Map<String,String> mapTestBuilding1Values = new Map<String,String>();
        mapTestBuilding1Values.put('Name','TestBuilding1');
        mapTestBuilding1Values.put('CurrencyIsoCode','USD');
        mapTestBuilding1Values.put('Address__c','Banner');
        mapTestBuilding1Values.put('City__c','Boston');
        mapTestBuilding1Values.put('UUID__c','4eb8144b-f461-4849-8b81-b5fa344fb978');
        lstMapTestBuildings.add(mapTestBuilding1Values);
        
        Map<String,String> mapTestBuilding2Values = new Map<String,String>();
        mapTestBuilding2Values.put('Name','TestBuilding2');
        mapTestBuilding2Values.put('CurrencyIsoCode','USD');
        mapTestBuilding2Values.put('Address__c','Banner');
        mapTestBuilding2Values.put('City__c','New York');
        mapTestBuilding2Values.put('UUID__c','4eb8144b-f461-4849-8b81-b5fa344fb975');
        lstMapTestBuildings.add(mapTestBuilding2Values);
        
        Map<String,String> mapTestBuilding3Values = new Map<String,String>();
        mapTestBuilding3Values.put('Name','TestBuilding3');
        mapTestBuilding3Values.put('CurrencyIsoCode','USD');
        mapTestBuilding3Values.put('Address__c','Banner');
        mapTestBuilding3Values.put('City__c','Chicago');
        mapTestBuilding3Values.put('UUID__c','4eb8144b-f461-4849-8b81-b5fa344fb972');
        lstMapTestBuildings.add(mapTestBuilding3Values);
        
        List<Building__c> lstTestBuildings = TestingUtility.createBuildings(lstMapTestBuildings, true);
        Building__c testBuilding1 = lstTestBuildings.get(0);
        
        Map<String,Object> mapOppValues = new Map<String,Object>();
        mapOppValues.put('AccountId',testAccount1.Id);
        mapOppValues.put('Building__c',testBuilding1.Id);
        mapOppValues.put('StageName','New');
        mapOppValues.put('Name','TestOpportunity1');
        mapOppValues.put('CloseDate',System.today().addDays(30));

        Opportunity testOpportunity1 = TestingUtility.createOpportunity(mapOppValues, true);        
    }
    
    @isTest
    static void verifyInterestsCreatedOnOpportunityInsertAndUpdate() {
        Opportunity testOpportunity1 = [SELECT Id FROM Opportunity LIMIT 1][0];
        List<Interest__c> lstOpportunityInsertInterests = [SELECT Id, Opportunity__c, Building__c, Inventory_Id__c FROM Interest__c WHERE Opportunity__c = :testOpportunity1.Id];
        List<Building__c> testBuildings = [SELECT Id FROM Building__c WHERE Name LIKE 'TestBuilding%' ORDER BY Name ASC];
        Building__c testBuilding1 = testBuildings[0];
        Building__c testBuilding2 = testBuildings[1];
        Building__c testBuilding3 = testBuildings[2];

        System.assertEquals(1, lstOpportunityInsertInterests.size());
        System.assertEquals(testOpportunity1.Id, lstOpportunityInsertInterests[0].Opportunity__c);
        System.assertEquals(testBuilding1.Id, lstOpportunityInsertInterests[0].Building__c);

        Test.startTest();
        // test the case where there is already an interest for this opportunity with the new building
        Interest__c interestForOpp = new Interest__c(Opportunity__c = testOpportunity1.Id, Building__c = testBuilding2.Id);
        TestingUtility.insertWithAssert(interestForOpp);
        testOpportunity1.Building__c = testBuilding2.Id;
        TestingUtility.updateWithAssert(testOpportunity1);
        
        // test the case where this is NOT an interst for this opportunity with the new building
        testOpportunity1.Building__c = testBuilding3.Id;
        TestingUtility.updateWithAssert(testOpportunity1);        
        Test.stopTest();
        
        List<Interest__c> lstOpportunityUpdateInterests = [SELECT Id, Opportunity__c, Building__c, Inventory_Id__c FROM Interest__c WHERE Opportunity__c = :testOpportunity1.Id];
        System.assertEquals(3, lstOpportunityUpdateInterests.size()); // 1 automatically from opp insert, 1 manually, 1 automatically from opp update
    }
}