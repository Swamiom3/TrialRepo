@isTest
public class AccountUpdateCIUnomyCompanyTrHTest {
    
    @testSetup 
    private static void initData(){
        List<Account> accounts = new List<Account>();
        List<CI_Company__c> unomyCompanies = TestingUtility.getRecords(new Map<String, Object>{'objName' => 'unomy', 'numberOfRecords' => 1, 'doInsert' => true});
        
        Account testAccount = TestingUtility.createAccount(new Map<String,Object>{'Name' => 'Test Account', 
            'Account_Type__c' => 'Org', 
            'UUID__c' => 'account-uuid-org', 
            'Nickname__c' => 'OrgAcc'}, false);
        TestingUtility.insertWithAssert(testAccount);        
        Contact testContact = TestingUtility.createContact(new Map<String,Object>{'LastName' => 'TestContact',
            'Email' => 'testcontact@example.com',
            'AccountId' => testAccount.Id}, false);
        TestingUtility.insertWithAssert(testContact);
    }
    
    @isTest
    private static void verifyUpdateCIUnomyCompanyOnContact(){
        Test.startTest();
        Account testAccount = [SELECT Id, CI_Company__c FROM Account WHERE Name = 'Test Account'];
        CI_Company__c objUnomyCompany = [SELECT Id, Company_Name__c FROM CI_Company__c LIMIT 1];
        testAccount.CI_Company__c = objUnomyCompany.Id;
        TestingUtility.updateWithAssert(testAccount);
        Contact testContact = [SELECT Id, CI_Company__c, CI_Updated_DateTime__c, AccountId, Account.CI_Company__c FROM Contact WHERE AccountId = :testAccount.Id];
        Test.stopTest();
        if(String.isNotBlank(testContact.AccountId)){ 
            System.assertEquals(testContact.Account.CI_Company__c, testContact.CI_Company__c);
            System.assertNotEquals(null, testContact.CI_Updated_DateTime__c);
        }
    }
}