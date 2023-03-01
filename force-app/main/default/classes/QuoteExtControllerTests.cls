@isTest
private class QuoteExtControllerTests {
    @isTest
    static void testSubmit() {
        Building__c building = new Building__c();
        building.Name = 'testbuild-001';
        building.Building_ID__c = 'test';
        building.UUID__c = 'test';
        building.Time_Zone__c ='America/Denver';
        building.CurrencyIsoCode = 'CAD';
        insert building;
        
        Opportunity opportunity = new Opportunity();
        opportunity.Name = 'Test Opp';
        opportunity.StageName = 'Closing';
        opportunity.CloseDate = System.today();
        insert opportunity;
        
        Account account = new Account(
            Name = 'Test Account 99'
        );
        insert account;
        
        SBQQ__Quote__c quote = new SBQQ__Quote__c();
        quote.Building_Id__c = building.Id;
        quote.CurrencyIsoCode = 'CAD';
        quote.Billing_Account__c = account.Id;
        quote.SBQQ__Opportunity2__c = opportunity.Id;
        insert quote;
        
        Test.startTest();
        QuoteExtController con = new QuoteExtController(new ApexPages.StandardController(quote));
        con.cancel();  
        con.onPreview();
        con.onContinue();
        con.onContinueSubmit();
        quote = [SELECT Id, ApprovalStatus__c FROM SBQQ__Quote__c WHERE Id = :quote.Id LIMIT 1];
        Test.stopTest();
        
        System.assertEquals('Approved', quote.ApprovalStatus__c,'Quote Not Approved');
    }
    @isTest
    static void testRecall() {
        Building__c building = new Building__c();
        building.Name = 'testbuildd-001';
        building.Building_ID__c = 'test';
        building.UUID__c = 'test';
        building.Time_Zone__c ='America/Denver';
        building.CurrencyIsoCode = 'CAD';
        insert building;
        
        Account account = new Account(
            Name = 'Test Account 99'
        );
        insert account;
        
        SBQQ__Quote__c quote = new SBQQ__Quote__c();
        quote.Building_Id__c = building.Id;
        quote.Billing_Account__c = account.Id;
        quote.CurrencyIsoCode = 'CAD';
        insert quote;
        
        Test.startTest();
        QuoteExtController con = new QuoteExtController(new ApexPages.StandardController(quote));
        con.onRecall();
        quote = [SELECT ApprovalStatus__c FROM SBQQ__Quote__c WHERE Id = :quote.Id LIMIT 1];
        Test.stopTest();
        
        System.assertEquals('Recalled', quote.ApprovalStatus__c,'Quote Not Recalled');
    }
    @isTest
    static void testCommitmentTermValidation(){
        Building__c building = new Building__c();
        building.Name = 'testbuildd-001';
        building.Building_ID__c = 'test';
        building.UUID__c = 'test';
        building.Time_Zone__c ='America/Denver';
        building.CurrencyIsoCode = 'CAD';
        insert building;
        
        Account account = new Account(
            Name = 'Test Account 99'
        );
        insert account;
        
        SBQQ__Quote__c quote = new SBQQ__Quote__c();
        quote.Building_Id__c = building.Id;
        quote.Billing_Account__c = account.Id;
        quote.CurrencyIsoCode = 'CAD';
        insert quote;
        
        Product2 product = new Product2( Name = 'Physical Membership', IsActive = true, ProductCode= '1', Product_UUID__c = UUIDHandler.generateVersion4());
        insert product;
        
        Inventory__c inventory = new Inventory__c();
        inventory.Name = 'testinv';
        inventory.List_Price__c = 100;
        inventory.Type__c = 'Office';
        inventory.UUID__c = '1234';
        inventory.Building__c = building.Id;
        insert inventory;
        
        SBQQ__QuoteLine__c quoteLine = new SBQQ__QuoteLine__c();
        quoteLine.SBQQ__Quote__c = quote.Id;
        quoteLine.SBQQ__Product__c = product.Id;
        quoteLine.Building_Id__c = building.Id;
        quoteLine.Inventory_Id__c = inventory.Id;
        quoteLine.SBQQ__StartDate__c = System.today();
        quoteLine.SBQQ__Number__c = 1;
        quoteLine.New_Move_in_Date__c = System.today()+90;
        quoteLine.SBQQ__EndDate__c = System.today()+90;
        quoteLine.New_End_Date__c = System.today()+180;
        insert quoteLine;
        
        Test.startTest();
        QuoteExtController con = new QuoteExtController(new ApexPages.StandardController(quote));
        con.onSubmit();
        quote = [SELECT ApprovalStatus__c FROM SBQQ__Quote__c WHERE Id = :quote.Id LIMIT 1];
        Test.stopTest();        
        System.assertEquals(null, quote.ApprovalStatus__c,'Quote Approved');
    }
    @isTest
    static void testServiceContractValidation(){
        Test.startTest();
        Building__c building = new Building__c();
        building.Name = 'testbuildd-001';
        building.Building_ID__c = 'test';
        building.UUID__c = 'test';
        building.Time_Zone__c ='America/Denver';
        building.CurrencyIsoCode = 'CAD';
        insert building;
        
        Product2 product = new Product2( Name = 'Physical Membership', IsActive = true, ProductCode= '1', Product_UUID__c = UUIDHandler.generateVersion4());
        insert product;
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
        
        ServiceContract serviceContract = new ServiceContract();
        serviceContract.Name ='Test';
        serviceContract.Pricebook2Id = standardPricebook.Id;
        insert serviceContract;
        
        Account account = new Account(
            Name = 'Test Account 99'
        );
        insert account;
        
        SBQQ__Quote__c quote = new SBQQ__Quote__c();
        quote.Building_Id__c = building.Id;
        quote.Billing_Account__c = account.Id;
        quote.CurrencyIsoCode = 'CAD';
        quote.SBQQSC__MasterServiceContract__c = serviceContract.Id;
        insert quote;
        
        Product2 addOnproduct = new Product2( Name = 'addOn', IsActive = true, ProductCode= '1',Family='addons', Product_UUID__c = UUIDHandler.generateVersion4());
        insert addOnproduct;
        
        Inventory__c inventory = new Inventory__c();
        inventory.Name = 'testinv';
        inventory.List_Price__c = 100;
        inventory.Type__c = 'Office';
        inventory.UUID__c = '1234';
        inventory.Building__c = building.Id;
        insert inventory;
        
        Inventory__c addOninventory = new Inventory__c();
        addOninventory.Name = 'testAddonInv';
        addOninventory.List_Price__c = 100;
        addOninventory.Type__c = 'Office';
        addOninventory.UUID__c = '12345';
        addOninventory.Building__c = building.Id;
        insert addOninventory;
        
        Inventory__c serviceItemInventory = new Inventory__c();
        serviceItemInventory.Name = 'testSrvInv';
        serviceItemInventory.List_Price__c = 100;
        serviceItemInventory.Type__c = 'Office';
        serviceItemInventory.UUID__c = '123456';
        serviceItemInventory.Building__c = building.Id;
        insert serviceItemInventory;
        
        SBQQ__QuoteLine__c quoteLine = new SBQQ__QuoteLine__c();
        quoteLine.SBQQ__Quote__c = quote.Id;
        quoteLine.SBQQ__Product__c = product.Id;
        quoteLine.Building_Id__c = building.Id;
        quoteLine.Inventory_Id__c = inventory.Id;
        quoteLine.Commitment_Term__c = '1';
        quoteLine.SBQQ__StartDate__c = System.today();
        quoteLine.SBQQ__Number__c = 1;
        quoteLine.New_Move_in_Date__c = System.today()+90;
        quoteLine.SBQQ__EndDate__c = System.today()+90;
        quoteLine.New_End_Date__c = System.today()+180;
        insert quoteLine;
        
        SBQQ__QuoteLine__c addOnquoteLine = new SBQQ__QuoteLine__c();
        addOnquoteLine.SBQQ__Quote__c = quote.Id;
        addOnquoteLine.SBQQ__Product__c = addOnproduct.Id;
        addOnquoteLine.Building_Id__c = building.Id;
        addOnquoteLine.Inventory_Id__c = addOninventory.Id;
        addOnquoteLine.SBQQ__StartDate__c = System.today();
        addOnquoteLine.SBQQ__Number__c = 1;
        addOnquoteLine.New_Move_in_Date__c = System.today()+90;
        addOnquoteLine.SBQQ__EndDate__c = System.today()+90;
        addOnquoteLine.New_End_Date__c = System.today()+180;
        insert addOnquoteLine; 
        
        ContractLineItem item = new ContractLineItem();
        item.ServiceContractId = serviceContract.Id;
        item.Inventory_Id__c = addOninventory.Id;
        item.Quantity =1;
        item.PricebookEntryId = pricebookEntry.Id;
        item.UnitPrice=100;
        insert item;        
        
        QuoteExtController con = new QuoteExtController(new ApexPages.StandardController(quote));        
        con.onSubmit();
        quote = [SELECT Id, ApprovalStatus__c FROM SBQQ__Quote__c WHERE Id = :quote.Id LIMIT 1];
        quote.ApprovalStatus__c = 'Approved';
        update quote;
        Test.stopTest();
        System.assertEquals('Approved', quote.ApprovalStatus__c,'Quote Not Approved');        
    }
    @isTest
    static void testSubmitNegative() {
        Building__c building = new Building__c();
        building.Name = 'testbuild-001';
        building.Building_ID__c = 'test';
        building.UUID__c = 'test';
        building.Time_Zone__c ='America/Denver';
        building.CurrencyIsoCode = 'CAD';
        insert building;
        
        Opportunity opportunity = new Opportunity();
        opportunity.Name = 'Test Opp';
        opportunity.StageName = 'Selling';
        opportunity.CloseDate = System.today();
        insert opportunity;
        
        Account account = new Account(
            Name = 'Test Account 99'
        );
        insert account;
        
        SBQQ__Quote__c quote = new SBQQ__Quote__c();
        quote.Building_Id__c = building.Id;
        quote.CurrencyIsoCode = 'CAD';
        quote.SBQQ__Opportunity2__c = opportunity.Id;
        insert quote;
        
        Test.startTest();
        QuoteExtController con = new QuoteExtController(new ApexPages.StandardController(quote));
        con.onPreview();
        quote.Billing_Account__c = account.Id;
        update quote;
        PageReference reference = con.onPreview();
        quote = [SELECT Id, ApprovalStatus__c FROM SBQQ__Quote__c WHERE Id = :quote.Id LIMIT 1];
        Test.stopTest();
        
        System.assertEquals(null, quote.ApprovalStatus__c,'Quote Approved');
        System.assertEquals(null, reference, 'Should get null as PageReference as it is not satisfying all the conditions');        
    }
}