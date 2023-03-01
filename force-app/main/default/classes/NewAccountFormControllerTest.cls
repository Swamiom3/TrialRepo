@isTest
public with sharing class NewAccountFormControllerTest {
    @TestSetup
    static void setup(){
        List<Account> lstAccounts = new List<Account>();
        List<Contact> lstContacts = new List<Contact>();
        Account objParentAccount = new Account(Name = 'GrandParent', RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Business Account').getRecordTypeId(), Account_Type__c = 'Org');
        insert objParentAccount;
        Map<String, Object> contactValuesMap = new Map<String, Object>{'FirstName' => 'strContact', 'AccountId' => objParentAccount.Id};
        for(Integer index = 0; index < 10; index++){
            contactValuesMap.put('Email', 'NickTest'+index+'@gmail.com');
            lstContacts.add((Contact) TestingUtility.createContact(contactValuesMap, false));
        }
        Test.startTest();
        TestingUtility.insertListWithAssert(lstContacts); 
        Map<String, Object> accountValuesMap = new Map<String, Object>{'Name' => 'strAccountName','Phone' => '6262655424', 'Website'=>'www.wework.com','Account_Type__c' => 'Org','RecordTypeId' =>  Schema.SObjectType.Account.getRecordTypeInfosByName().get('Business Account').getRecordTypeId()};
        for(Integer i = 0; i<lstContacts.size(); i++){
            Account a = TestingUtility.getAccountsByType(accountValuesMap, 'Org', 1)[0];     
            a.Name += i;
            a.Primary_Member__c = lstContacts[i].Id;
            lstAccounts.add(a);
        }
        TestingUtility.insertListWithAssert(lstAccounts);
        Test.stopTest();
        System.assertEquals([SELECT Id FROM Account].size(), 11);
        System.assertEquals([SELECT Id FROM Contact].size(), 10);
    }
    
    @isTest
    public static void testAccountNameSearch() {
        Map<String, Map<String, String>> fieldSettings = BillingAccountMigratorServices.getFieldLabels('Account', new List<String>{'Name'}, new Map<String, String>(), new Map<String, String>());
        List<Account> lstReturnAccounts = NewAccountFormController.getAccountsByCriteria(JSON.serialize(new Map<String, String>{'Name'=>'strAcc'}), fieldSettings);
        System.assertEquals(10, lstReturnAccounts.size());

    }


    @isTest
    public static void testAccountWebsiteSearch() {
        Map<String, Map<String, String>> fieldSettings = BillingAccountMigratorServices.getFieldLabels('Account', new List<String>{'Website'}, new Map<String, String>(), new Map<String, String>());
        List<Account> lstReturnAccounts = NewAccountFormController.getAccountsByCriteria(JSON.serialize(new Map<String, String>{'Name'=>'strAcc','Website'=>'https://www.wework.com'}), fieldSettings);
        System.assertEquals(10, lstReturnAccounts.size());
    }


    @isTest
    public static void testAccountEmailSearch() {
        Map<String, Map<String, String>> fieldSettings = BillingAccountMigratorServices.getFieldLabels('Account', new List<String>{'Primary_Contact_Email__c'}, new Map<String, String>(), new Map<String, String>());
        List<Account> lstReturnAccounts = NewAccountFormController.getAccountsByCriteria(JSON.serialize(new Map<String, String>{'Name'=>'strAcc','Primary_Contact_Email__c'=>'NickTest3@gmail.com'}), fieldSettings);
        System.assertEquals(10, lstReturnAccounts.size());
    }


    @isTest
    public static void testAccountPhoneSearch() {
        Map<String, Map<String, String>> fieldSettings = BillingAccountMigratorServices.getFieldLabels('Account', new List<String>{'Phone'}, new Map<String, String>(), new Map<String, String>());
        List<Account> lstReturnAccounts = NewAccountFormController.getAccountsByCriteria(JSON.serialize(new Map<String, String>{'Name'=>'strAcc','Phone'=>'6262655424'}), fieldSettings);
        System.assertEquals(10, lstReturnAccounts.size());
    }
    
    @isTest
    public static void getParsedWebsiteTest() {
        String website='www.google.com';
        String parsedWebsite=NewAccountFormController.getParsedWebsite(website);
        System.assertEquals('google',parsedWebsite);
    }
    
    @isTest
    public static void getCleansedNameTest() {
        String name='Akash.Test/Name';
        String cleansedName=NewAccountFormController.getCleansedName(name);
        System.assertEquals('Name',cleansedName);
    }
}