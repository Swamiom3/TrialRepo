/************************************************************************************************************************************
    Author 		:   Shubham Nandwana
    Description : 	This class contains test for OpportunityPriceService
    Issue No    :   TWSPG-5410
	----------------------------------------------------------------------------------------------------------------------------------
	VERSION		DATE				AUTHOR					DETAIL
    1			16 November 2021	Shubham Nandwana     	Initial Development	 
**************************************************************************************************************************************/
@isTest
public class OpportunityPriceServiceTest {
    
    @testSetup
    static void createData(){
        Product2 p1 = new product2(name='All Access',ProductCode='ca04dfa5-b8f4-4c80-b36e-f9547a23f654',
                                   Product_UUID__c ='TestUUID1');
        insert p1;
        Product2 p2 = new product2(name='All Access Dynamic',ProductCode='b067dd33-83b9-442d-96b5-6290cba60e14',
                                   Product_UUID__c ='TestUUID2');
        insert p2;        
        Id standardPbId = Test.getStandardPricebookId();
        insert new PricebookEntry(pricebook2id = standardPbId, product2id = p1.id,unitprice=11.0, isActive=true);
        insert new PricebookEntry(pricebook2id = standardPbId, product2id = p2.id,unitprice=21.0, isActive=true);
    }
    
	@isTest
    public static void getAllAccessPriceTest_positive(){
        Test.startTest();
        Set<String> productNames = new Set<String>{'All Access','All Access Dynamic'};
        Id standardPbId = Test.getStandardPricebookId();
        OpportunityPriceService priceService = new OpportunityPriceService();
        Map<String,OpportunityPriceService.PriceBookEntryDetails> productToCurrency = 
            priceService.getAllAccessPrice(productNames, new List<String>{standardPbId});
        List<PricebookEntry> priceBookEnteries = [SELECT Id,UnitPrice,ProductCode,Pricebook2id FROM PricebookEntry];
        String key0 = priceService.getProdPricebookCurrKey(priceBookEnteries.get(0).ProductCode,standardPbId);
        System.assertEquals(priceBookEnteries.get(0).UnitPrice,productToCurrency.get(key0).UnitPrice , 'Price is not returned correctly');
        String key1 = priceService.getProdPricebookCurrKey(priceBookEnteries.get(1).ProductCode,standardPbId);
        System.assertEquals(priceBookEnteries.get(1).UnitPrice,productToCurrency.get(key1).UnitPrice , 'Price is not returned correctly');
        Test.stopTest();
    }
    @isTest
    public static void getAllAccessPriceTest_negative(){
        Test.startTest();
        Set<String> productNames = new Set<String>{'WeWork'};
        Id standardPbId = Test.getStandardPricebookId();
        OpportunityPriceService priceService = new OpportunityPriceService();
        Map<String,OpportunityPriceService.PriceBookEntryDetails> productToCurrency = 
            priceService.getAllAccessPrice(productNames, new List<String>{standardPbId});
        System.assertEquals(true, productToCurrency.isEmpty(), 'No records should be returned for incorrect product');
        Test.stopTest();
    }
}