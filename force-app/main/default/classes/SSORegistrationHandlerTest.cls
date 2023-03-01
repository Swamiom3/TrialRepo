@isTest
private class SSORegistrationHandlerTest {
    
    static final String USER_EMAIL = 'testSSOUser@wework.com';
    
    @testSetup
    static void setup() {
        User u = UtilUser.createUser([SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id, false);
        String fedId = USER_EMAIL + '.service';
        //needed to be dynamic to work on every sbox
        if([SELECT IsSandbox FROM Organization].IsSandbox){
            String baseUrl = System.URL.getSalesforceBaseUrl().toExternalForm();
            fedId = fedId + '.' + baseUrl.substringBetween('--','.');
        }
        u.FederationIdentifier = fedId;
        u.Email = USER_EMAIL;
        insert u;
    }
    
    @isTest
    static void createUserTest() {
        SSORegistrationHandler handler = new SSORegistrationHandler();

        User u = [
            SELECT Id, Email, FirstName, LastName, Name 
            FROM User 
            WHERE Email = :USER_EMAIL 
            LIMIT 1
        ];
        
        Auth.UserData sampleData = new Auth.UserData(
            u.Id, u.FirstName, u.LastName, u.Name, u.Email, 
            null, 'test', 'en_US', 'facebook',null, 
            new Map<String, String>{'language' => 'en_US'}
        );
        
        Test.startTest();
        User createdUser = handler.createUser(null, sampleData);
        Test.stopTest();
        
        System.assertEquals(createdUser.Email, u.Email, 'Email should be the same');
    }

    @isTest
    static void sanitizeEmailTest(){
        String testEmailNotLoggedIn = 'mm@wework.com.invalid';
        String testEmailLoggedIn = 'mm@wework.com';

        SSORegistrationHandler handler = new SSORegistrationHandler();
        System.assert(handler.sanitizeEmail(testEmailNotLoggedIn) == 'mm@wework.com', 'Email should have suffix .invalid removed');
        System.assert(handler.sanitizeEmail(testEmailLoggedIn) == testEmailLoggedIn, 'Email should be the same');
    }
}