/*********************************************************************************************************
    Author        :  Krishna Somwanshi
    Description   :  This is test class for TransferContactController
    Issue No.     :  
    History       :
-----------------------------------------------------------------------------------------------------------
    VERSION        DATE            AUTHOR             DETAIL
    1          11-Jan-2023     Krishna Somwanshi     Initial Development
**********************************************************************************************************/
@isTest
public class TransferContactControllerTest {
    
    @TestSetup
    static void initData(){
        Account account = new Account();
        account.Name = 'Test Account';
        Account account1 = new Account();
        account1.Name = 'Test Account 1';
        insert account;
        insert account1;
        
        List<Contact> contacts = new List<Contact>();
        for(integer i=0;i<2;i++){
            Contact contact = new Contact();
            contact.FirstName = 'Test';
            contact.LastName = 'Contact '+i;
            contact.Email = 'testcontact'+i+'@gmail.com';
            contacts.add(contact);
        }
        insert contacts;
        
        Opportunity opportunity = new Opportunity();
        opportunity.Name = 'Test Opportunity';
        opportunity.Primary_Member__c = Contacts[0].Id;
        opportunity.StageName = 'Selling';
        opportunity.CloseDate = System.today();
        insert opportunity;
    }
    
    public static testmethod void transferContactAccount(){
        Test.startTest();
        list<Account> accounts = TransferContactController.getAccountList('Test Account');
        Test.stopTest();
        System.assertEquals('Test Account', accounts[0].Name, 'Account name should match');
        System.assertNotEquals('Test Account', accounts[1].Name, 'Account name should not match');
    }
    
    public static testmethod void transferContact(){
        Test.startTest();
        list<Contact> contacts = TransferContactController.getContactList('Test Contact');
        Test.stopTest();
        System.assertEquals('Test Contact 0', contacts[0].Name, 'Contact name should match');
        System.assertNotEquals('Test Contact 0', contacts[1].Name, 'Contact name should not match');
    }
    
    public static testmethod void updateContact(){
        List<Account> accounts = [SELECT Id, Name From Account];
        List<Contact> contacts = [SELECT Id, Name, AccountId From Contact];
        Test.startTest();
        TransferContactController.updateContact(contacts[0].Id, accounts[0].Id);
        Test.stopTest();
        List<Contact> contactsUpdates = [SELECT Id, Name, AccountId From Contact];
        System.assertEquals(contactsUpdates[0].AccountId, accounts[0].Id, 'Account should match on contact');
        System.assertNotEquals(contacts[0].AccountId, accounts[0].Id, 'Account should not match on contact');
    }
    public static testmethod void updateOpportunity(){
        List<Account> accounts = [SELECT Id, Name From Account];
        List<Contact> contacts = [SELECT Id, Name From Contact];
        Opportunity opportunity = [Select Id, Primary_Member__c, AccountId, Decision_Maker__c From Opportunity LIMIT 1];
        Test.startTest();
        TransferContactController.updateOpportunity(contacts[0].Id, accounts[0].Id);
        Test.stopTest();
        Opportunity opportunityUpdated = [Select Id, Primary_Member__c, AccountId, Decision_Maker__c From Opportunity LIMIT 1];
        System.assertEquals(opportunityUpdated.AccountId, accounts[0].Id, 'Account should matched on opportunity');
        System.assertNotEquals(opportunity.AccountId, accounts[0].Id, 'Account should not match on opportunity');
    }
}