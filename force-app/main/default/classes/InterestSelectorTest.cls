@isTest
public class InterestSelectorTest {
    @testSetup
    private static void makeData() {
       List<Opportunity> testOpportunity = new List<Opportunity>();
        for(Integer i = 0; i<4; i++){
            testOpportunity.add(new Opportunity(Name = 'Test Opportunity'+i,
                                                Broker_Involvement_Indicated__c = 'No',
                                                CurrencyIsoCode = 'USD',
                                                Description = 'Test Description',
                                                CloseDate = System.Date.today().addDays(4),
                                                Locations_Interested__c = 'AMS-Labs',
                                                StageName = 'Selling',
                                                OwnerId = UserInfo.getUserId(),
                                                Owner = UserUtility.getUserById(UserInfo.getUserId())
                                                ));
        }
        insert testOpportunity;
        List<Building__c> testBuilding = new List<Building__c>();
        for(Integer i = 0; i<4; i++){
        testBuilding.add(new Building__c(Name = 'Test Building'+i));
        }
         insert testBuilding;
        List<Inventory__c> testInventory = new List<Inventory__c>();
        for(Integer i = 0; i<4; i++){
            testInventory.add(new Inventory__c(Name = 'Test'+i,
                                               List_Price__c = 1000,
                                               Type__c = 'Office',
                                               UUID__c = '12345' + i
                                                ));
        }
         insert testInventory;
        Interest__c testInterest = new Interest__c(Opportunity__c = testOpportunity[0].Id,
                                                   Building__c = testBuilding[0].Id,
                                                   Inventory_Id__c = testInventory[0].Id
                                                  );
         insert testInterest;
    }

    @isTest
    public static void getInterestByOpportunitiesTest(){
        InterestSelector interestSelector = new InterestSelector();
        Interest__c interestRecord = [SELECT Id FROM Interest__c LIMIT 1];
        Interest__c interestRecords = [SELECT Id, Opportunity__c, Inventory_Id__c FROM Interest__c LIMIT 1];
        System.assertNotEquals(null, interestSelector.getInterestByOpportunity(new Set<Id>{interestRecord.Id}, new Set<Id>{interestRecords.Id}), 'List should not be empty');
    }
}