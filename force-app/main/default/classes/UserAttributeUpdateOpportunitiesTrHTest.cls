/**********************************************************************************************************
    Author        :  Ashish Sharma
    Description   :  This is a test class for UserAttributeUpdateOpportunitiesTrH.
    Issue No.     :  ST-7390
    History       :
-----------------------------------------------------------------------------------------------------------
    VERSION        DATE          AUTHOR           DETAIL
      1         15-Jan-2021    Ashish Sharma      Refactor and move to new framework
**********************************************************************************************************/
@isTest
private class UserAttributeUpdateOpportunitiesTrHTest {
    private final static Id USER_ID = UserInfo.getUserId();
    @testSetup
    private static void setup() {
        Opportunity insertOpp = new Opportunity();
       	insertOpp.Name = 'Test Opp';
        insertOpp.OwnerId = USER_ID;
        insertOpp.Owner_Assigned_Date__c = System.today();
        insertOpp.StageName = 'Qualifying';
        insert insertOpp;
        List<Opportunity> oppsToInsert = new List<Opportunity>();
        Map<String, Object> mapData = new Map<String, Object>{'objName' => 'Opportunity',
                                                              'numberOfRecords' => 1,
                                                              'doInsert' => false,
                                                              'mapFieldValues' => new Map<String,  List<Object>> {
                                                                  'OwnerId' => new List<Object>{USER_ID},
                                                                  'Name' => new List<Object>{'testOpp1'}
                                                              }
                                                             };
        oppsToInsert.addAll((List<Opportunity>) TestingUtility.getRecords(mapData));
        mapData = new Map<String, Object>{'objName' => 'Opportunity',
                                          'numberOfRecords' => 1,
                                          'doInsert' => false,
                                          'mapFieldValues' => new Map<String,  List<Object>> {
                                               'OwnerId' => new List<Object>{USER_ID},
                                               'Name' => new List<Object>{'testOpp2'}
                                          }
		};
        oppsToInsert.addAll((List<Opportunity>) TestingUtility.getRecords(mapData));
        TestingUtility.insertListWithAssert(oppsToInsert);
        List<User_Attribute__c> uasToInsert = new List<User_Attribute__c>();
        uasToInsert.add(new User_Attribute__c(User__c = USER_ID, 
                                              As_of_Date__c = Date.today().addDays(-30),
                                              End_Date__c = Date.today().addDays(10)
                                             ));
        uasToInsert.add(new User_Attribute__c(User__c = USER_ID, 
                                              As_of_Date__c = Date.newInstance(2018, 06, 01), 
                                              End_Date__c = Date.newInstance(2018, 07, 31)
                                             ));
        TestingUtility.insertListWithAssert(uasToInsert);
    }
    
    @isTest
    private static void updateOpportunityOnInsertTest() {
        Test.startTest();
        List<Opportunity> oppsToAssert = [SELECT User_Attribute__c FROM Opportunity];
        List<User_Attribute__c> userAttributes = [SELECT Id FROM User_Attribute__c];        
        Test.stopTest();
        System.assertEquals(3, oppsToAssert.size(), 'Opportunity size is equal to 3');
    }
    
    @isTest
    private static void updateOpportunityOnUpdateTest() {
        Test.startTest();
        List<User_Attribute__c> userAttributes = [SELECT Id FROM User_Attribute__c];
        userAttributes[0].As_of_Date__c = Date.newInstance(2018, 06, 01);
        userAttributes[0].End_Date__c = Date.newInstance(2021, 06, 01);
        userAttributes[1].As_of_Date__c = Date.today().addDays(-10);
        userAttributes[1].End_Date__c = Date.today().addDays(30);
        TestingUtility.updateListWithAssert(userAttributes);
        List<Opportunity> oppsToAssert = [SELECT User_Attribute__c FROM Opportunity];
        Test.stopTest();
        System.assertEquals(3, oppsToAssert.size(), 'Opportunity size is equal to 3');
    }
}