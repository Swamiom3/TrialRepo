@isTest
private class OIDT_GenerateTaxTest {
    private static AccountSelector accountSelector = new AccountSelector();
    public static final Id billingRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Billing Account').getRecordTypeId();
    @testSetup
    static void makeData() {
        OIDT_TestDataFactory.createTestRecords();
    }

    @isTest
    static void getQuoteTaxFieldsTest() {
        SBQQ__Quote__c quote =[SELECT Id,Calculated_Tax_Amount__c FROM SBQQ__Quote__c LIMIT 1];
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new OIDT_TestDataFactory.MockHttpResponseGenerator());
        Map<String,String> quoteRespMap=OIDT_GenerateTax.getQuoteTaxFields(quote.Id,false);
    
        System.assertEquals(quoteRespMap.isEmpty(),false,'Quote tax calculation failed');
        Test.stopTest();
        SBQQ__Quote__c taxUpdatedQuote =[SELECT Id,Calculated_Tax_Amount__c FROM SBQQ__Quote__c where Id=:quote.id];
        System.assertNotEquals(taxUpdatedQuote.Calculated_Tax_Amount__c,quote.Calculated_Tax_Amount__c,'Quote tax calculation failed');
    }

    @isTest
    static void getQuoteTaxFieldsMissingBillToTest() {
        SBQQ__Quote__c quote =[SELECT Id,SBQQ__Account__c FROM SBQQ__Quote__c LIMIT 1];
        Account accunt =[SELECT Id FROM Account WHERE Name='Account without billing details' LIMIT 1];
        quote.SBQQ__Account__c=accunt.Id;
        update quote;
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new OIDT_TestDataFactory.MockHttpResponseGenerator());
        Map<String,String> quoteRespMap=OIDT_GenerateTax.getQuoteTaxFields(quote.id,false);
        System.assertEquals(quoteRespMap.get('status'),'MissingBillTo','Account billing details should not be blank');
        Test.stopTest();
    }
    
    @isTest
    static void getQuoteTaxFieldsMissingShipFromTest() {
        SBQQ__Quote__c quote =[SELECT Id,Building_Id__r.Legal_Entity_Id__c FROM SBQQ__Quote__c LIMIT 1];
        blng__LegalEntity__c legalEntity =[SELECT Id,blng__ZipPostalCode__c FROM blng__LegalEntity__c WHERE Id=:quote.Building_Id__r.Legal_Entity_Id__c LIMIT 1];
        legalEntity.blng__ZipPostalCode__c=null;
        update legalEntity;
        Test.startTest();
        Map<String,String> quoteRespMap=OIDT_GenerateTax.getQuoteTaxFields(quote.id,false);
        System.assertEquals(quoteRespMap.get('status'),'MissingShipFrom','Legal entity shipping address details should not be blank');
        Test.stopTest();
    }    
    
        
    @isTest
    static void getQuoteTaxFieldsInvalidStatusTest() {
        SBQQ__Quote__c quote =[SELECT Id,Building_Id__r.Legal_Entity_Id__c,SBQQ__Status__c FROM SBQQ__Quote__c LIMIT 1];
        quote.SBQQ__Status__c='Draft';
        update quote;
        Test.startTest();
        Map<String,String> quoteRespMap=OIDT_GenerateTax.getQuoteTaxFields(quote.id,false);
        System.assertEquals(quoteRespMap.get('status'),'invalidStatus','Only Accepted/Approved/Presented quotes are allowed to update tax.');
        Test.stopTest();
    }
    
    
    @isTest
    static void getOrderTaxFieldsTest() {
        Order orderRec =[SELECT Id,Calculated_Tax_Amount__c FROM Order LIMIT 1];
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new OIDT_TestDataFactory.MockHttpResponseGenerator());
        Map<String,String> orderRespMap=OIDT_GenerateTax.orderTaxFields(OrderRec.Id,false);
        System.assertEquals(orderRespMap.isEmpty(),false,'Order tax calculation failed');
        Test.stopTest();
        Order taxUpdatedOrderRec =[SELECT Id,Calculated_Tax_Amount__c FROM Order where Id=:orderRec.id];
        System.assertNotEquals(taxUpdatedOrderRec.Calculated_Tax_Amount__c,orderRec.Calculated_Tax_Amount__c,'Order tax calculation failed');
     }

    @isTest
    static void orderTaxFieldsMissingBillToTest() {
        Order orderRec =[SELECT Id,AccountId FROM Order LIMIT 1];
        Account accunt =[SELECT Id FROM Account WHERE Name='Account without billing details' LIMIT 1];
        orderRec.AccountId=accunt.Id;
        update orderRec;
        
        Test.startTest();
        Map<String,String> orderRespMap=OIDT_GenerateTax.orderTaxFields(orderRec.id,false);
        System.assertEquals(orderRespMap.get('status'),'MissingBillTo','Account billing details should not be blank');
        Test.stopTest();
    }
    
    @isTest
    static void orderTaxFieldsMissingShipFromTest() {
        Order orderRec =[SELECT Id,Building_Id__r.Legal_Entity_Id__c FROM Order LIMIT 1];
        blng__LegalEntity__c legalEntity =[SELECT Id,blng__ZipPostalCode__c FROM blng__LegalEntity__c WHERE Id=:orderRec.Building_Id__r.Legal_Entity_Id__c LIMIT 1];
        legalEntity.blng__City__c=null;
        update legalEntity;
        Test.startTest();
        Map<String,String> orderRespMap=OIDT_GenerateTax.orderTaxFields(orderRec.id,false);
        System.assertEquals(orderRespMap.get('status'),'MissingShipFrom','Order associated Legal entity shipping address details should not be blank');
        Test.stopTest();
    }    

    
    @isTest
    static void getcnTaxFieldsTest() {
        blng__CreditNote__c creditNote =[SELECT Id,Calculated_Tax_Amount__c FROM blng__CreditNote__c LIMIT 1];
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new OIDT_TestDataFactory.MockHttpResponseGenerator());
        Map<String,String> creditNoteRespMap=OIDT_GenerateTax.cnTaxFields(creditNote.Id,false);
        System.assertEquals(creditNoteRespMap.isEmpty(),false,'creditNote tax calculation failed');
        Test.stopTest();
        blng__CreditNote__c taxUpdatedcreditNote =[SELECT Id,Calculated_Tax_Amount__c FROM blng__CreditNote__c where Id=:creditNote.id];
        System.assertNotEquals(taxUpdatedcreditNote.Calculated_Tax_Amount__c,creditNote.Calculated_Tax_Amount__c,'creditNote tax calculation failed');

    }

    @isTest
    static void cnTaxFieldsMissingShipFromTest() {
        blng__CreditNote__c creditNote =[SELECT Id,Building_Id__r.Legal_Entity_Id__c FROM blng__CreditNote__c LIMIT 1];
        blng__LegalEntity__c legalEntity =[SELECT Id,blng__ZipPostalCode__c FROM blng__LegalEntity__c WHERE Id=:creditNote.Building_Id__r.Legal_Entity_Id__c LIMIT 1];
        legalEntity.blng__City__c=null;
        update legalEntity;
        Test.startTest();
        Map<String,String> creditNoteRespMap=OIDT_GenerateTax.cnTaxFields(creditNote.id,false);
        System.assertEquals(creditNoteRespMap.get('status'),'MissingShipFrom','Credit Note associated Legal entity shipping address details should not be blank');
        Test.stopTest();
    }    
    @isTest
    static void invoiceTaxFieldsTest() {
        blng__Invoice__c invoice =[SELECT Id,Calculated_Tax_Amount__c FROM blng__Invoice__c LIMIT 1];
    
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new OIDT_TestDataFactory.MockHttpResponseGenerator());
        Map<String,String> invoiceRespMap=OIDT_GenerateTax.invoiceTaxFields(invoice.Id,false);
        System.assertEquals(invoiceRespMap.isEmpty(),false,'invoice tax calculation failed');
        Test.stopTest();
        blng__Invoice__c taxUpdatedInvoice =[SELECT Id,Calculated_Tax_Amount__c FROM blng__Invoice__c where Id=:invoice.id];
        System.assertNotEquals(taxUpdatedInvoice.Calculated_Tax_Amount__c,invoice.Calculated_Tax_Amount__c,'invoice tax calculation failed');
        OIDT_OneSourceTaxGenCtrl.calculateTax(new List<String>{invoice.Id});
    }

    @isTest
    static void invoiceTaxFieldsMissingShipFromTest() {
        blng__Invoice__c invoice =[SELECT Id,Building_Id__r.Legal_Entity_Id__c FROM blng__Invoice__c LIMIT 1];
        blng__LegalEntity__c legalEntity =[SELECT Id,blng__ZipPostalCode__c FROM blng__LegalEntity__c WHERE Id=:invoice.Building_Id__r.Legal_Entity_Id__c LIMIT 1];
        legalEntity.blng__City__c=null;
        update legalEntity;
        Test.startTest();
        Map<String,String> invoiceRespMap=OIDT_GenerateTax.invoiceTaxFields(invoice.id,false);
        System.assertEquals(invoiceRespMap.get('status'),'MissingShipFrom','Invoice associated Legal entity shipping address details should not be blank');
        Test.stopTest();
    }
    
     @isTest
    static void updateQuoteTest() {
        SBQQ__Quote__c sq = [select id from SBQQ__Quote__c];
        Map<String,String> smap = new Map<String,String>();
        Test.startTest();
        OIDT_GenerateTax.updateQuote(smap,sq.id);
        Test.stopTest();
    }
}