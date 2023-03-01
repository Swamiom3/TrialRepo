/************************************************************************************************************************************
Author      :   Serge Kandukuri
Description :   This is test class for flow apex class - CreditNoteSelectorController
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION      DATE         AUTHOR              DETAIL
    1            09/08/2021   Serge Kandukuri     Test class for flow apex class - CreditNoteSelectorController
**************************************************************************************************************************************/
@IsTest
public class CreditNoteSelectorTest{
    private static CreditNoteSelector cnSelector = new CreditNoteSelector();
    @testSetup 
    static void createTestdata() {


        List<Account> listOfAccountToTest = (List<Account>)TestingUtility.getRecords(new Map<String, Object>{'objName' => 'Account', 'numberOfRecords' => 1});
        Account accountToTest = listOfAccountToTest.get(0);
        
        
        List<Building__c> buildingsToInsert=new List<Building__c>();
        buildingsToInsert.add(UtilBuilding.createBuilding(null, 'test@test.com', null, true));
        buildingsToInsert.get(0).Building_Id__c = 'ABC';
        upsert buildingsToInsert;
        
        // Invoice
        List<blng__Invoice__c> invs = new List<blng__Invoice__c>();
        invs.add(new blng__Invoice__c(blng__Account__c = accountToTest.Id,
                                      blng__InvoiceStatus__c = 'Initiated',
                                      Invoice_Type__c = 'Standard',
                                      Building_Id__c = buildingsToInsert.get(0).Id,
                                      blng__InvoiceDate__c = system.today(),
                                      Temp_Number__c = 1,
                                      blng__DueDate__c = System.today().addDays(-5)));
        Database.insert(invs);

        blng__CreditNote__c creditNoteToTest = new blng__CreditNote__c();
        creditNoteToTest.blng__Account__c = accountToTest.Id;
        creditNoteToTest.blng__CreditNoteDate__c = system.today();
        creditNoteToTest.blng__RelatedInvoice__c = invs[0].Id;
        Database.insert(creditNoteToTest);

        List<blng__Invoice__c> invoicesToPost = new List<blng__Invoice__c>([Select id, blng__InvoiceStatus__c from blng__Invoice__c]);
        for(blng__Invoice__c invoice:invoicesToPost){
            invoice.blng__InvoiceStatus__c = 'Posted';
        }
        update invoicesToPost;
    }
    
    @isTest
    static void getDefaultFieldsTest(){
        cnSelector.getDefaultFields();
        System.assertEquals(true,!cnSelector.defaultFields.isEmpty(),'Default Fields are Not Present');
    }
   
    @isTest
    static void getLatestNonSRInvoiceTest(){
        Set<String> buildingcode = new Set<String>{'ABC'};
        List<blng__CreditNote__c> latestBuildingNotes = cnSelector.getLatestCreditNotes(System.today().addDays(-2), System.today().addDays(+3),buildingcode);
        System.assertEquals(1, latestBuildingNotes.size(), 'Did Not Find Credit Note');
    }
}