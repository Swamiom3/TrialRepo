/**********************************************************************************************************
    Author        :  Ashish Sharma
    Description   :  Test for GenerateProposalController
    Issue No.     :  ST-8071
    History       :
-----------------------------------------------------------------------------------------------------------
    VERSION        DATE          AUTHOR           DETAIL
      1         06-May-2021    Ashish Sharma      ST-8071
**********************************************************************************************************/
@isTest
public class GenerateProposalControllerTest {
    @testSetup
    private static void setup() {        
        Map<String, Object> mapData = new Map<String, Object>{'objName' => 'Opportunity',
                                                              'numberOfRecords' => 1,
                                                              'doInsert' => false,
                                                              'mapFieldValues' => new Map<String,  List<Object>>()
                                                             };
        MetadataDrivenTriggerHandler.disableExecution();
        TestingUtility.getTerritorystructure();        
        List<Opportunity> opportunities = TestingUtility.getRecords(mapData);
        opportunities[0].Building__c = [SELECT Id FROM Building__c LIMIT 1].Id;
        TestingUtility.insertListWithAssert(opportunities);
        List<Inventory__c> inventories = UtilInventory.createInventory(3, opportunities[0].Building__c, false);
        inventories[0].Contract_Status__c = inventories[1].Contract_Status__c = inventories[2].Contract_Status__c = 'Contract Sent';
        TestingUtility.insertListWithAssert(inventories);
        Interest__c testInterest = new Interest__c(Opportunity__c = opportunities[0].Id, 
                                                   Building__c = opportunities[0].Building__c, 
                                                   Inventory_Id__c = inventories[0].Id);
        insert testInterest;
        Opportunity oppReturned = GenerateProposalController.getOppInfo(opportunities[0].Id);
        System.assert(oppReturned != null, 'Method should return an Opportunity');
    }
    
    @isTest
    private static void getInventoriesTest() {
        Opportunity testOpp = [SELECT Id, Building__c FROM Opportunity LIMIT 1];
        GenerateProposalController.Inventory data = GenerateProposalController.getInventories(testOpp.Building__c, testOpp.Id);
        System.assertEquals(1, data.matchingInventoryIds.size(), 'There should be 1 matching inventory');
        System.assertEquals(3, data.inventoriesForBuilding.size(), 'There should be 3 inventories');
        
        List<Inventory__c> inventories = GenerateProposalController.searchInventories('Residential Unit');
        System.assertEquals(3, inventories.size(), 'There should be 3 inventories');
    }
    
    @isTest
    private static void generateProposalTest() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200, 'fakepresentationurl'));
        Opportunity testOpp = [SELECT Id, Building__c FROM Opportunity LIMIT 1];        
        List<Inventory__c> inventories = [SELECT Id, Building__c FROM Inventory__c];
        Interest__c testInterest = [SELECT Id, Building__c, Inventory_Id__r.UUID__c FROM Interest__c];
        Interest__c interestToInsert = new Interest__c(Opportunity__c = testOpp.Id, 
                                                       Building__c = inventories[1].Building__c, 
                                                       Inventory_Id__c = inventories[1].Id);
        
        String payload = '{"locationUuid": "building-0001-0001", "inventoryUuids": "reservable-0001-0001", "capacity": 2, clientName: "test"}';
        Test.startTest();
        DatabaseResult response = GenerateProposalController.generateProposal(payload, testOpp, new List<Interest__c>{interestToInsert});
        Test.stopTest();
        System.assertEquals(true, response.success, 'request should be successful');
        System.assertEquals('fakepresentationurl', response.Data, 'request should return fakepresentationurl');
    }
}