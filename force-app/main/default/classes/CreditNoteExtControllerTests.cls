@isTest
private class CreditNoteExtControllerTests {
    @isTest
    static void testSubmit() {
        List<Account> listOfAccountToTest = (List<Account>)TestingUtility.getRecords(new Map<String, Object>{'objName' => 'Account', 'numberOfRecords' => 1});
        Account accountToTest = listOfAccountToTest.get(0);

        blng__CreditNote__c creditNote = new blng__CreditNote__c(blng__Account__c = accountToTest.Id, blng__CreditNoteDate__c = System.today());
        insert creditNote;
        
        List<Product2> productList = TestingUtility.createAllWeWorkProducts(TRUE);
        Product2 lineProduct = [SELECT Id FROM Product2 WHERE IsActive = TRUE LIMIT 1];

        blng__CreditNoteLine__c creditNoteLine = new blng__CreditNoteLine__c(blng__CreditNote__c = creditNote.Id, blng__CreditNoteLineDate__c = System.today(), blng__Product__c = lineProduct.Id, blng__Subtotal__c = 100);
        insert creditNoteLine;

        Test.startTest();
        CreditNoteExtController con = new CreditNoteExtController(new ApexPages.StandardController(creditNote));
        con.onSubmit();
        creditNote = [SELECT ApprovalStatus__c FROM blng__CreditNote__c WHERE Id = :creditNote.Id LIMIT 1];
        Test.stopTest();
        
        System.assertEquals('Approved', creditNote.ApprovalStatus__c,'Credit Note Not Approved');
    }

    @isTest
    static void testRecall() {
        List<Account> listOfAccountToTest = (List<Account>)TestingUtility.getRecords(new Map<String, Object>{'objName' => 'Account', 'numberOfRecords' => 1});
        Account accountToTest = listOfAccountToTest.get(0);
        
        blng__CreditNote__c creditNote = new blng__CreditNote__c(blng__Account__c = accountToTest.Id, blng__CreditNoteDate__c = System.today());
        insert creditNote;
        
        List<Product2> productList = TestingUtility.createAllWeWorkProducts(TRUE);
        Product2 lineProduct = [SELECT Id FROM Product2 WHERE IsActive = TRUE LIMIT 1];

        blng__CreditNoteLine__c creditNoteLine = new blng__CreditNoteLine__c(blng__CreditNote__c = creditNote.Id, blng__CreditNoteLineDate__c = System.today(), blng__Product__c = lineProduct.Id, blng__Subtotal__c = 100);
        insert creditNoteLine;

        Test.startTest();
        CreditNoteExtController con = new CreditNoteExtController(new ApexPages.StandardController(creditNote));
        con.onRecall();
        creditNote = [SELECT ApprovalStatus__c FROM blng__CreditNote__c WHERE Id = :creditNote.Id LIMIT 1];
        Test.stopTest();
        
        System.assertEquals('Recalled', creditNote.ApprovalStatus__c,'Credit Note Not Recalled');
    }
}