/************************************************************************************************************************************
Author       :  Shubham Nandwana   
@Description :  Test class for AccConRelationRestrictionsTrH  
Issue No     :  TWSPG-3535
----------------------------------------------------------------------------------------------------------------------------------
VERSION    DATE              AUTHOR              ISSUE NO              DETAIL
1          30 August 2021    Shubham Nandwana    TWSPG-3535            Initial Developement
2          24 Mar, 2022      Pawel Biszczak                            Refactor
**************************************************************************************************************************************/
@isTest
public class AccConRelationRestrictionsTrHTest {
    static String billingAccountRecordtypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Billing Account').getRecordTypeId();
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
                        'LastName' => 'Test Contact',
                        'Email' => 'TestEmail@test.com',
                        'AccountId' => businessAccount.Id
                },
                true);
    }
    
    @isTest
    public static void accConRelationRestrictPrimaryMember_test_positive(){
        Test.startTest();
        List<Contact> contacts = [SELECT Id, Name FROM Contact];
        List<Account> accounts = [SELECT Id, Name FROM Account WHERE RecordTypeId =: billingAccountRecordtypeId];
        AccountContactRelation accConRel = new AccountContactRelation();
        accConRel.Roles = 'Primary Member';
        accConRel.AccountId = accounts.get(0).Id;
        accConRel.ContactId = contacts.get(0).Id;
        insert accConRel;
        
        accConRel = new AccountContactRelation();
        accConRel.Roles = 'Billing Administrator Member';
        accConRel.AccountId = accounts.get(0).Id;
        accConRel.ContactId = contacts.get(1).Id;
        insert accConRel;

        List<AccountContactRelation> accConRelations = [SELECT Id, Roles 
                                                        FROM AccountContactRelation
                                                        WHERE AccountId =: accounts.get(0).Id];
        System.assertEquals(2, accConRelations.size(), '2 AccountContactRelation records should be created');
        Test.stopTest();
    }

     @isTest
    public static void accConRelationRestrictPrimaryMember_test_negative(){
        Test.startTest();
        try{
            List<Contact> contacts = [SELECT id,name FROM Contact];
            List<Account> accounts = [SELECT id,name FROM Account WHERE RecordTypeId =: billingAccountRecordtypeId];
            AccountContactRelation accConRel = new AccountContactRelation();
            accConRel.Roles = 'Primary Member';
            accConRel.AccountId = accounts.get(0).Id;
            accConRel.ContactId = contacts.get(0).Id;
            insert accConRel;
            
            accConRel = new AccountContactRelation();
            accConRel.Roles = 'Billing Administrator Member';
            accConRel.AccountId = accounts.get(0).Id;
            accConRel.ContactId = contacts.get(1).Id;
            insert accConRel;
            List<AccountContactRelation> accConRelations = [SELECT Id, Roles 
                                                            FROM AccountContactRelation
                                                            WHERE AccountId =: accounts.get(0).Id];
            System.assertEquals(2, accConRelations.size(), '2 AccountContactRelation records should be created');
            
            accConRel.Roles = 'Primary Member';
            update accConRel;
        }catch(Exception ex){
            System.assertEquals('System.DmlException', ex.getTypeName(), 'Error is not returned correctly');
            System.assert(ex.getMessage().contains('FIELD_CUSTOM_VALIDATION_EXCEPTION'), 'Custom error is not returned');
        }
        Test.stopTest();
    }

    @isTest
    public static void shouldProceedWithOnNoDML(){
        List<Contact> contacts = getFakeContacts();
        List<Account> accounts = getFakeAccounts();
        List<AccountContactRelation> relations = new List<AccountContactRelation>();

        AccountContactRelation accContactRelation = new AccountContactRelation();
        accContactRelation.Roles = 'Primary Member';
        accContactRelation.AccountId = accounts.get(0).Id;
        accContactRelation.ContactId = contacts.get(0).Id;
        relations.add(accContactRelation);
        accContactRelation = new AccountContactRelation();
        accContactRelation.Roles = 'Billing Administrator Member';
        accContactRelation.AccountId = accounts.get(0).Id;
        accContactRelation.ContactId = contacts.get(1).Id;
        relations.add(accContactRelation);
        List<AccountContactRelation> existingRelations = new List<AccountContactRelation>();
        accContactRelation = new AccountContactRelation();
        accContactRelation.Roles = 'Test Role';
        accContactRelation.AccountId = accounts.get(0).Id;
        accContactRelation.ContactId = contacts.get(2).Id;
        existingRelations.add(accContactRelation);

        Test.startTest();
        AccConRelationRestrictionsTrH handlerInstance = new AccConRelationRestrictionsTrH();
        handlerInstance.newAccConRelations = relations;
        handlerInstance.isUserToBeBypassed = false;
        handlerInstance.accConRelationSelector = (AccountContactRelationSelector) MockService.createMock(
                AccountContactRelationSelector.class,
                new Map<String, Object>{
                        'getAccountContactRelationsByAccountIdsAndRoles' =>
                                existingRelations
                });
        handlerInstance.beforeInsert();
        Test.stopTest();

        System.assert(!handlerInstance.accountRoleToAccConRelations.isEmpty(),
                      'List of relations should not be empty for not bypassed User');
        System.assertEquals(3, handlerInstance.accountRoleToAccConRelations.size(),
                            'List of relations should contain 3 records - for existing and new roles');
    }

    static List<Account> getFakeAccounts() {
        Map<String, Object> recordsData = new Map<String, Object>();
        recordsData = new Map<String, Object>();
        recordsData.put('objectName', 'Account');
        recordsData.put('numberOfRecords', 1);
        return MockTestingUtility.getRecords(recordsData, true);
    }

    static List<Contact> getFakeContacts() {
        Map<String, Object> recordsData = new Map<String, Object>();
        recordsData = new Map<String, Object>();
        recordsData.put('objectName', 'Contact');
        recordsData.put('numberOfRecords', 3);
        return MockTestingUtility.getRecords(recordsData, true);
    }

}