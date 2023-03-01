@isTest
public class InterestDuplicateManagementTrHTest {
    @isTest
    private static void interestDuplicateManagementTest(){
        List<Building__c> building = getInsertedBuildings();
        List<Opportunity> opportunity = getFakeOpportunity(true);
        List<Inventory__c> inventory = getInsertedinventory();
        List<Interest__c> interests = getInsertedInterest();
        List<Interest__c> mockedInterests = new List<Interest__c>{
            new Interest__c(Id = interests[0].Id, Opportunity__c = opportunity[0].Id, Building__c = building[0].Id, Inventory_Id__c = inventory[0].Id),
            new Interest__c(Id = interests[1].Id, Opportunity__c = opportunity[1].Id, Building__c = building[1].Id),
            new Interest__c(Id = interests[2].Id, Opportunity__c = opportunity[2].Id, Building__c = building[2].Id, Inventory_Id__c = inventory[2].Id),
            new Interest__c(Id = interests[3].Id, Opportunity__c = opportunity[3].Id, Building__c = building[3].Id)
        };
        List<Interest__c> newMockedInterests = new List<Interest__c>{
            new Interest__c(Id = interests[4].Id, Opportunity__c = opportunity[0].Id, Building__c = building[0].Id, Inventory_Id__c = inventory[0].Id),
            new Interest__c(Id = interests[5].Id, Opportunity__c = opportunity[1].Id, Building__c = building[1].Id),
            new Interest__c(Id = interests[6].Id, Opportunity__c = opportunity[2].Id, Building__c = building[2].Id, Inventory_Id__c = inventory[2].Id),
            new Interest__c(Id = interests[7].Id, Opportunity__c = opportunity[3].Id, Building__c = building[3].Id)
        };
        Test.startTest();
        InterestDuplicateManagementTrH duplicateManagement = new InterestDuplicateManagementTrH();
        duplicateManagement.newInterests = newMockedInterests;
        duplicateManagement.interestSelector = (InterestSelector) MockService.createMock(InterestSelector.class, 
                                                                                         new Map<String, Object>{ 'getInterestByOpportunity' => mockedInterests
        });
        duplicateManagement.beforeInsert();
        String errorMsg = newMockedInterests[2].getErrors()[0].getMessage();
        String errorMsg1 = newMockedInterests[3].getErrors()[0].getMessage();
        System.debug('***vipul =='+errorMsg1);
        System.assert(errorMsg.contains('with the same Opportunity, Building, and Inventory already exists'));
        System.assert(errorMsg1.contains('with the same Opportunity and Building exists with no Inventory. Add a Inventory to that Interest instead of creating a new one.'));
        Test.stopTest();
    }
    
    @isTest
    private static void interestDuplicateManagementUpdateTest(){
        List<Building__c> building = getInsertedBuildings();
        List<Opportunity> opportunity = getFakeOpportunity(true);
        List<Inventory__c> inventory = getInsertedinventory();
        List<Interest__c> interests = getInsertedInterest();
        List<Interest__c> mockedInterests = new List<Interest__c>{
            new Interest__c(Id = interests[0].Id, Opportunity__c = opportunity[0].Id, Building__c = building[0].Id, Inventory_Id__c = inventory[0].Id),
            new Interest__c(Id = interests[1].Id, Opportunity__c = opportunity[1].Id, Building__c = building[1].Id),
            new Interest__c(Id = interests[2].Id, Opportunity__c = opportunity[2].Id, Building__c = building[2].Id, Inventory_Id__c = inventory[2].Id),
            new Interest__c(Id = interests[3].Id, Opportunity__c = opportunity[3].Id, Building__c = building[3].Id)
        };
        List<Interest__c> newMockedInterests = new List<Interest__c>{
            new Interest__c(Id = interests[4].Id, Opportunity__c = opportunity[0].Id, Building__c = building[0].Id, Inventory_Id__c = inventory[0].Id),
            new Interest__c(Id = interests[5].Id, Opportunity__c = opportunity[1].Id, Building__c = building[1].Id),
            new Interest__c(Id = interests[6].Id, Opportunity__c = opportunity[2].Id, Building__c = building[2].Id, Inventory_Id__c = inventory[2].Id),
            new Interest__c(Id = interests[7].Id, Opportunity__c = opportunity[3].Id, Building__c = building[3].Id)
        };
        Test.startTest();
        InterestDuplicateManagementTrH duplicateManagement = new InterestDuplicateManagementTrH();
        duplicateManagement.oldInterestsMap = new Map<Id, Interest__c>(mockedInterests);
        duplicateManagement.newInterests = newMockedInterests;
        duplicateManagement.interestSelector = (InterestSelector) MockService.createMock(InterestSelector.class,
                                                                                         new Map<String, Object>{'getInterestByOpportunity' => mockedInterests
        });
        duplicateManagement.beforeUpdate();
        String errorMsg = newMockedInterests[2].getErrors()[0].getMessage();
        String errorMsg1 = newMockedInterests[3].getErrors()[0].getMessage();
        System.debug('***vipul1 =='+errorMsg1);
        System.assert(errorMsg.contains('with the same Opportunity, Building, and Inventory already exists'));
        System.assert(errorMsg1.contains('with the same Opportunity and Building exists with no Inventory. Add a Inventory to that Interest instead of creating a new one.'));
        Test.stopTest();
    }

    private static List<Building__c> getInsertedBuildings(){
        List<Building__c> testBuilding = new List<Building__c>();
        for(Integer i = 0; i<4; i++){
        testBuilding.add(new Building__c(Name = 'Test Building'+i,
                                         Id = TestUtility.getFakeId(Building__c.getSObjectType())
                                        ));
        }
        return testBuilding;
    }
    
    private static List<Opportunity> getFakeOpportunity(Boolean isFakeIds) {
        Map<String, Object> recordsData = new Map<String, Object>();
        recordsData = new Map<String, Object>();
        recordsData.put('objectName', 'Opportunity');
        recordsData.put('numberOfRecords', 4);
        return MockTestingUtility.getRecords(recordsData, isFakeIds);
    }

    private static List<Inventory__c> getInsertedInventory(){
        List<Inventory__c> testInventory = new List<Inventory__c>();
        for(Integer i =0; i<4; i++){testInventory.add(new Inventory__c(Id = TestUtility.getFakeId(Inventory__c.getSObjectType()),
                                                                       Name = 'Test'+i,
                                                                       List_Price__c = 1000,
                                                                       Type__c = 'Office',
                                                                       UUID__c = '12345' + i
                                                                      ));     
        }
        return testInventory;
    }

    private static List<Interest__c> getInsertedInterest(){
        List<Interest__c> testInterest = new List<Interest__c>();
        for(Integer i = 0; i<10; i++){
            testInterest.add(new Interest__c(Id = TestUtility.getFakeId(Interest__c.getSObjectType())));
        }
        return testInterest;
    }
}