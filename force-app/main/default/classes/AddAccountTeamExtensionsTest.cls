@isTest
public class AddAccountTeamExtensionsTest {
    @isTest
    public static void verifyPageCreation() {
        Map<String, Object> mapSingleAccount = new Map<String, Object>{'Name' => 'Account_Test','Account_Type__c' => 'Org', 'RecordTypeId' =>  Schema.SObjectType.Account.getRecordTypeInfosByName().get('Billing Account').getRecordTypeId()};
        List<Account> lstAccounts = TestingUtility.getAccountsByType(mapSingleAccount, 'Org', 1);
        insert lstAccounts;
        System.assertEquals(lstAccounts[0] != null, true, 'no account created');
        ApexPages.StandardController accountController = new ApexPages.StandardController(lstAccounts[0]);
        AddAccountTeamExtensions extension = new AddAccountTeamExtensions(accountController);

        Test.startTest();
        System.assertEquals(extension.currentAccount.Id, lstAccounts[0].Id, 'extension accountId==>'+extension.currentAccount.Id+' created account Id==> '+lstAccounts[0].Id);
    }
}