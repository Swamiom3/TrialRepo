/*************************************************************************************************************************************
    Author      :   Pawel Biszczak
    Description :   This class provides sufficient test coverage for AccountContactRelationSelector class
    --------------------------------------------------------------------------------------------------------------------------------------
    VERSION     DATE            AUTHOR            DETAIL
    1           24 Mar, 2022    Pawel Biszczak    Initial Deployment
**************************************************************************************************************************************/
@isTest
public with sharing class AccountContactRelationSelectorTest {
    private static String billingAccountRecordtypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Billing Account').getRecordTypeId();
    private static AccountContactRelationSelector accConRelationSelector = new AccountContactRelationSelector();

    @testSetup
    static void makeData(){
        Account businessAccount = TestingUtility.createAccount('TestBusiness', true);
        TestingUtility.createAccount(
                new Map<String, Object>{
                        'Name' => 'Test Account',
                        'RecordTypeId' => billingAccountRecordtypeId,
                        'Interested_in_Number_of_Desks__c' => 10,
                        'Number_of_Full_Time_Employees__c' => 12
                },
                true);
        TestingUtility.createContact(businessAccount.Id, 'testContact', true);
        TestingUtility.createContact(
                new Map<String, Object>{
                        'FirstName' => 'First',
                        'LastName' => 'Test Contact',
                        'Email' => 'TestEmail@test.com',
                        'AccountId' => businessAccount.Id
                },
                true);

        List<Contact> contacts = [SELECT Id, Name FROM Contact];
        List<Account> accounts = [SELECT Id, Name FROM Account WHERE RecordTypeId =: billingAccountRecordtypeId];
        AccountContactRelation accConRel = new AccountContactRelation();
        accConRel.Roles = GlobalConstants.ACCOUNT_CONTACT_RELATION_ROLE_PRIMARY_MEMBER;
        accConRel.AccountId = accounts.get(0).Id;
        accConRel.ContactId = contacts.get(0).Id;
        insert accConRel;
    }

    @isTest
    static void shouldGetDefaultFields(){
        Set<String> fields;

        Test.startTest();
        fields = accConRelationSelector.getDefaultFields();
        Test.stopTest();

        System.assert(!fields.isEmpty(), 'Default fields should be presented');
    }

    @isTest
    public static void shouldReturnAccountContactRelationForSpecificRole() {
        Test.startTest();
        Set<Id> accountIds = new Map<Id, Account>([SELECT Id
                                                   FROM Account
                                                   WHERE RecordTypeId =: billingAccountRecordtypeId]).keySet();

        List<AccountContactRelation> relations =
                accConRelationSelector.getAccountContactRelationsByAccountIdsAndRoles(
                        new List<Id>(accountIds),
                        new List<String>{
                                GlobalConstants.ACCOUNT_CONTACT_RELATION_ROLE_PRIMARY_MEMBER,
                                'Additional Test Role'
                        });
        Test.stopTest();

        System.assert(!relations.isEmpty(), 'Should return at least one record for provided ids and roles');
    }

    @isTest
    static void testGetAccountContactRelationsByAccountIdsAndRoles() {
        Contact c = [SELECT Id FROM Contact LIMIT 1];
        Test.startTest();
        List<AccountContactRelation> result = accConRelationSelector.getAccountContactRelationsByAccountIdsAndRoles(c.Id);
        Test.stopTest();
        System.assertEquals(1, result.size(), 'Query must return relationship object for specified contact');
    }
}