@isTest
public with sharing class CPQAmendSingleContractTest {
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
            Time_Zone__c ='America/Denver',
            CurrencyIsoCode = 'CAD'
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

        List<Product2> products = new List<Product2>();
        Product2 product = new Product2(
            Name = 'Test Product',
            IsActive = true,
            ProductCode= 'CODE1',
            SBQQ__SubscriptionPricing__c = 'Fixed Price', 
            Product_UUID__c = UUIDHandler.generateVersion4()
        );
        products.add(product);
        for(integer i= 0;i<10;i++){
            Product2 product1 = new Product2();
            product1.Name = 'Month '+i;
            product1.IsActive = true;
            product1.ProductCode= string.valueof(i);
            product1.SBQQ__SubscriptionPricing__c = 'Fixed Price';
            product1.Product_UUID__c = 'Product '+i;
            products.add(product1); 
        }
        insert products;
        
        Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true,
            currencyIsoCode = 'CAD'
        );
        update standardPricebook;
        
        PricebookEntry pricebookEntry = new PricebookEntry(
            Pricebook2Id = standardPricebook.Id,
            Product2Id = products.get(0).Id,
            UnitPrice = 1020,
            IsActive = true
        );
        insert pricebookEntry;
        
        SBQQ__Quote__c quote = new SBQQ__Quote__c(
            Building_Id__c = building.Id,
            SBQQ__PricebookId__c = standardPricebook.Id,
            SBQQ__Account__c = account.Id,
            CurrencyIsoCode = 'CAD'
        );
        insert quote;
        
        SBQQ__QuoteLine__c quoteLine1 = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = quote.Id,
            SBQQ__Product__c = products.get(0).Id,
            Building_Id__c = building.Id,
            Inventory_Id__c = inventory.Id,
            SBQQ__StartDate__c = System.today(),
            Commitment_Term__c = '1',
            SBQQ__Number__c = 1
        );
        insert quoteLine1;
        
        List<SBQQ__ProductOption__c> productOptions = new List<SBQQ__ProductOption__c>();
        for(Integer i= 0 ;i<10;i++){
            SBQQ__ProductOption__c productOption = new SBQQ__ProductOption__c();
            productOption.SBQQ__Number__c = i;
            productOptions.add(productOption);
        }        
        insert productOptions;
        
        ServiceContract serviceContract = new ServiceContract(
            Name = 'Test Service Contract',
            AccountId = account.Id,
            SBQQSC__Quote__c = quote.Id,
            StartDate = System.Now().date() - 1,
            EndDate = System.Now().date() + 10,
            Pricebook2Id = standardPricebook.Id,
            SBQQSC__PreserveBundleStructureUponRenewals__c = true
        );
        insert serviceContract;
        
        ContractLineItem contractLineItem = new ContractLineItem(
            UnitPrice = 0,
            Quantity = 1,
            SBQQSC__Account__c = account.Id,
            StartDate = System.Now().date() - 1,
            EndDate = System.Now().date() + 10,
            ServiceContractId = serviceContract.Id,
            SBQQSC__QuoteLine__c = quoteLine1.Id,
            PricebookEntryId = pricebookEntry.Id
        );
        insert contractLineItem;
    }
    @isTest 
    static void testAmendQuote() {
        ServiceContract serviceContract = [SELECT Id FROM ServiceContract LIMIT 1];
        String contractId = serviceContract.Id;
        List<CPQAmendSingleContract.AmendRequest> serviceContractRequestIds = new List<CPQAmendSingleContract.AmendRequest>();
        CPQAmendSingleContract.AmendRequest request = new CPQAmendSingleContract.AmendRequest();
        request.quoteId = contractId;
        serviceContractRequestIds.add(request);
        
        Test.startTest();        
        List<CPQAmendSingleContract.AmendResponse> response = CPQAmendSingleContract.amendServiceContracts(serviceContractRequestIds);        
        Test.stopTest();
        System.assert(response[0].cpqQuote.SBQQ__Type__c=='Amendment', 'Service contract Amendment Incomplete');
    }
    @isTest 
    static void testNegativeAmendQuote() {
        ServiceContract serviceContract = [SELECT Id FROM ServiceContract LIMIT 1];
        String contractId = serviceContract.Id;
        List<CPQAmendSingleContract.AmendRequest> serviceContractRequestIds = new List<CPQAmendSingleContract.AmendRequest>();
        CPQAmendSingleContract.AmendRequest request = new CPQAmendSingleContract.AmendRequest();
        request.quoteId = contractId;
        serviceContractRequestIds.add(request);
        Test.startTest();
        List<CPQAmendSingleContract.AmendResponse> response = CPQAmendSingleContract.amendServiceContracts(serviceContractRequestIds);
        Test.stopTest();
        System.assert(response[0].cpqQuote.SBQQ__Status__c == 'Draft', 'Service contract Amendment has been completed');
    }    
}