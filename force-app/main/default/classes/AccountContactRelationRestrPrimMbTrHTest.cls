/*********************************************************************************************************
    Author        :  Krishna Somwanshi
    Description   :  Test class for AccountContactRelationRestrPrimMmbrTrH
    Issue No.     :  TWSPG-14844
    History       :
-----------------------------------------------------------------------------------------------------------
    VERSION        DATE            AUTHOR                DETAIL
    1             12-Oct-2022      Krishna Somwanshi     Initial
**********************************************************************************************************/
@isTest
public class AccountContactRelationRestrPrimMbTrHTest {
    static final String BILIINGACCOUNTRECORDTYPE = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Billing Account').getRecordTypeId();
    
    @isTest
    static void accountContactRelationRestrPrimMmbrTrH() {
        List<Account> businessAccount = getInsertedBusinessAccounts();
        List<Account> accounts = getInsertedBillingAccounts();
        List<Contact> contacts = getInsertedContacts(businessAccount);
        List<AccountContactRelation> accConRel = getInsertedAccountContactRelation(contacts, accounts);
        Test.startTest();
        AccountContactRelationRestrPrimMmbrTrH accountContactRelationRestrPrimMmbrTrH = new AccountContactRelationRestrPrimMmbrTrH();
        accountContactRelationRestrPrimMmbrTrH.newAccountContactRelation = accConRel;
        accountContactRelationRestrPrimMmbrTrH.beforeUpdate();
        Test.stopTest();
        System.assertNotEquals(null, accConRel[0].Roles,'AccountContactRelation has a Primary role');
        System.assertEquals('Primary Member', accConRel[1].Roles,'AccountContactRelation has a Primary role');
    }
    
    @isTest
    static void accountContactRelationRestrPrimMmbrMuleUser() {
        User mulesoftIntegrationUser = [SELECT ID FROM User WHERE Name = 'Mulesoft Integration User'];
        System.runAs(mulesoftIntegrationUser){
            List<Account> businessAccount = getInsertedBusinessAccounts();
            List<Account> accounts = getInsertedBillingAccounts();
            List<Contact> contacts = getInsertedContacts(businessAccount);
            List<AccountContactRelation> accConRel = getInsertedAccountContactRelation(contacts, accounts);
            Test.startTest();
            AccountContactRelationRestrPrimMmbrTrH accountContactRelationRestrPrimMmbrTrH = new AccountContactRelationRestrPrimMmbrTrH();
            accountContactRelationRestrPrimMmbrTrH.newAccountContactRelation = accConRel;
            accountContactRelationRestrPrimMmbrTrH.beforeUpdate();
            Test.stopTest();
            System.assertNotEquals(null, accConRel[0].Roles,'AccountContactRelation should get updated');
            System.assertEquals('Primary Member', accConRel[1].Roles,'AccountContactRelation should get updated');
        }
    }
    
    @isTest
    static void accountContactRelationRestrPrimMmbrDelete() {
        List<Account> businessAccount = getInsertedBusinessAccounts();
        List<Account> accounts = getInsertedBillingAccounts();
        List<Contact> contacts = getInsertedContacts(businessAccount);
        List<AccountContactRelation> accConRel = getInsertedAccountContactRelation(contacts, accounts);
        Test.startTest();
        AccountContactRelationRestrPrimMmbrTrH accountContactRelationRestrPrimMmbrTrH = new AccountContactRelationRestrPrimMmbrTrH();
        accountContactRelationRestrPrimMmbrTrH.oldAccountContactRelations = accConRel;
        accountContactRelationRestrPrimMmbrTrH.beforeDelete();
        Test.stopTest();
        System.assertNotEquals(null, accConRel[0].Roles,'AccountContactRelation should get updated');
        System.assertEquals('Primary Member', accConRel[1].Roles,'AccountContactRelation should get updated');
    }
    
    @isTest
    static void accountContactRelationRestrPrimMmbrDeleteMuleUser() {
        User mulesoftIntegrationUser = [SELECT ID FROM User WHERE Name = 'Mulesoft Integration User'];
        System.runAs(mulesoftIntegrationUser){
            List<Account> businessAccount = getInsertedBusinessAccounts();
            List<Account> accounts = getInsertedBillingAccounts();
            List<Contact> contacts = getInsertedContacts(businessAccount);
            List<AccountContactRelation> accConRel = getInsertedAccountContactRelation(contacts, accounts);
            Test.startTest();
            AccountContactRelationRestrPrimMmbrTrH accountContactRelationRestrPrimMmbrTrH = new AccountContactRelationRestrPrimMmbrTrH();
            accountContactRelationRestrPrimMmbrTrH.oldAccountContactRelations = accConRel;
            accountContactRelationRestrPrimMmbrTrH.beforeDelete();
            Test.stopTest();
            System.assertNotEquals(null, accConRel[0].Roles,'AccountContactRelation should get updated');
            System.assertEquals('Primary Member', accConRel[1].Roles,'AccountContactRelation should get updated');
        }
    }
    
    private static List<AccountContactRelation> getInsertedAccountContactRelation(List<Contact> contacts, List<Account> accounts){
         List<AccountContactRelation> testAccountContactRelations = new List<AccountContactRelation>();
        for(Integer i = 0; i < 2; i++) {
            testAccountContactRelations.add(new AccountContactRelation(
                Roles = 'Primary Member',
                AccountId = accounts.get(i).Id,
                ContactId = contacts.get(i).Id
            ));
        }
        return testAccountContactRelations;
    }
    
    private static List<Account> getInsertedBillingAccounts() {
        List<Account> testAccounts = new List<Account>();
        for(Integer i = 0; i < 2; i++) {
            testAccounts.add(new Account(
                Id = TestUtility.getFakeId(Account.getSObjectType()),
                Name = 'Test Billing Account ' + i,
                RecordTypeId = BILIINGACCOUNTRECORDTYPE,
                Interested_in_Number_of_Desks__c = 10,
                Number_of_Full_Time_Employees__c = 12
            ));
        }
        return testAccounts;
    }
    
    private static List<Contact> getInsertedContacts(List<Account> businessAccount) {
        List<Contact> testContacts = new List<Contact>();
        for(Integer i = 0; i < 2; i++) {
            testContacts.add(new Contact(
                Id = TestUtility.getFakeId(Contact.getSObjectType()),
                LastName = 'Test Contact ' + i,
                Email = 'TestEmail'+i+'@test.com',
                AccountId = businessAccount[i].Id
            ));
        }
        return testContacts;
    }
    
     private static List<Account> getInsertedBusinessAccounts() {
        List<Account> testAccounts = new List<Account>();
        for(Integer i = 0; i < 2; i++) {
            testAccounts.add(new Account(
                Id = TestUtility.getFakeId(Account.getSObjectType()),
                Name = 'Test Business Account ' + i,
                Account_Type__c = 'Org'
            ));
        }
        return testAccounts;
    }
    
}