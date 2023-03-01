/*************************************************************************************************************************************
    Author      :   Pawel Biszczak
    Description :   This class provides sufficient test coverage for UserSelector class
    --------------------------------------------------------------------------------------------------------------------------------------
    VERSION     DATE            AUTHOR            DETAIL
    1           27 Jan, 2022    Pawel Biszczak    Initial Deployment
    2           23 March, 2022  Ishwar Shinde     Implementation Of ST-10054
**************************************************************************************************************************************/
@isTest
public with sharing class UserSelectorTest {
    private static UserSelector userSelector = new UserSelector();
    
    @testSetup
    static void makeData(){
        Map<String, Object> recordsData = new Map<String, Object>();
        recordsData.put('objName', 'User');
        recordsData.put('numberOfRecords', 1);
        TestingUtility.getRecords(recordsData);
        UserRole userRole = new UserRole(DeveloperName = 'TestCustomRole', Name = 'Test Role');
        insert userRole; 
        User user = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id,
            LastName = 'LastName123',
            Username = 'test@test.com' + System.currentTimeMillis(),
            CompanyName = 'Test_Comp',
            Email = 'test@test.com',
            IsActive = TRUE,
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            UserRoleId = userRole.Id,
            FederationIdentifier = 'test@test.com.service'
        );
        insert user;
    }
    
    @isTest
    static void shouldGetDefaultFields(){
        Set<String> fields;
        
        Test.startTest();
        fields = userSelector.getDefaultFields();
        Test.stopTest();
        
        System.assert(!userSelector.defaultFields.isEmpty(), 'Default fields should be presented');
    }
    
    @isTest
    static void shouldGetUserById(){
        User userForSelector;
        Id userId;
        
        Test.startTest();
        userForSelector = [SELECT Id FROM User WHERE LastName = 'LastName123' LIMIT 1];
        List<User> testUsers1 = userSelector.getUsersById(new List<Id>{ userForSelector.Id });
        List<User> testUsers2 = userSelector.getUsersById(new Set<Id>{ userForSelector.Id });
        List<User> getEmptyUsers1 = userSelector.getUsersById(new List<Id>());
        List<User> getEmptyUsers2 = userSelector.getUsersById(new Set<Id>());
        Test.stopTest();
        
        System.assertEquals(1, testUsers1.size(), 'Should get User for provided Id');
        System.assertEquals('LastName123', testUsers1[0].LastName, 'Should get proper User LastName');
        System.assertEquals('America/Los_Angeles', testUsers2[0].TimeZoneSidKey, 'Should get proper User Time Zone');
        System.assert(getEmptyUsers1.isEmpty(), 'Should not get any Users for empty list');
        System.assert(getEmptyUsers2.isEmpty(), 'Should not get any Users for empty list');
    }
    
    @isTest
    static void shouldNotGetRecordsForFakeId(){
        List<User> users;
        User userForSelector = getFakeUsers()[0];
        
        Test.startTest();
        users = userSelector.getUsersById(new List<Id>{ userForSelector.Id });
        Test.stopTest();
        
        System.assert(users.isEmpty(), 'Should not get any Users for fake Id');
    }
    
    @isTest
    static void shouldGetUsersWithAdditionalFieldsById(){
        User userForSelector;
        Id userId;
        
        Test.startTest();
        userForSelector = [SELECT Id FROM User WHERE LastName = 'LastName123' LIMIT 1];
        List<User> testUsers = userSelector.getUsersWithAdditionalFieldsById(userForSelector.Id);
        List<User> getEmptyUsers = userSelector.getUsersWithAdditionalFieldsById(userId);
        Test.stopTest();
        System.assertEquals('America/Los_Angeles', testUsers[0].TimeZoneSidKey, 'Should get proper User Time Zone');  
        System.assertNotEquals('test_test@test.com', testUsers[0].Email, 'Should get proper User Email');                
        System.assertEquals('System Administrator', testUsers[0].Profile.Name, 'Should get proper User Profile Name');
        System.assert(getEmptyUsers.isEmpty(), 'Should not get any Users for empty list');
    }
    
    @isTest
    static void shouldGetActiveUsersByIdWithOrderByName(){
        Test.startTest();
        List<User> testUsers = [SELECT Id FROM User WHERE IsActive = TRUE AND LastName = 'LastName123' LIMIT 1];
        List<User> testUsers1 = userSelector.getActiveUsersByIdWithOrderByName(new Set<Id>{testUsers[0].Id});
        List<User> getEmptyUsers = userSelector.getActiveUsersByIdWithOrderByName(new Set<Id>{});
        Test.stopTest();
        
        System.assertEquals('test@test.com', testUsers1[0].Email, 'Should get proper User Email');
        System.assert(!testUsers1.isEmpty(), 'should not get empty user');
        System.assertEquals(1, testUsers1.size(), 'Should get User for provided Id');
        System.assert(getEmptyUsers.isEmpty(), 'should get empty user');
    }
    
    @isTest
    static void shouldGetUsersByProfileId(){
        User userForSelector;
        String profileId;
        
        Test.startTest();
        userForSelector = [SELECT ProfileId FROM User WHERE LastName = 'LastName123' LIMIT 1];
        List<User> testUsers = userSelector.getUsersByProfileId(userForSelector.ProfileId);
        List<User> getEmptyUsers = userSelector.getUsersByProfileId(profileId);
        Test.stopTest();
        
        System.assert(!testUsers.isEmpty(), 'Should get User'); 
        System.assert(getEmptyUsers.isEmpty(), 'Should not get any Users for empty list');
    }
    
    @isTest
    static void shouldGetUsersByEmailAndUsername(){
        User userForSelector;
        String email;
        
        Test.startTest();
        userForSelector = [SELECT Id, UserName, Email FROM User WHERE LastName = 'LastName123' LIMIT 1];
        List<User> testUsers = userSelector.getUsersByEmailAndUsername(userForSelector.Email, userForSelector.UserName);
        List<User> getEmptyUsers = userSelector.getUsersByEmailAndUsername(email, userForSelector.UserName);
        Test.stopTest();
        
        System.assert(!testUsers.isEmpty(), 'Should get User');
        System.assertEquals(userForSelector.Id, testUsers[0].Id, 'Should get proper User Id');                
        System.assert(getEmptyUsers.isEmpty(), 'Should not get any Users for empty list');
    }
    
    @isTest
    static void shouldGetActiveUsersByEmail(){
        User userForSelector;
        String email;
        
        Test.startTest();
        userForSelector = [SELECT Id, Email FROM User WHERE LastName = 'LastName123' LIMIT 1];
        List<User> testUsers = userSelector.getActiveUsersByEmail(userForSelector.Email);
        List<User> getEmptyUsers = userSelector.getActiveUsersByEmail(email);
        Test.stopTest();
        
        System.assert(!testUsers.isEmpty(), 'Should get User');
        System.assertEquals(userForSelector.Id, testUsers[0].Id, 'Should get proper User Id');
        System.assertEquals(userForSelector.Email, testUsers[0].Email, 'Should get proper User Email');
        System.assertNotEquals('test_test@test.com', testUsers[0].Email, 'Should get proper User Email');                
        System.assert(getEmptyUsers.isEmpty(), 'Should not get any Users for empty list');
    }
    
    @isTest
    static void shouldGetAllActiveUsers(){
        
        Test.startTest();
        List<User> testUsers = userSelector.getAllActiveUsers();
        Test.stopTest();
        
        System.assert(!testUsers.isEmpty(), 'Should get User');
    }
    @isTest
    static void shouldGetUserByFederationIdentifier(){
        Test.startTest();
        List<User> testUsers = userSelector.getUserByFederationId('test@test.com.service');
        Test.stopTest();
        System.debug(testUsers);
        System.assert(!testUsers.isEmpty(),'Should get User by Federation Id');

    }
   
    private static List<User> getFakeUsers() {
        Map<String, Object> recordsData = new Map<String, Object>();
        recordsData = new Map<String, Object>();
        recordsData.put('objectName', 'User');
        recordsData.put('numberOfRecords', 1);
        return MockTestingUtility.getRecords(recordsData, true);
    }
}