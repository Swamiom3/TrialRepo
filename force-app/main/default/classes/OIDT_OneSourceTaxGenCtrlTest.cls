@isTest
private class OIDT_OneSourceTaxGenCtrlTest {
 @testSetup
    static void makeTestData() {
        OIDT_TestDataFactory.createTestRecords();
    }
   @isTest
    static void getTaxFieldsQuoteTest() {
        SBQQ__Quote__c quote =[SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new OIDT_TestDataFactory.MockHttpResponseGenerator());
        Map<String,String> taxfields= OIDT_OneSourceTaxGenCtrl.getTaxFields(quote.Id,false);
        System.assertEquals(taxfields.isEmpty(),false,'Tax calculation failed');
        Test.stopTest();        
    }
   @isTest
    static void getTaxFieldsOrderTest() {
        Order order =[SELECT Id FROM Order LIMIT 1];
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new OIDT_TestDataFactory.MockHttpResponseGenerator());
        Map<String,String> taxfields= OIDT_OneSourceTaxGenCtrl.getTaxFields(order.Id,false);
        System.assertEquals(taxfields.isEmpty(),false,'Tax calculation failed');
        Test.stopTest();        
    }
   @isTest
    static void getTaxFieldsCreditNoteTest() {
        blng__CreditNote__c creditNote =[SELECT Id FROM blng__CreditNote__c LIMIT 1];
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new OIDT_TestDataFactory.MockHttpResponseGenerator());
        Map<String,String> taxfields= OIDT_OneSourceTaxGenCtrl.getTaxFields(creditNote.Id,false);
        System.assertEquals(taxfields.isEmpty(),false,'Tax calculation failed');
        Test.stopTest();        
    }   
   @isTest
    static void getTaxFieldsForNonBillingAccountTest() {
        SBQQ__Quote__c quote =[SELECT Id,SBQQ__Account__c FROM SBQQ__Quote__c LIMIT 1];
        Account blankBillingAccount=[SELECT Id FROM Account WHERE NAME='Account without billing details' LIMIT 1];
        quote.SBQQ__Account__c=blankBillingAccount.Id;
        update quote;
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new OIDT_TestDataFactory.MockHttpResponseGenerator());
        
        Map<String,String> taxfields= OIDT_OneSourceTaxGenCtrl.getTaxFields(quote.Id,false);
      
        System.assertEquals(taxfields.get('status'),'MissingBillTo','Billing address data is missing on Account.');
        
        Test.stopTest();
    }
    
     @isTest
    static void calculateTaxTest() {
        SBQQ__Quote__c sq = [select id from SBQQ__Quote__c];
        list<String> lst = new list<String>();
        lst.add(sq.Id);
       Test.startTest();
        OIDT_OneSourceTaxGenCtrl.calculateTax(lst);
         Test.stopTest();  
    }
    
}