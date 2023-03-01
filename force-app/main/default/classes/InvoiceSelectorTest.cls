/************************************************************************************************************************************
Author      :   Serge Kandukuri
Description :   This is test class for flow apex class - InvoiceSelector
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION      DATE         AUTHOR              DETAIL
    1            08/06/2021   Serge Kandukuri     Test class for flow apex class - InvoiceSelector
**************************************************************************************************************************************/
@isTest
public class InvoiceSelectorTest{
    public static InvoiceSelector invSelector = new InvoiceSelector();

    @testSetup 
    static void createTestdata() {

        SFBD__DunningMethod__c dm = new SFBD__DunningMethod__c(Name='Test Method 1 act');
        dm.Dunning_Move_in_Type__c = 'Standard';
        Database.insert(dm);

        List<Account> lstAccounts = (List<Account>)TestingUtility.getRecords(new Map<String, Object>{'objName' => 'Account', 'numberOfRecords' => 1});
        Account testAcc = lstAccounts.get(0);
        
        Building__c building0 = UtilBuilding.createBuilding(null, 'test@test.com', null, true);
        Building__c building1 = UtilBuilding.createBuilding(null, 'test@test.com', null, true);
        
        
        building0.Building_Id__c = 'ABC';
        update building0;
        
        building1.Building_Id__c = 'XYZ';
        update building1;
        
        // Invoice
        List<blng__Invoice__c> invs = new List<blng__Invoice__c>();
        invs.add(new blng__Invoice__c(blng__Account__c = testAcc.Id,
                                      blng__InvoiceStatus__c = 'Draft',
                                      Invoice_Type__c = 'Standard',
                                      Building_Id__c = building0.Id,
                                      blng__InvoiceDate__c = System.today(),
                                      Temp_Number__c = 1,
                                      blng__DueDate__c = System.today().addDays(-5)));
        invs.add(new blng__Invoice__c(blng__Account__c = testAcc.Id,
                                      blng__InvoiceStatus__c = 'Draft',
                                      Invoice_Type__c = 'Service Retainer',
                                      Building_Id__c = building1.Id,
                                      Temp_Number__c = 1,
                                      blng__InvoiceDate__c = system.today(),
                                      blng__DueDate__c = System.today().addDays(-2)));
        Database.insert(invs);

    }
    
    @isTest
    static void getDefaultFieldsTest(){
        invSelector.getDefaultFields();
        System.assertEquals(true,!invSelector.defaultFields.isEmpty(),'Default Fields are Not Present');
    }
    
    @isTest
    static void getLatestNonSRInvoiceTest(){
        
        Set<String> buildingcode = new Set<String>{'ABC'};
        List<blng__Invoice__c> nonSRInvoice = invSelector.getLatestNonSRInvoices(System.today().addDays(-2), System.today().addDays(+3),buildingcode);
        System.assertEquals(1,nonSRInvoice.size(), 'Did Not Find 1 non SR Invoice');
        
        Set<Id> invoiceIds = new Set<Id>();
        invoiceIds.add(nonSRInvoice[0].Id);
        List<blng__Invoice__c> invoiceList = invSelector.getInvoicesById(invoiceIds);
        System.assertEquals(1, invoiceList.size(), 'Invoice retrieved successfully based on Id.');
        
    }
    
    @isTest
    static void getLatestSRInvoiceTest(){
        Set<String> buildingcode = new Set<String>{'XYZ'};
        List<blng__Invoice__c> sRInvoice = invSelector.getLatestSRInvoices(System.today().addDays(-2), System.today().addDays(+3),buildingcode);
        System.assertEquals(1, sRInvoice.size(), 'Did Not Find 1 SR Invoice');
    }
    
    
}