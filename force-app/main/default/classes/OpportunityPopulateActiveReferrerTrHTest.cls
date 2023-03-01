/************************************************************************************************************************************
Author      :   Salesforce
Description :   Test class for OpportunityPopulateActiveReferrerTrH apex class
Issue No    :   TWSPG-9682
----------------------------------------------------------------------------------------------------------------------------------
VERSION         DATE             AUTHOR              DETAIL
  1        14 April 2022       Salesforce     Initial Development
**************************************************************************************************************************************/
@isTest
private with sharing class OpportunityPopulateActiveReferrerTrHTest {

    @testSetup
    static void createTestData() {
        Account account = TestingUtility.createAccount('Test Account', true);
        Contact referralContact = TestingUtility.createContact(account.Id, 'Referral Test', false);
        referralContact.Email = 'referral@email.com';
        Contact referrerContact = TestingUtility.createContact(account.Id, 'Referrer Test', false);
        referrerContact.Email = 'referrer@email.com';
        insert new List<Contact>{referralContact, referrerContact};
        Referral__c testReferral = new Referral__c(Name = 'Test Referral',Referral_Email__c = 'referral@email.com',Referrer__c = referrerContact.Id,IsActive__c = true);
        insert testReferral;
    }
    
    @isTest
    static void populateOpportunityActiveReferrer_test_positive() {
        Account account = [SELECT Id, Name FROM Account WHERE Name = 'Test Account' LIMIT 1];
        Contact referralContact = [SELECT Id, Name FROM Contact WHERE AccountId =: account.Id AND Email = 'referral@email.com' LIMIT 1];
        Contact referrerContact = [SELECT Id, Name FROM Contact WHERE AccountId =: account.Id AND Email = 'referrer@email.com' LIMIT 1];
        Opportunity testOpportunity = TestingUtility.createOpportunity(account.Id, false);
        testOpportunity.Primary_Member__c = referralContact.Id;
        Test.startTest();
        insert testOpportunity;
        Test.stopTest();
		Opportunity resultTestOpportunity = [SELECT Id, Referrer__c, Primary_Member__c, Primary_Member_Email_New__c FROM Opportunity WHERE Id =: testOpportunity.Id LIMIT 1];
        System.assertEquals(referrerContact.Id, resultTestOpportunity.Referrer__c, 'Opportunity Referrer should be equal to Referral Referrer');
    }
    
    @isTest
    static void populateOpportunityActiveReferrer_test_negative() {
        Account account = [SELECT Id, Name FROM Account WHERE Name = 'Test Account' LIMIT 1];
        Contact referralContact = [SELECT Id, Name FROM Contact WHERE AccountId =: account.Id AND Email = 'referral@email.com' LIMIT 1];
        Contact referrerContact = [SELECT Id, Name FROM Contact WHERE AccountId =: account.Id AND Email = 'referrer@email.com' LIMIT 1];
        Opportunity testOpportunity = TestingUtility.createOpportunity(account.Id, false);
        Test.startTest();
        insert testOpportunity;
        Test.stopTest();
		Opportunity resultTestOpportunity = [SELECT Id, Referrer__c, Primary_Member__c, Primary_Member_Email_New__c FROM Opportunity WHERE Id =: testOpportunity.Id LIMIT 1];
        System.assertNotEquals(referrerContact.Id, resultTestOpportunity.Referrer__c, 'Opportunity Referrer should not be equal to Referral Referrer');
    }
}