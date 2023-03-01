/************************************************************************************************************************************
Author      :   Tayo Chestnut
Description :   This is test class for apex class - Refund Selector
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION      DATE         AUTHOR              DETAIL
    1            12/20/2021   Tayo Chestnut     Test class for apex class - Refund Selector
**************************************************************************************************************************************/
@IsTest
public class RefundSelectorTest{
    private static RefundSelector rfSelector = new RefundSelector();
    @testSetup 
    static void createTestdata() {

        List<Account> listOfAccountToTest = (List<Account>)TestingUtility.getRecords(new Map<String, Object>{'objName' => 'Account', 'numberOfRecords' => 1});
        Account accountToTest = listOfAccountToTest.get(0);
        
        accountToTest.UUID__c = '1111';
        update accountToTest;

        blng__Refund__c refundToTest = new blng__Refund__c();
        refundToTest.blng__Account__c = accountToTest.Id;
        refundToTest.currencyIsoCode = 'CAD';
        refundToTest.blng__RefundType__c = 'ACH';
        refundToTest.blng__RefundMode__c = 'External';
        refundToTest.blng__Status__c = 'Draft';
        refundToTest.blng__RefundDate__c = System.today();
        refundToTest.Batch_Date__c = '20211220';
        refundToTest.Sequential_Bank_Counter__c = 1;
        insert refundToTest;
    }
    
    @isTest
    static void getDefaultFieldsTest(){
        Test.startTest();
        rfSelector.getDefaultFields();
        Test.stopTest();
        
        System.assertEquals(true,!rfSelector.defaultFields.isEmpty(),'Default Fields are Present');
    }
   
    @isTest
    static void getRefundPositive(){
        Test.startTest();
        RefundSelector rfSelector = new RefundSelector();
        List<blng__Refund__c> refundList = rfSelector.getCurrentRefundCounter('20211220');
        Test.stopTest();
        
        System.assertEquals(1, refundList.size(), 'No Matching Refund Record Found');
    }

    @isTest
    static void getRefundNegative(){
        Test.startTest();
        RefundSelector rfSelector = new RefundSelector();
        List<blng__Refund__c> refundList = rfSelector.getCurrentRefundCounter('20211221');
        Test.stopTest();
        
        System.assertEquals(0, refundList.size(), 'Matching Refund Record Found');
    }
    
   
}