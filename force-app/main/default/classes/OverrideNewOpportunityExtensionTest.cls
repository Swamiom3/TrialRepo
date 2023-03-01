@isTest
public class OverrideNewOpportunityExtensionTest {
    @isTest
    public static void testOverrideNewOpportunityExtension() {
        Map<String, Object> accountValuesMap1 = new Map<String, Object>{
            'Name' => 'Company2',
            'Account_Type__c' => 'Org',
            'RecordTypeId' => Schema.SObjectType.Account.getRecordTypeInfosByName().get('Billing Account').getRecordTypeId()
        };
        Account testAcc = TestingUtility.getAccountsByType(accountValuesMap1, 'Org', 1)[0];
        Test.startTest();
        PageReference objPageRef = Page.OverrideNewOpportunityPage;
        Test.setCurrentPage(objPageRef);
        objPageRef.getParameters().put('recordId',testAcc.id);
        OverrideNewOpportunityExtension objExtension = new OverrideNewOpportunityExtension(new ApexPages.StandardController(testAcc));
        System.assertEquals(testAcc.Id, objExtension.billingAccountId);
        Test.stopTest();
    }
}