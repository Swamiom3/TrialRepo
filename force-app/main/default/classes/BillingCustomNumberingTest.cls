@IsTest
public class BillingCustomNumberingTest {

    @testSetup 
    static void createTestdata() {
        List<Account> accountsToTest = (List<Account>)TestingUtility.getRecords(new Map<String, Object>{'objName' => 'Account', 'numberOfRecords' => 1});
        Account accountToTest = accountsToTest.get(0);

        List<Building__c> buildingsToInsert=new List<Building__c>();
        buildingsToInsert.add(UtilBuilding.createBuilding(null, 'test@test.com', null, false));
        buildingsToInsert.add(UtilBuilding.createBuilding(null, 'test@test.com', null, false));
        buildingsToInsert.get(0).WeCode__c = 'ABC';
        buildingsToInsert.get(1).WeCode__c = 'XYZ';
        buildingsToInsert.get(0).Building_Id__c = 'ABC';
        buildingsToInsert.get(1).Building_Id__c = 'XYZ';
        buildingsToInsert.get(0).Country__c = 'Canada';
        buildingsToInsert.get(1).Country__c = 'Canada';
        insert buildingsToInsert;

        Building_Account__c ba = new Building_Account__c();
        ba.Building_Id__c = buildingsToInsert.get(0).Id;
        ba.Billing_Account_Id__c = accountsToTest.get(0).Id;
        ba.Name = 'TestBA';
        insert ba;

        List<blng__Invoice__c> invs = new List<blng__Invoice__c>();
        invs.add(new blng__Invoice__c(blng__Account__c = accountToTest.Id,
                                      blng__InvoiceStatus__c = 'Posted',
                                      Invoice_Type__c = 'Standard',
                                      Building_Id__c = buildingsToInsert.get(0).Id,
                                      blng__InvoiceDate__c = System.today(),
                                      Temp_Number__c = null,
                                      blng__DueDate__c = System.today().addDays(-5)));
        invs.add(new blng__Invoice__c(blng__Account__c = accountToTest.Id,
                                      blng__InvoiceStatus__c = 'Posted',
                                      Invoice_Type__c = 'Standard',
                                      blng__InvoiceDate__c = System.today(),
                                      Temp_Number__c = null,
                                      blng__DueDate__c = System.today().addDays(-2)));
        Database.insert(invs);
    }

    @isTest
    static void debitNoteNumberGenerateTestPositive() {
        
        Account accountToTest = [SELECT Id FROM Account LIMIT 1];
        blng__Invoice__c invoiceToTest = [SELECT Id, Name,Building_Id__c,Building_Short_Code__c,Temp_Number__c FROM blng__Invoice__c WHERE Building_Id__c != null LIMIT 1];
        Building_Account__c ba = [Select id from Building_Account__c LIMIT 1];

        Test.startTest();
        blng__DebitNote__c debitNoteToTest = new blng__DebitNote__c();
        debitNoteToTest.blng__Account__c = accountToTest.Id;
        debitNoteToTest.blng__BillToAccount__c = accountToTest.Id;
        debitNoteToTest.Building_Account_Id__c = ba.Id;
        debitNoteToTest.Building_Id__c = invoiceToTest.Building_Id__c;
        debitNoteToTest.blng__DebitNoteDate__c = System.today();
        debitNoteToTest.Invoice_Id__c = invoiceToTest.Id;
        debitNoteToTest.blng__DebitNoteSourceAction__c = 'Manual';
        debitNoteToTest.Temp_Number__c = null;
        debitNoteToTest.Reason__c = 'Late Fee';
        debitNoteToTest.blng__Status__c = 'Draft';
        Database.insert(debitNoteToTest);

        List<blng__DebitNote__c> debitNotes = new List<blng__DebitNote__c>();
        debitNotes.add(debitNoteToTest);
        List<List<SObject>> debitNoteListList= new List<List<SObject>>();
        debitNoteListList.add(debitNotes);
        List<String> customNum = BillingCustomNumbering.setNumbering(debitNoteListList);

        blng__DebitNote__c debitNoteToTest2 = new blng__DebitNote__c();
        debitNoteToTest2.blng__Account__c = accountToTest.Id;
        debitNoteToTest2.blng__BillToAccount__c = accountToTest.Id;
        debitNoteToTest2.Building_Account_Id__c = ba.Id;
        debitNoteToTest2.Building_Id__c = invoiceToTest.Building_Id__c;
        debitNoteToTest2.blng__DebitNoteDate__c = System.today();
        debitNoteToTest2.Invoice_Id__c = invoiceToTest.Id;
        debitNoteToTest2.blng__DebitNoteSourceAction__c = 'Manual';
        debitNoteToTest2.Temp_Number__c = null;
        debitNoteToTest2.Reason__c = 'Late Fee';
        debitNoteToTest2.blng__Status__c = 'Draft';
        Database.insert(debitNoteToTest2);

        debitNotes = new List<blng__DebitNote__c>();
        debitNotes.add(debitNoteToTest2);
        debitNoteListList= new List<List<SObject>>();
        debitNoteListList.add(debitNotes);
        customNum = BillingCustomNumbering.setNumbering(debitNoteListList);
        Test.stopTest();
        
        List<blng__DebitNote__c> debitNoteList = [SELECT Id,Temp_Number__c, Debit_Note_Number_Custom__c FROM blng__DebitNote__c LIMIT 1];
        System.assertNotEquals(0,debitNoteList[0].Temp_Number__c , 'Debit Note Number Not zero');
    }
   
    @isTest
    static void debitNoteNumberGenerateTestNegative() {
        
        Account accountToTest = [SELECT Id FROM Account LIMIT 1];
        blng__Invoice__c invoiceToTest = [SELECT Id, Name FROM blng__Invoice__c WHERE Building_Id__c = null LIMIT 1];
        
        Test.startTest();
        blng__DebitNote__c debitNoteToTest = new blng__DebitNote__c();
        debitNoteToTest.blng__Account__c = accountToTest.Id;
        debitNoteToTest.blng__DebitNoteDate__c = System.today();
        debitNoteToTest.Temp_Number__c = null;
        debitNoteToTest.Invoice_Id__c = invoiceToTest.Id;
        Database.insert(debitNoteToTest);
        Test.stopTest();
        
        List<blng__DebitNote__c> debitNoteList = [SELECT Id, Temp_Number__c, Debit_Note_Number_Custom__c FROM blng__DebitNote__c WHERE Temp_Number__c = null];
        System.assertEquals(1, debitNoteList.size(), 'Debit Note Number populated if building web code is blank');
        
    }
    @isTest
    static void creditNoteNumberGenerateTestPositive() {
        Account accountToTest = [SELECT Id FROM Account LIMIT 1];
        blng__Invoice__c invoiceToTest = [SELECT Id, Name,Building_Id__c,Building_Short_Code__c FROM blng__Invoice__c WHERE Building_Id__c != null LIMIT 1];

        blng__CreditNote__c creditNoteToTest = new blng__CreditNote__c();
        creditNoteToTest.blng__Account__c = accountToTest.Id;
        creditNoteToTest.blng__CreditNoteDate__c = System.today();
        creditNoteToTest.blng__RelatedInvoice__c = invoiceToTest.Id;
        creditNoteToTest.Reason__c = 'Accommodation';
        creditNoteToTest.Temp_Number__c = null;
        Database.insert(creditNoteToTest);

        Test.startTest();
        List<blng__CreditNote__c> creditNotes = new List<blng__CreditNote__c>();
        creditNotes.add(creditNoteToTest);
        List<List<SObject>> creditNoteListList= new List<List<SObject>>();
        creditNoteListList.add(creditNotes);
        List<String> customNum = BillingCustomNumbering.setNumbering(creditNoteListList);
        Test.stopTest();

        List<blng__CreditNote__c> creNoteRecords = [SELECT Id, Credit_Note_Number_Custom__c FROM blng__CreditNote__c WHERE Credit_Note_Number_Custom__c != null];
        System.assertEquals(1, creNoteRecords.size(),'Credit Note Number Not populated on Credit Note');
        
    }
   
    @isTest
    static void creditNoteNumberGenerateTestNegative() {
        Account accountToTest = [SELECT Id FROM Account LIMIT 1];
        blng__Invoice__c invoiceToTest = [SELECT Id, Name FROM blng__Invoice__c WHERE Building_Id__c = null LIMIT 1];

        blng__CreditNote__c creditNoteToTest = new blng__CreditNote__c();
        creditNoteToTest.blng__Account__c = accountToTest.Id;
        creditNoteToTest.blng__CreditNoteDate__c = System.today();
        creditNoteToTest.Temp_Number__c = null;
        creditNoteToTest.blng__RelatedInvoice__c = invoiceToTest.Id;
        Database.insert(creditNoteToTest);
        List<blng__CreditNote__c> creditNoteRecs = [SELECT Id,Temp_Number__c,Credit_Note_Number_Custom__c FROM blng__CreditNote__c WHERE Temp_Number__c = null];
        System.assertEquals(1, creditNoteRecs.size(), 'Credit Note Number populated if building web code is blank');
    }
    @isTest
    static void nonSRInvoiceNumberGenerateTestPositive() {
        Account invoiceAccount = [SELECT Id FROM Account LIMIT 1];
        
        Building__c invoiceBuilding = [SELECT Id, Name FROM Building__c LIMIT 1];
        invoiceBuilding.WeCode__c='1234';
        List<blng__Invoice__c> invs = new List<blng__Invoice__c>();
        invs.add(new blng__Invoice__c(blng__Account__c = invoiceAccount.Id,
                                      blng__InvoiceStatus__c = 'Posted',
                                      Invoice_Type__c = 'Standard',
                                      Building_Id__c = invoiceBuilding.Id,
                                      blng__InvoiceDate__c = System.today(),
                                      blng__DueDate__c = System.today().addDays(-5)));
        invs.add(new blng__Invoice__c(blng__Account__c = invoiceAccount.Id,
                                      blng__InvoiceStatus__c = 'Posted',
                                      Invoice_Type__c = 'Standard',
                                      blng__InvoiceDate__c = System.today(),
                                      Building_Id__c = invoiceBuilding.Id,
                                      blng__DueDate__c = System.today().addDays(-2)));
        Database.insert(invs);
        
        List<blng__Invoice__c> invoiceListToCheck = [SELECT Id,Temp_Number__c FROM blng__Invoice__c WHERE Invoice_Number_Custom__c != null AND Invoice_Type__c != 'Service Retainer'];
        System.assertEquals(3, invoiceListToCheck.size(), 'Invoice Number not populated on both Non SR Invoice');
        
        blng__DebitNote__c debitNoteToTest = new blng__DebitNote__c();
        debitNoteToTest.blng__Account__c = invoiceAccount.Id;
        debitNoteToTest.blng__DebitNoteDate__c = System.today();
        debitNoteToTest.Invoice_Id__c = invs[0].Id;
        debitNoteToTest.Temp_Number__c = null;
        Database.insert(debitNoteToTest);
        
        
        
        invoiceListToCheck = [SELECT Id , Temp_Number__c FROM blng__Invoice__c WHERE Invoice_Number_Custom__c != null];
        System.assertEquals(3, invoiceListToCheck.size(), 'Invoice Number not populated on all Non SR Invoice');
    }
    
    @isTest
    static void nonSRInvoiceNumberGenerateNextNumberTestPositive() {
        Account invoiceAccount = [SELECT Id FROM Account LIMIT 1];
        Building__c invoiceBuilding = [SELECT Id, Name FROM Building__c LIMIT 1];
        invoiceBuilding.WeCode__c='234';
        List<blng__Invoice__c> invs = new List<blng__Invoice__c>();
        invs.add(new blng__Invoice__c(blng__Account__c = invoiceAccount.Id,
                                      blng__InvoiceStatus__c = 'Posted',
                                      Invoice_Type__c = 'Standard',
                                      blng__InvoiceDate__c = System.today(),
                                      Building_Id__c = invoiceBuilding.Id,
                                      blng__DueDate__c = System.today().addDays(-5)));
        invs.add(new blng__Invoice__c(blng__Account__c = invoiceAccount.Id,
                                      blng__InvoiceStatus__c = 'Posted',
                                      blng__InvoiceDate__c = System.today(),
                                      Invoice_Type__c = 'Standard',
                                      Building_Id__c = invoiceBuilding.Id,
                                      blng__DueDate__c = System.today().addDays(-2)));
        Database.insert(invs);
        
        invs = new List<blng__Invoice__c>();
        invs.add(new blng__Invoice__c(blng__Account__c = invoiceAccount.Id,
                                      blng__InvoiceStatus__c = 'Posted',
                                      Invoice_Type__c = 'Standard',
                                      Building_Id__c = invoiceBuilding.Id,
                                      blng__InvoiceDate__c = System.today(),
                                      blng__DueDate__c = System.today().addDays(-5)));
        invs.add(new blng__Invoice__c(blng__Account__c = invoiceAccount.Id,
                                      blng__InvoiceStatus__c = 'Posted',
                                      Invoice_Type__c = 'Standard',
                                      blng__InvoiceDate__c = System.today(),
                                      Building_Id__c = invoiceBuilding.Id,
                                      blng__DueDate__c = System.today().addDays(-2)));
        Database.insert(invs);
        
        blng__DebitNote__c debitNoteToTest = new blng__DebitNote__c();
        debitNoteToTest.blng__Account__c = invoiceAccount.Id;
        debitNoteToTest.blng__DebitNoteDate__c = System.today();
        debitNoteToTest.Invoice_Id__c = invs[0].Id;
        debitNoteToTest.Temp_Number__c = null;
        Database.insert(debitNoteToTest);
        
        List<blng__Invoice__c> invoiceListToCheck = [SELECT Id,Temp_Number__c FROM blng__Invoice__c WHERE Invoice_Number_Custom__c != null AND Invoice_Type__c != :InvoiceConstants.SERVICE_RETAINER ];
        System.assertEquals(5, invoiceListToCheck.size(), 'Invoice Number not populated on all Non SR Invoice');
    }
    
    @isTest
    static void srInvoiceNumberGenerateTestPositive() {
        Account invoiceAccount = [SELECT Id FROM Account LIMIT 1];
        
        Building__c invoiceBuilding = [SELECT Id, Name FROM Building__c LIMIT 1];
        invoiceBuilding.WeCode__c='1234';
        List<blng__Invoice__c> invs = new List<blng__Invoice__c>();
        invs.add(new blng__Invoice__c(blng__Account__c = invoiceAccount.Id,
                                      blng__InvoiceStatus__c = 'Posted',
                                      Invoice_Type__c = 'Service Retainer',
                                      Building_Id__c = invoiceBuilding.Id,
                                      blng__InvoiceDate__c = System.today(),
                                      blng__DueDate__c = System.today().addDays(-5)));
        invs.add(new blng__Invoice__c(blng__Account__c = invoiceAccount.Id,
                                      blng__InvoiceStatus__c = 'Draft',
                                      Invoice_Type__c = 'Service Retainer',
                                      blng__InvoiceDate__c = System.today(),
                                      Building_Id__c = invoiceBuilding.Id,
                                      blng__DueDate__c = System.today().addDays(-2)));
        Database.insert(invs);
        
        blng__DebitNote__c debitNoteToTest = new blng__DebitNote__c();
        debitNoteToTest.blng__Account__c = invoiceAccount.Id;
        debitNoteToTest.blng__DebitNoteDate__c = System.today();
        debitNoteToTest.Invoice_Id__c = invs[0].Id;
        debitNoteToTest.Temp_Number__c = null;
        Database.insert(debitNoteToTest);
        
        List<blng__Invoice__c> invoiceListToCheck = [SELECT Id , Temp_Number__c FROM blng__Invoice__c WHERE Invoice_Number_Custom__c != null AND Invoice_Type__c != :InvoiceConstants.SERVICE_RETAINER];
        System.assertEquals(1, invoiceListToCheck.size(), 'Invoice Number not populated on both SR Invoice');
    }
    
    @isTest
    static void srInvoiceNumberGenerateNextNumberTestPositive() {
        Account invoiceAccount = [SELECT Id FROM Account LIMIT 1];
        
        Building__c invoiceBuilding = [SELECT Id, Name FROM Building__c LIMIT 1];
        invoiceBuilding.WeCode__c='2345';
        List<blng__Invoice__c> invs = new List<blng__Invoice__c>();
        invs.add(new blng__Invoice__c(blng__Account__c = invoiceAccount.Id,
                                      blng__InvoiceStatus__c = 'Draft',
                                      Invoice_Type__c = 'Service Retainer',
                                      Building_Id__c = invoiceBuilding.Id,
                                      blng__InvoiceDate__c = System.today(),
                                      blng__DueDate__c = System.today().addDays(-5)));
        invs.add(new blng__Invoice__c(blng__Account__c = invoiceAccount.Id,
                                      blng__InvoiceStatus__c = 'Draft',
                                      Invoice_Type__c = 'Service Retainer',
                                      Building_Id__c = invoiceBuilding.Id,
                                      blng__InvoiceDate__c = System.today(),
                                      blng__DueDate__c = System.today().addDays(-2)));
        Database.insert(invs);
       
        invs = new List<blng__Invoice__c>();
        invs.add(new blng__Invoice__c(blng__Account__c = invoiceAccount.Id,
                                      blng__InvoiceStatus__c = 'Draft',
                                      Invoice_Type__c = 'Service Retainer',
                                      Building_Id__c = invoiceBuilding.Id,
                                      blng__InvoiceDate__c = System.today(),
                                      blng__DueDate__c = System.today().addDays(-5)));
        invs.add(new blng__Invoice__c(blng__Account__c = invoiceAccount.Id,
                                      blng__InvoiceStatus__c = 'Draft',
                                      Invoice_Type__c = 'Service Retainer',
                                      Building_Id__c = invoiceBuilding.Id,
                                      blng__InvoiceDate__c = System.today(),
                                      blng__DueDate__c = System.today().addDays(-2)));
        Database.insert(invs);
        
        blng__DebitNote__c debitNoteToTest = new blng__DebitNote__c();
        debitNoteToTest.blng__Account__c = invoiceAccount.Id;
        debitNoteToTest.blng__DebitNoteDate__c = System.today();
        debitNoteToTest.Invoice_Id__c = invs[0].Id;
        debitNoteToTest.Temp_Number__c = 123;
        Database.insert(debitNoteToTest);
        
        List<blng__Invoice__c> invoiceListToCheck = [SELECT Id,Temp_Number__c FROM blng__Invoice__c WHERE Invoice_Number_Custom__c != null AND  Invoice_Type__c != :InvoiceConstants.SERVICE_RETAINER];
        System.assertEquals(1, invoiceListToCheck.size(), 'Invoice Number not populated on all SR Invoice');
    }
    
    @isTest
    static void invoiceNumberGenerateTestNegative() {
        Account invoiceAccount = [SELECT Id FROM Account LIMIT 1];
                
        List<blng__Invoice__c> invs = new List<blng__Invoice__c>();
        invs.add(new blng__Invoice__c(blng__Account__c = invoiceAccount.Id,
                                      blng__InvoiceStatus__c = 'Draft',
                                      Invoice_Type__c = 'Standard',
                                      blng__InvoiceDate__c = System.today(),
                                      blng__DueDate__c = System.today().addDays(-5)));
        invs.add(new blng__Invoice__c(blng__Account__c = invoiceAccount.Id,
                                      blng__InvoiceStatus__c = 'Draft',
                                      Invoice_Type__c = 'Standard',
                                      blng__InvoiceDate__c = System.today(),
                                      blng__DueDate__c = System.today().addDays(-2)));
        Database.insert(invs);

        List<blng__Invoice__c> invoiceListToCheck = [SELECT Id,Invoice_Number_Custom__c, Temp_Number__c FROM blng__Invoice__c WHERE Temp_Number__c = null and Building_Id__c = null];
        System.assertEquals(3, invoiceListToCheck.size(), 'Invoice Number populated if building we code is blank');
    }

    @isTest
    static void debiteNoteNumberIsZero() {
        
        Account accountToTest = [SELECT Id FROM Account LIMIT 1];
        blng__Invoice__c invoiceToTest = [SELECT Id, Name,Building_Id__c,Building_Short_Code__c, Temp_Number__c FROM blng__Invoice__c WHERE Building_Id__c != null LIMIT 1];

        Test.startTest();
        blng__DebitNote__c debitNoteToTest = new blng__DebitNote__c();
        debitNoteToTest.blng__Account__c = accountToTest.Id;
        debitNoteToTest.blng__DebitNoteDate__c = System.today();
        debitNoteToTest.Invoice_Id__c = invoiceToTest.Id;
        debitNoteToTest.Temp_Number__c = null;
        Database.insert(debitNoteToTest);
        Test.stopTest();
        
        List<blng__DebitNote__c> debitNoteList = [SELECT Id,Temp_Number__c, Debit_Note_Number_Custom__c FROM blng__DebitNote__c LIMIT 1];
        System.assertNotEquals(0,debitNoteList[0].Temp_Number__c , 'Debit Note Number Not zero');
    }

    @isTest
    static void debiteNoteAlreadyExists() {
        
        Account accountToTest = [SELECT Id FROM Account LIMIT 1];
        blng__Invoice__c invoiceToTest = [SELECT Id, Name,Building_Id__c,Building_Short_Code__c, Temp_Number__c FROM blng__Invoice__c WHERE Building_Id__r.WeCode__c = 'ABC' LIMIT 1];

        Test.startTest();
        blng__DebitNote__c debitNoteToTest = new blng__DebitNote__c();
        debitNoteToTest.blng__Account__c = accountToTest.Id;
        debitNoteToTest.blng__DebitNoteDate__c = System.today();
        debitNoteToTest.Invoice_Id__c = invoiceToTest.Id;
        debitNoteToTest.Temp_Number__c = 1;
        Database.insert(debitNoteToTest);

        blng__DebitNote__c debitNoteToTest2 = new blng__DebitNote__c();
        debitNoteToTest2.blng__Account__c = accountToTest.Id;
        debitNoteToTest2.blng__DebitNoteDate__c = System.today();
        debitNoteToTest2.Invoice_Id__c = invoiceToTest.Id;
        Database.insert(debitNoteToTest2);
        Test.stopTest();
        
        List<blng__DebitNote__c> debitNoteList = [SELECT Id,Temp_Number__c, Debit_Note_Number_Custom__c FROM blng__DebitNote__c];
        System.assertNotEquals(0,debitNoteList[0].Temp_Number__c , 'Debit Note Number Not zero');
    }

}