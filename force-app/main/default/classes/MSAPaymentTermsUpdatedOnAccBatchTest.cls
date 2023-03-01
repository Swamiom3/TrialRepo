/************************************************************************************************************************************
    Author      :   Stepan Vardzal
    Description :   Test Class to cover MSAPaymentTermsUpdatedOnAccountsBatch
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION     DATE                AUTHOR                  DETAIL
    1           Jul 07, 2022        Stepan Vardzal          Initial version
**************************************************************************************************************************************/
@isTest
public class MSAPaymentTermsUpdatedOnAccBatchTest {

    @isTest
    private static void testPaymentTermsFieldUpdate() {
        List<Account> testAccounts = new List<Account>();
        for (Integer i = 0; i < 4; i++) {
            Account acc = new Account(Id = TestUtility.getFakeId(Account.SObjectType), Name = 'Test Account ' + i);
            if (i < 2) {
                acc.Payment_Terms__c = 'Due on receipt';
            }
            testAccounts.add(acc);
        }

        System.assertEquals('Due on receipt', testAccounts[0].Payment_Terms__c, 'First Account on the list should have populated the field Payment_Terms__c with the value - Due on receipt');
        System.assertEquals('Due on receipt', testAccounts[1].Payment_Terms__c, 'Second Account on the list should have populated the field Payment_Terms__c with the value - Due on receipt');

        Test.startTest();
        MSAPaymentTermsUpdatedOnAccountsBatch batchClassInstance = new MSAPaymentTermsUpdatedOnAccountsBatch();
        batchClassInstance.paymentTermsFieldUpdate(testAccounts);
        Test.stopTest();

        System.assertEquals(null, testAccounts[0].Payment_Terms__c, 'First Account on the list should not have populated the field Payment_Terms__c');
        System.assertEquals(null, testAccounts[1].Payment_Terms__c, 'Second Account on the list should not have populated the field Payment_Terms__c');
    }

    @isTest
    private static void testGetResultMessage() {

        Test.startTest();
        MSAPaymentTermsUpdatedOnAccountsBatch batchClassInstance = new MSAPaymentTermsUpdatedOnAccountsBatch();
        batchClassInstance.totalSucceededRecords = 66;
        batchClassInstance.totalFailedRecords = 3;
        batchClassInstance.getResultMessage('TestUser', 69, 3, 'testuser@mail.com', 'Success');
        Test.stopTest();

        List<EmailMessage> results = [SELECT Id, CreatedById, CreatedDate, HtmlBody FROM EmailMessage];

        System.assertEquals(1, results.size(), 'List of EmailMessage should containe 1 message');
        System.assert(results[0].HtmlBody.contains('Hi TestUser,'));
    }

    @isTest
    private static void testWithRealData() {
        List<Account> testAccounts = new List<Account>();
        for (Integer i = 0; i < 4; i++) {
            Account acc = new Account(Name = 'Real Test Account ' + i);
            if (i < 2) {
                acc.Payment_Terms__c = 'Due on receipt';
                acc.MSA_Expiration__c = Date.today();
            }
            testAccounts.add(acc);
        }
        insert testAccounts;

        Test.startTest();
        MSAPaymentTermsUpdatedOnAccountsBatch batchClassInstance = new MSAPaymentTermsUpdatedOnAccountsBatch();
        Id batchId = Database.executeBatch(batchClassInstance, 4);
        Test.stopTest();

        System.assertEquals(2, [SELECT count() FROM Account WHERE Payment_Terms__c = 'Due on receipt'], 'Records was not updated according to logic');
    }
}