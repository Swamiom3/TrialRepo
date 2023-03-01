/*********************************************************************************************************
    Author        :  Rohit Nimase
    Description   :  Test class for BuildingUtility
    Issue No.     :  ST-8836
    History       :
-----------------------------------------------------------------------------------------------------------
    VERSION        DATE            AUTHOR             DETAIL
    1              22-Sept-2021    Rohit Nimase       Optimize/Cleanup Setting Class Methods
**********************************************************************************************************/
@isTest
public class UserUtilityTest {

     static{ 
        Profile weworkSystemAdmin = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        Map<String,Object> userRecordMap1 = new Map<String,Object>();
        userRecordMap1.put('LastName', 'Last Name 1');
        userRecordMap1.put('Username', 'testweworkuser11@example.com');
        userRecordMap1.put('Email', 'testweworkuser1@example.com');
        userRecordMap1.put('CommunitynickName', 'test111'+system.now());
        user testUser1 = TestingUtility.insertUserWithAssert(weworkSystemAdmin.Id, userRecordMap1, true);
    }
    
    @isTest
    public static void testUserUtilityIncreaseCodeCoverage(){
        user adminUser = [SELECT Id, Name, UserName, Email FROM User WHERE UserName = 'testweworkuser11@example.com'];
        
        User userById = UserUtility.getUserById(adminUser.Id);
        system.assert(userById != null, 'User must be returned based on Id passed to getUserById method');
        
        User userByEmail = UserUtility.getUserByEmail('testweworkuser1@example.com');
        system.assert(userByEmail != null, 'User must be returned based on Email passed to getUserByEmail method');
        
        User userByName= UserUtility.getUserByName('Last Name 1');
        system.assert(userByName != null, 'User must be returned based on Name passed to getUserByName method');
      
        Boolean getUserActive = UserUtility.getUserActive(adminUser.Id);
        system.assertEquals(true, getUserActive, 'User is not active');
        
        List<User> lstAllUsers = UserUtility.getAllUsers();
        system.assert(!lstAllUsers.isEmpty(), 'Should return all users');
        
        System.runAs(adminUser){
            System.assertEquals(true, UserUtility.isSystemAdministrator, 'User is not System Admin');
            System.assertEquals(false, UserUtility.isMuleSoftUser, 'User is Mulesoft User');
        }
        
        System.assert(String.isNotBlank(UserUtility.getApiUserId()), 'getApiUserId should return APIUserId');
        System.assert(String.isBlank(UserUtility.getValidationRuleRestrictionSalesforceId(null)));
        UserUtility.refreshUsers();
    }
    
}