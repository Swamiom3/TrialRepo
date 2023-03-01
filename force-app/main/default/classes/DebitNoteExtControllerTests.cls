@isTest
private class DebitNoteExtControllerTests {
    @isTest
    static void testSubmit() {
        List<Account> listOfAccountToTest = (List<Account>)TestingUtility.getRecords(new Map<String, Object>{'objName' => 'Account', 'numberOfRecords' => 1});
        Account accountToTest = listOfAccountToTest.get(0);

        blng__DebitNote__c debitNote = new blng__DebitNote__c(blng__Account__c = accountToTest.Id, blng__DebitNoteDate__c = System.today());
        insert debitNote;
        
        List<Product2> productList = TestingUtility.createAllWeWorkProducts(true);
        Product2 lineProduct = [Select id from Product2 where isActive = true LIMIT 1];

        blng__DebitNoteLine__c debitNoteLine = new blng__DebitNoteLine__c(blng__DebitNote__c = debitNote.Id, blng__DebitNoteLineDate__c = System.today(), blng__Product__c = lineProduct.Id, blng__Subtotal__c = 100);
        insert debitNoteLine;

        Test.startTest();
        DebitNoteExtController con = new DebitNoteExtController(new ApexPages.StandardController(debitNote));
        con.onSubmit();
        debitNote = [SELECT ApprovalStatus__c FROM blng__DebitNote__c WHERE Id = :debitNote.Id LIMIT 1];
        Test.stopTest();
        
        System.assertEquals('Approved', debitNote.ApprovalStatus__c,'Debit Note Not Approved');
    }

    @isTest
    static void testRecall() {
        List<Account> listOfAccountToTest = (List<Account>)TestingUtility.getRecords(new Map<String, Object>{'objName' => 'Account', 'numberOfRecords' => 1});
        Account accountToTest = listOfAccountToTest.get(0);
        
        blng__DebitNote__c debitNote = new blng__DebitNote__c(blng__Account__c = accountToTest.Id, blng__DebitNoteDate__c = System.today());
        insert debitNote;
        
        List<Product2> productList = TestingUtility.createAllWeWorkProducts(true);
        Product2 lineProduct = [Select id from Product2 where isActive = true LIMIT 1];

        blng__DebitNoteLine__c debitNoteLine = new blng__DebitNoteLine__c(blng__DebitNote__c = debitNote.Id, blng__DebitNoteLineDate__c = System.today(), blng__Product__c = lineProduct.Id, blng__Subtotal__c = 100);
        insert debitNoteLine;

        Test.startTest();
        DebitNoteExtController con = new DebitNoteExtController(new ApexPages.StandardController(debitNote));
        con.onRecall();
        debitNote = [SELECT ApprovalStatus__c FROM blng__DebitNote__c WHERE Id = :debitNote.Id LIMIT 1];
        Test.stopTest();
        
        System.assertEquals('Recalled', debitNote.ApprovalStatus__c,'Debit Note Not Recalled');
    }
}