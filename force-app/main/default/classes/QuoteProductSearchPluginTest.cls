@isTest
public class QuoteProductSearchPluginTest {
    @testSetup
    static void setup() {
        OperatingHours operatingHour = new OperatingHours(
            Name = 'EDT: Standard 9AM - 5PM Weekday'
        );
        insert operatingHour;
        
        Building__c building = new Building__c(
            Name = 'testbuild-001',
            Building_ID__c = 'test234',
            UUID__c = 'test234',
            Time_Zone__c ='America/Denver'
         );
        insert building;
        
        Inventory__c inventory = new Inventory__c(
            Name = 'testinv',
            List_Price__c = 100, Type__c = 'Office',
            UUID__c = 'gfty789hgfd',
            Building__c = building.Id
        );
        insert inventory;
        
        Account account = new Account(
            Name = 'Test Account'
        );
        insert account;
        
        Product2 product = new Product2(
            Name = 'Test Product', IsActive = true,
            ProductCode= 'CODE1', Product_UUID__c = 'Product1',
            SBQQ__SubscriptionPricing__c = 'Fixed Price'
        );
        insert product;

        List<Product2> products = new List<Product2>();
        for(integer i= 0;i<10;i++){
            Product2 product1 = new Product2();
            product1.Name = 'Month '+i;
            product1.IsActive = true;
            product1.ProductCode= string.valueof(i);
            product1.SBQQ__SubscriptionPricing__c = 'Fixed Price';
            product1.Product_UUID__c = 'Product - '+i;
            products.add(product1); 
        }
        insert products;
        
        Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        update standardPricebook;
        
        PricebookEntry pricebookEntry = new PricebookEntry(
            Pricebook2Id = standardPricebook.Id,
            Product2Id = product.Id,
            UnitPrice = 1020,
            IsActive = true
        );
        insert pricebookEntry;
        
        SBQQ__Quote__c quote = new SBQQ__Quote__c(
            Building_Id__c = building.Id,
            SBQQ__PricebookId__c = standardPricebook.Id,
            SBQQ__Account__c = account.Id
        );
        insert quote;
        
        SBQQ__QuoteLine__c quoteLine1 = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = quote.Id,
            SBQQ__Product__c = product.Id,
            Building_Id__c = building.Id,
            Inventory_Id__c = inventory.Id,
            SBQQ__StartDate__c = System.today(),
            Commitment_Term__c = '1',
            SBQQ__Number__c = 1
        );
        insert quoteLine1;
        
        SBQQ__QuoteLine__c quoteLine2 = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = quote.Id,
            SBQQ__Product__c = product.Id,
            Building_Id__c = building.Id,
            Inventory_Id__c = inventory.Id,
            SBQQ__StartDate__c = System.today(),
            Commitment_Term__c = '6',
            SBQQ__Number__c = 1,
            SBQQ__RequiredBy__c = quoteLine1.Id
        );        
        insert quoteLine2;
        
        List<SBQQ__ProductOption__c> productOptions = new List<SBQQ__ProductOption__c>();
        for(Integer i= 0 ;i<10;i++){
            SBQQ__ProductOption__c productOption = new SBQQ__ProductOption__c();
            productOption.SBQQ__Number__c = i;
            productOptions.add(productOption);
        }        
        insert productOptions;
    }
    @isTest 
    static void testProductSearchPlugin() {
        Test.startTest();
        SBQQ__Quote__c quote = [SELECT Id, Building_Id__c, SBQQ__PricebookId__c FROM SBQQ__Quote__c LIMIT 1];
        Building__c building = [SELECT Id, Building_ID__c, UUID__c FROM Building__c LIMIT 1];
        Set<Id> ids = new Set<Id>();
        ids.add(quote.Id);
        QuoteProductSearchPlugin quoteProductSearchPlugin = new QuoteProductSearchPlugin();
        quoteProductSearchPlugin.getFilterDefaultValue(quote, '');
        quoteProductSearchPlugin.isFilterHidden(quote, '');
        quoteProductSearchPlugin.isInputHidden(quote, '');
        quoteProductSearchPlugin.isSearchCustom(quote, new Map<String,Object>());              
        quoteProductSearchPlugin.isSuggestCustom(quote, new Map<String,Object>());
        quoteProductSearchPlugin.suggest(quote, new Map<String,Object>());
        quoteProductSearchPlugin.getInputDefaultValue(quote, '');
        Test.setMock(HttpCalloutMock.class, new RestAPIMock(building.UUID__c,'200'));
        String serchFilter = quoteProductSearchPlugin.getAdditionalSearchFilters(quote, new Map<String,Object>());        
        quoteProductSearchPlugin.getAdditionalSuggestFilters(quote, new Map<String,Object>());
        quoteProductSearchPlugin.search(quote, new Map<String,Object>());
        quoteProductSearchPlugin.inClausify(ids);
        System.assert(serchFilter !=null, 'Search filters not retrieved');
        Test.stopTest();
    }
    @isTest 
    static void testProductSearchPluginNegative() {
        Test.startTest();
        SBQQ__Quote__c quote = [SELECT Id, Building_Id__c, SBQQ__PricebookId__c FROM SBQQ__Quote__c LIMIT 1];
        Building__c building = [SELECT Id, Building_ID__c, UUID__c FROM Building__c LIMIT 1];
        Set<Id> ids = new Set<Id>();
        ids.add(quote.Id);
        QuoteProductSearchPlugin quoteProductSearchPlugin = new QuoteProductSearchPlugin();
        quoteProductSearchPlugin.getFilterDefaultValue(quote, '');
        quoteProductSearchPlugin.isFilterHidden(quote, '');
        quoteProductSearchPlugin.isInputHidden(quote, '');
        quoteProductSearchPlugin.isSearchCustom(quote, new Map<String,Object>());              
        quoteProductSearchPlugin.isSuggestCustom(quote, new Map<String,Object>());
        quoteProductSearchPlugin.suggest(quote, new Map<String,Object>());
        quoteProductSearchPlugin.getInputDefaultValue(quote, '');
        Test.setMock(HttpCalloutMock.class, new RestAPIMock(building.UUID__c,'201'));
        String additionalFileter = quoteProductSearchPlugin.getAdditionalSearchFilters(quote, new Map<String,Object>());
        quoteProductSearchPlugin.getAdditionalSuggestFilters(quote, new Map<String,Object>());
        quoteProductSearchPlugin.search(quote, new Map<String,Object>());
        quoteProductSearchPlugin.inClausify(ids);
        System.assert(additionalFileter == null, 'Search filters not retrieved');        
        Test.stopTest();
    }
}