/**********************************************************************************************************
Author        :  Salesforce
Description   :  This is a test class for UserSalesforceSchedulerTrH.
-----------------------------------------------------------------------------------------------------------
VERSION        DATE            AUTHOR           DETAIL
1              02-Sep-2021     Salesforce       
**********************************************************************************************************/
@isTest
public with sharing class UserSalesforceSchedulerTrHTest {
    @testSetup
    static void setup(){ 
        Profile testProfile = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        List<User> testUsersToInsert = new List<User>();
        testUsersToInsert.add(new User(Alias = 'testU', Email = 'sfschedulertestuser1@sfscheduler.com',
                                 EmailEncodingKey = 'UTF-8', LastName = 'User', LanguageLocaleKey = 'en_US',
                                 LocaleSidKey = 'en_US', ProfileId = testProfile.Id, IsActive = true,
                                 TimeZoneSidKey = 'America/Los_Angeles', Username = 'sfschedulertestuser1@sfscheduler.com', 
                                 CommunityNickname = TestingUtility.createUserCommunityName(), Salesforce_Scheduler_User__c = true));
        testUsersToInsert.add(new User(Alias = 'testU', Email = 'sfschedulertestuser2@sfscheduler.com',
                                 EmailEncodingKey = 'UTF-8', LastName = 'User', LanguageLocaleKey = 'en_US',
                                 LocaleSidKey = 'en_US', ProfileId = testProfile.Id, IsActive = true,
                                 TimeZoneSidKey = 'America/Los_Angeles', Username = 'sfschedulertestuser2@sfscheduler.com', 
                                 CommunityNickname = TestingUtility.createUserCommunityName(), Salesforce_Scheduler_User__c = false));
        insert testUsersToInsert;
    }

    @isTest
    private static void manageSalesforceSchedulerUsers_test_positive() {
        User testUser = [SELECT Id, Salesforce_Scheduler_User__c FROM User WHERE Username = 'sfschedulertestuser1@sfscheduler.com'];
        List<ServiceResource> sResources = [SELECT Id, IsActive FROM ServiceResource WHERE RelatedRecordId =: testUser.Id];
        System.assertEquals(true, sResources[0].IsActive, 'The Service Resource record should be created and activated');
        testUser.Salesforce_Scheduler_User__c = false;
        update testUser;
        System.assertEquals(true, sResources[0].IsActive, 'The Service Resource record should be created and activated');
    }

    @isTest
    private static void manageSalesforceSchedulerUsers_test_negative() {
        User testUser = [SELECT Id, Salesforce_Scheduler_User__c FROM User WHERE Username = 'sfschedulertestuser2@sfscheduler.com'];
        List<ServiceResource> sResources = [SELECT Id, IsActive FROM ServiceResource WHERE RelatedRecordId =: testUser.Id];
        System.assertEquals(0, sResources.size(), 'The Service Resource record should not be created');
    }

}