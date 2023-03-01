/*
reid.carlberg@salesforce.com
creates entities required for testing.
*/
@isTest
public with sharing class TestUtility {
    
    private static Integer sNum = 1;
    private static String[] nummap = new String[] { '0','1','2','3','4','5','6','7','8','9' };
    private static String[] charmap = new String[] {
        '0','1','2','3','4','5','6','7','8','9',
        'a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v','w','x','y','z',
        'A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z'
    };
    private static final Profile SYS_ADMIN_PROFILE = getSystemAdminProfile(); 
    
    /*
        A random user is useful for testing in order to be 
        sure that you are able to see data across posts regardless
        of follow status.
    */  
    public static User createTestUser() {
        return createTestUser(SYS_ADMIN_PROFILE, null);
    }

    public static User createTestUser(Id managerId) {
        return createTestUser(SYS_ADMIN_PROFILE, managerId);
    }

    public static User createTestUser(Profile p, Id managerId) {
        String namePrefix = 'Doe';
        User testUser = new User();
        testUser.Email = 'test'  + TestUtility.generateRandomNum(2) + '@test.com';
        testUser.Username = namePrefix + TestUtility.generateRandomString(8) + '@testuser.com';
        testUser.LastName = 'test';
        testUser.Alias = 'test' + TestUtility.generateRandomNum(2);
        testUser.ProfileId = p.Id;
        testUser.LanguageLocaleKey = 'en_US';
        testUser.LocaleSidKey = 'en_US';
        testUser.TimeZoneSidKey = 'America/Chicago';
        testUser.EmailEncodingKey = 'UTF-8';
        testUser.ManagerId = managerId;
        insert testUser;
        return testUser;
    }
    
    public static User createTestUser(String profileName) {
        Profile p = [SELECT Id FROM Profile WHERE Name = :profileName LIMIT 1];
        User u = new User(
            LastName = '#test-user',
            Alias = '#tu',
            Email = 'user@unit-test.com',
            Username = 'unit-test-user@gold-event.com',
            CommunityNickname = '#tu',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = p.Id
        );
        insert u;
        return u;
    }
    
    /**
    * Create a  random string
    * @param strLength string Length 
    */
    public static String generateRandomString( Integer strLength ) {
        String nonce = '';
        for (Integer i = 0; i < strLength; ++i) {
            nonce += charmap.get(Math.min((Math.random() * charmap.size()).intValue(), charmap.size() - 1));
        }
        return nonce;
    }
    /**
    * Create a  random email
    */
    public static String generateRandomEmail() {
        String nonce = '';
        String partA = generateRandomString(8);
        String partB = generateRandomString(6);
        
        nonce = partA +'@'+ partB +'.com';
        
        return nonce;
    }
    /**
    * Create a  random numb
    * @param strLength string Length 
    */
    public static String generateRandomNum( Integer strLength ) {
        String nonce = '';
        for (Integer i = 0; i < strLength; ++i) {
            nonce += nummap.get(Math.min((Math.random() * nummap.size()).intValue(), nummap.size() - 1));
        }
        return nonce;
    }

    public static String getFakeId(Schema.SObjectType sot){
        String result = String.valueOf(sNum++);
        return sot.getDescribe().getKeyPrefix() + 
           '0'.repeat(12-result.length()) + result;
    }

    public static Profile getSystemAdminProfile(){
        return [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
    }
}