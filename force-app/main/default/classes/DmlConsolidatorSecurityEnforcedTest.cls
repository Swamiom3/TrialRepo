@isTest
public with sharing class DmlConsolidatorSecurityEnforcedTest {

    static final String TEST_USERNAME = 'cjilag1234423@test.com';

    @testSetup
    static void makeData(){
        insert new User(
            UserRoleId = [SELECT Id FROM UserRole WHERE PortalType = 'None' LIMIT 1].Id,
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Minimum Access - Salesforce' LIMIT 1].Id,
            Username = TEST_USERNAME,
            Alias = 'batman',
            Email = 'testtermsconditions1234423@kaplan.com',
            EmailEncodingKey = 'UTF-8',
            Firstname = 'Bruce',
            Lastname = 'Wayne',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'America/Chicago'
        );
    }

    @isTest
    static void testConsolidatorSecurityEnforcedInsert() {
        Test.startTest();
        System.runAs([SELECT Id FROM User WHERE Username = :TEST_USERNAME][0]) {
            try {
                DmlConsolidatorSecurityEnforced.getInstance()
                                               .add(new List<Account>{new Account(Name = 'test 1')}, DmlConsolidator.Operation.FOR_INSERT)
                                               .run();
                System.assert(false, 'Exception must be thrown');
            } catch (Exception ex) {
                System.assert(ex instanceof NoAccessException, 'Error should be related to missing user access');
            }
        }
        Test.stopTest();
    }

    @isTest
    static void testConsolidatorSecurityEnforcedUpdateAndDelete() {
        Account acc = UtilAccount.GetNewAccounts(1, true)[0];
        acc.Name = 'test 1';
        Test.startTest();
        System.runAs([SELECT Id FROM User WHERE Username = :TEST_USERNAME][0]) {
            try {
                DmlConsolidatorSecurityEnforced.getInstance()
                                               .add(new List<SObject>{acc}, DmlConsolidator.Operation.FOR_UPDATE)
                                               .run();
                System.assert(false, 'Exception must be thrown');
            } catch (Exception ex) {
                System.assert(ex instanceof NoAccessException, 'NoAccessException should be thrown');
                System.assert(ex.getMessage().contains('No access to entity'), 'Error should be related to missing user access');
            }
            try {
                DmlConsolidatorSecurityEnforced.getInstance()
                                                .add(new List<SObject>{acc}, DmlConsolidator.Operation.FOR_DELETE)
                                                .run();
                System.assert(false, 'Exception must be thrown');
            } catch (Exception ex) {
                System.assert(ex instanceof DmlException, 'DmlException should be thrown');
                System.assert(ex.getMessage().contains('INSUFFICIENT_ACCESS_OR_READONLY'), 'Error should be related to missing user access');
            }
        }
        Test.stopTest();
    }
}