/**********************************************************************************************************
    Author        :  Ashish Sharma
    Description   :  This is a test class for UserAttributeUpdateUsersTrH.
    Issue No.     :  ST-7390
    History       :
-----------------------------------------------------------------------------------------------------------
    VERSION        DATE          AUTHOR           DETAIL
      1         15-Jan-2021    Ashish Sharma      Refactor and move to new framework
**********************************************************************************************************/
@isTest
private class UserAttributeUpdateUsersTrHTest {
    private final static Id USER_ID = UserInfo.getUserId();
    @testSetup
    private static void setup() {
        OperatingHours objOpHour = new OperatingHours(Name = 'EDT: Standard 9AM - 5PM Weekday');
        insert objOpHour;
        TestingUtility.getTerritorystructure();
        List<User> users = TestingUtility.getRecords(new Map<String, Object>{
            	'objName' => 'User', 
                'numberOfRecords' => 1, 
                'doInsert' => true, 
                'mapFieldValues' => new Map<String, List<Object>> {}
        });
        List<User_Attribute__c> uasToInsert = new List<User_Attribute__c>();
        uasToInsert.add(new User_Attribute__c(User__c = USER_ID, 
                                              As_of_Date__c = Date.today().addDays(-30),
                                              End_Date__c = Date.today().addDays(30),
                                              Sales_Function__c = 'NMD - OB SWAT',
                                              Sales_Team__c = 'Inside Sales'
                                             ));
        uasToInsert.add(new User_Attribute__c(User__c = users[0].Id, 
                                              As_of_Date__c = Date.newInstance(2018, 06, 01), 
                                              End_Date__c = Date.newInstance(2018, 07, 31),
                                              Sales_Function__c = 'NMD - OB SWAT',
                                              Sales_Team__c = 'Inside Sales'
                                             ));
        TestingUtility.insertListWithAssert(uasToInsert);
    }
    
    @isTest
    private static void updateUserOnInsertTest() {
        Test.startTest();
        User testUser = UserUtility.getUserById(USER_ID);
        List<User> users = [SELECT Email, Sales_Team__c, Sales_Role__c FROM User 
                            WHERE Id =:testUser.Id OR Email = 'testUserEmail1@test.com'];
        Map<String, User> emailToUser = new Map<String, User>();
        TestingUtility.createMapOfValues(users, emailToUser, 'Email');
        List<User_Attribute__c> userAttributes = [SELECT User__c, Sales_Function__c, Sales_Team__c FROM User_Attribute__c];
        Test.stopTest();
        User userToAssert = emailToUser.get('testuseremail1@test.com');
        System.assertEquals(userToAssert.Id, userAttributes[1].User__c);
        System.assertEquals(null, userToAssert.Sales_Team__c, 'User updated with wrong Sales_Team__c');
        System.assertEquals(null, userToAssert.Sales_Role__c, 'User updated with wrong Sales_Role__c');
        
        userToAssert = emailToUser.get(testUser.Email);
        System.assertEquals(userToAssert.Id, userAttributes[0].User__c);
        System.assertEquals(userAttributes[0].Sales_Team__c, userToAssert.Sales_Team__c, 'User updated with wrong Sales_Team__c');
        System.assertEquals(userAttributes[0].Sales_Function__c, userToAssert.Sales_Role__c, 'User updated with wrong Sales_Role__c');
    }
    
    @isTest
    private static void updateUserOnUpdateTest() {
        Test.startTest();
        Market__c market = [SELECT Id, Name, Region__c FROM Market__c LIMIT 1];
        Region__c region = [SELECT Id FROM Region__c LIMIT 1];
        List<User_Attribute__c> userAttributes = [SELECT User__c, Region__c, Sales_Function__c, Sales_Team__c 
                                                  FROM User_Attribute__c];
        User_Attribute__c uaToUpdate = userAttributes[0];
        uaToUpdate.Sales_Team__c = 'Other';
        uaToUpdate.Sales_Function__c = 'MLB - SSD';
        //uaToUpdate.Sales_Pod__c = 'ARG_001';
        uaToUpdate.Portfolio__c = market.Id;
        update uaToUpdate;
        User userToAssert = [SELECT Portfolio__c, Region__c, Sales_Pod__c, Sales_Role__c, Sales_Team__c FROM User 
                            WHERE Id =:USER_ID];        
        Test.stopTest();
        System.assertEquals(market.Name, userToAssert.Portfolio__c, 'User updated with wrong Portfolio__c');
        System.assertEquals(market.Region__c, userToAssert.Region__c, 'User updated with wrong Region__c');
        System.assertEquals(uaToUpdate.Sales_Function__c, userToAssert.Sales_Role__c, 'User updated with wrong Sales_Function__c');
       // System.assertEquals(uaToUpdate.Sales_Pod__c, userToAssert.Sales_Pod__c, 'User updated with wrong Sales_Pod__c');
        System.assertEquals(uaToUpdate.Sales_Team__c, userToAssert.Sales_Team__c, 'User updated with wrong Sales_Team__c');   
             
    }
}