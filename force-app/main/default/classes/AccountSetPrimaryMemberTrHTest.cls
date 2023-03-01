/************************************************************************************************************************************
Author              :   Mayuresh Ghodke
Description         :   Test class of AccountSetPrimaryMemberTrH apex class used to verify Set Primary Member of Account
Last Modified Date  :   05 July 2016
Last Modified By    :   Mayuresh Ghodke
**************************************************************************************************************************************/
@isTest
private with sharing class AccountSetPrimaryMemberTrHTest {
    
    @testSetup
    static void createTestData(){
        List<Account> lstAccountRecords = new List<Account>();
        List<Contact> lstContactRecords = new List<Contact>();
        lstAccountRecords.add(TestingUtility.createAccount(new Map<String,Object>{'Name' => 'Test Org Account','Account_Type__c' => 'Org','UUID__c' => 'account-uuid-org0', 
            												    'Nickname__c' => 'OrgAcc'}, false));
        insert lstAccountRecords;
        lstContactRecords.add(TestingUtility.createContact(new Map<String,Object>{'LastName' => 'TestContact1','Email' => 'testcontact1@example.com','AccountId' => lstAccountRecords[0].Id},false));
        lstContactRecords.add(TestingUtility.createContact(new Map<String,Object>{'LastName' => 'TestContact2','Email' => 'testcontact2@example.com'},false));
        insert lstContactRecords;
    }
    
    @isTest
    static void testPositive_AccountSetPrimaryMemberTrH(){
        Account testAccount = [SELECT Id, Name, Primary_Member__c FROM Account WHERE Name = 'Test Org Account' LIMIT 1];
        Contact  testContact1 = [SELECT Id, Name FROM Contact WHERE Email = 'testcontact1@example.com' LIMIT 1];
       
        testAccount.Primary_Member__c = null;
        update testAccount;
        
        Account resultTestAccount = [SELECT Id, Name, Primary_Member__c FROM Account WHERE Name = 'Test Org Account' LIMIT 1];
        System.assertEquals(resultTestAccount.Primary_Member__c, testContact1.Id, 'Contact should be primary member of account.');
    }
    
    @isTest
    static void testNegative_AccountSetPrimaryMemberTrH(){
        Account testAccount = [SELECT Id, Name, Primary_Member__c FROM Account WHERE Name = 'Test Org Account' LIMIT 1];
        Contact  testContact2 = [SELECT Id, Name FROM Contact WHERE Email = 'testcontact2@example.com' LIMIT 1];
        
        testAccount.Primary_Member__c = testContact2.Id;
        update testAccount;
        
        Account resultTestAccount = [SELECT Id, Name, Primary_Member__c FROM Account WHERE Name = 'Test Org Account' LIMIT 1];
        System.assertEquals(resultTestAccount.Primary_Member__c, testContact2.Id, 'Contact should be primary member of account.');
    }
}