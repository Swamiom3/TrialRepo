/************************************************************************************************************************************
Author      :   Serge Kandukuri
Description :   This is test class for flow apex class - DebitNoteSelector
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION      DATE         AUTHOR              DETAIL
    1            09/08/2021   Serge Kandukuri     Test class for flow apex class - DebitNoteSelector
**************************************************************************************************************************************/
@IsTest
public class DebitNoteSelectorTest{
    private static DebitNoteSelector dnSelector = new DebitNoteSelector();
    @testSetup 
    static void createTestdata() {

        List<Account> accountsToTest = (List<Account>)TestingUtility.getRecords(new Map<String, Object>{'objName' => 'Account', 'numberOfRecords' => 1});
        Account accountToTest = accountsToTest.get(0);
        
        List<Building__c> buildingsToInsert=new List<Building__c>();
        buildingsToInsert.add(UtilBuilding.createBuilding(null, 'test@test.com', null, false));
        buildingsToInsert.get(0).Building_Id__c = 'ABC';
        buildingsToInsert.get(0).Country__c = 'Canada';
        insert buildingsToInsert;
        
        Building_Account__c buildingAccount = new Building_Account__c();
        buildingAccount.Billing_Account_Id__c = accountToTest.Id;
        buildingAccount.Building_Id__c = buildingsToInsert.get(0).Id;
        insert buildingAccount;

        // Invoice
        List<blng__Invoice__c> invs = new List<blng__Invoice__c>();
        invs.add(new blng__Invoice__c(blng__Account__c = accountToTest.Id,
                                      blng__InvoiceStatus__c = 'Posted',
                                      Invoice_Type__c = 'Standard',
                                      Building_Id__c = buildingsToInsert.get(0).Id,
                                      blng__InvoiceDate__c = system.today(),
                                      Temp_Number__c = 1,
                                      blng__DueDate__c = System.today().addDays(-5)));
        Database.insert(invs);

        blng__DebitNote__c debitNoteToTest = new blng__DebitNote__c();
        debitNoteToTest.blng__Account__c = accountToTest.Id;
        debitNoteToTest.blng__BillToAccount__c = accountToTest.Id;
        debitNoteToTest.blng__DebitNoteDate__c = system.today();
        debitNoteToTest.Invoice_Id__c = invs[0].Id;
        debitNoteToTest.Building_Id__c = buildingsToInsert.get(0).Id;
        debitNoteToTest.Building_Account_Id__c = buildingAccount.Id;
        debitNoteToTest.blng__Status__c = 'Draft';
        debitNoteToTest.Reason__c = 'Late Fee';
        Database.insert(debitNoteToTest);


        List<Product2> productList = TestingUtility.createAllWeWorkProducts(true);
        Product2 lineProduct = [Select id from Product2 where isActive = true LIMIT 1];

        blng__DebitNoteLine__c debitNoteLine = new blng__DebitNoteLine__c(blng__BillToAccount__c =accountToTest.Id, blng__DebitNote__c = debitNoteToTest.Id, blng__DebitNoteLineDate__c = System.today(), blng__Product__c = lineProduct.Id, blng__Subtotal__c = 100);
        insert debitNoteLine;
    }
    
    @isTest
    static void getDefaultFieldsTest(){
        Test.startTest();
        dnSelector.getDefaultFields();
        Test.stopTest();
        
        System.assertEquals(true,!dnSelector.defaultFields.isEmpty(),'Default Fields are Not Present.');
    }
   
    @isTest
    static void getLatestNonSRInvoiceTest(){
        Test.startTest();
        Set<String> buildingcode = new Set<String>{'ABC'};
        List<blng__DebitNote__c> latestBuildingNotes = dnSelector.getLatestDebitNotes(System.today().addDays(-2), System.today().addDays(+3),buildingcode);
        Test.stopTest();
        System.assertEquals(0, latestBuildingNotes.size(), 'Debit Note Found.');
    }
    
    
    @isTest
    static void getLatestDebitNotesTest(){
        Test.startTest();
        Set<Id> invoiceIdSet = new Set<Id>();
        List<blng__DebitNote__c> latestBuildingNotes = dnSelector.getLatestDebitNotes(invoiceIdSet);
        Test.stopTest();
        
        System.assertEquals(0, latestBuildingNotes.size(), 'Debit Note Not Found.');
    }

    @isTest
    static void getDebitNotesbyIdTest(){
        Test.startTest();
        Set<Id> debitNotes = new Set<Id>();
        for(blng__DebitNote__c dn: [Select Id from blng__DebitNote__c]){
            debitNotes.add(dn.Id);
        }

        List<blng__DebitNote__c> debiteNoteById = dnSelector.getDebitNotesbyId(debitNotes);
        System.assertEquals(1, debiteNoteById.size(), 'Debit Note Found.');
    }
}