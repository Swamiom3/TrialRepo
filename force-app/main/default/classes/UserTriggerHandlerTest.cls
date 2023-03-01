/************************************************************************************************************************************
    Author 		: Dipak Pawar
    Description : This class will contain the Test Methods of UserTrigger.
	Issue No.	: ST-542,  ST-682 
    History		: --

----------------------------------------------------------------------------------------------------------------------------------
	VERSION					DATE					AUTHOR							DETAIL
	1					    09,Sept 2016		    Dipak Pawar	                	Initial Developement
	2						26,Sept 2016			Dipak Pawar						--
**************************************************************************************************************************************/
@isTest
public class UserTriggerHandlerTest {    
    private static UserSelector userSelector = new UserSelector();
    final static String TEST_EMAIL = 'testUser09092016_1@example.com';
    private final static Id USER_ID = UserInfo.getUserId();
    @testSetup 
    public static void setup() {
        
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        Profile testProfile = [SELECT Id FROM Profile WHERE Name='System Administrator'];		
        User testUser1 = new User(Alias = 'testU', Email=TEST_EMAIL, 
                                  EmailEncodingKey='UTF-8', LastName='User', LanguageLocaleKey='en_US', 
                                  LocaleSidKey='en_US', ProfileId = testProfile.Id, IsActive = true,
                                  TimeZoneSidKey='America/Los_Angeles', UserName=TEST_EMAIL+'.service',
                                  CommunityNickname =TestingUtility.createUserCommunityName());
        insert testUser1;
        List<User_Attribute__c> uasToInsert = new List<User_Attribute__c>();
        uasToInsert.add(new User_Attribute__c(User__c = testUser1.Id, 
                                              As_of_Date__c = Date.newInstance(2018, 06, 01), 
                                              Sales_Function__c = 'NMD - OB SWAT',
                                              Sales_Team__c = 'Inside Sales'
                                             ));
        insert uasToInsert;
    }
    
    @isTest
    public static void testQueryGenerator() { 
        String query = UserTriggerHandler.queryGenerator('Account',new List<String>{'Id','Name'},'123456789',false,Schema.getGlobalDescribe().get('Account').getDescribe().fields.getMap());
        String expected = 'SELECT Id,Name FROM Account WHERE Id = \'123456789\' OR Name LIKE \'%123456789%\'';
        System.assertEquals(expected, query);
        query = UserTriggerHandler.queryGenerator('Account',new List<String>{'Name'},'123456789',true,Schema.getGlobalDescribe().get('Account').getDescribe().fields.getMap());
        expected = 'SELECT Id,Name,Name FROM Account';
        System.assertEquals(expected, query);
        User userName = [Select Id,UserName from User limit 1];
        Map<String,String> mapOfCSV = new Map<String,String>();
        mapOfCSV.put('Account', 'Account');
        UserTriggerHandler.sendEmail(userName.Id, userName.Username, mapOfCSV, 'testExport', 'TestEmailBody', new set<String> {'test@gmail.com'});
    }
    

    @isTest
    private static void verifyFederationIdIsPopulatedOrNot() { 
        Test.startTest();
        List<User> users = userSelector.getActiveUsersByEmail(TEST_EMAIL);
        System.assertEquals(users[0].Email+'.service', users[0].FederationIdentifier);
        users[0].FederationIdentifier = '';
        update users[0];    
        Test.stopTest();         
        List<User> usersAfterUpdate = userSelector.getActiveUsersByEmail(TEST_EMAIL);
        System.assertEquals(usersAfterUpdate[0].Email+'.service', usersAfterUpdate[0].FederationIdentifier);                  
    }
    
    /************************************************************************************************************************************
            Author         : Krishana Tupe
            Description    : This method is used to verify federationID when user specifies if Blank then value should be UserName else specidied federationID. 
            Created Date   : 14 March 2019 
            Issue No       : ST-3634
    **************************************************************************************************************************************/
    @isTest
    private static void verifyFederationIdOnUsernameChange(){
        User user = [SELECT Id, Email, Username, FederationIdentifier FROM User WHERE Email =: TEST_EMAIL LIMIT 1];
        Test.startTest();
        user.Username = 'testingusernamechange@check.com';
        update user;    
        Test.stopTest();
        User toTest = [SELECT Id, Email, Username, FederationIdentifier FROM User WHERE Id =: user.Id];
        System.assertEquals('testingusernamechange@check.com', toTest.Username);
    }

    /************************************************************************************************************************************
            Author         : Oleksandr Vashchenko
            Description    : This method is used to verify federationID when user specifies if Blank then value should be UserName else specidied federationID. 
            Created Date   : 14 March 2019 
            Issue No       : ST-3634
    **************************************************************************************************************************************/
    @isTest
    private static void verifyDeactivatedUserAttributes(){
        User userToDeactivate = [SELECT Id, Email, Username, isActive FROM User WHERE Email =: TEST_EMAIL Limit 1];
        userToDeactivate.isActive = false;
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs(thisUser){
            Map<String, Object> recordValuesMap = new Map<String, Object>();
        	recordValuesMap.put('Community_Sales_Lead__c', userToDeactivate.Id);
        	Building__c testBuilding = TestingUtility.createBuilding(recordValuesMap, true);
        }
   
        Test.startTest();
        update userToDeactivate;        
        Test.stopTest(); 
        User_Attribute__c toCheck = [SELECT Id, User__c, End_Date__c FROM User_Attribute__c WHERE User__c =: userToDeactivate.Id LIMIT 1];
        System.assertEquals(Date.today(), toCheck.End_Date__c, 'End Date should be deactivated end date');
    }
}