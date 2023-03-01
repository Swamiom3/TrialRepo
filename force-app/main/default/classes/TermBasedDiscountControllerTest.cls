@isTest
public class TermBasedDiscountControllerTest {
    @testSetup 
    static void setup() {
        OperatingHours operatingHour = new OperatingHours(Name = 'EDT: Standard 9AM - 5PM Weekday');
        insert operatingHour;
        
        Building__c building = new Building__c();
        building.Name = 'testbuild-001';
        building.Building_ID__c = 'test';
        building.UUID__c = 'test';
        building.Time_Zone__c ='America/Denver';
        insert building;
        
        Inventory__c inventory = new Inventory__c();
        inventory.Name = 'testinv';
        inventory.List_Price__c = 100;
        inventory.Type__c = 'Office';
        inventory.UUID__c = 'fad7cb7f-3e86-4428-8b22-d4578703d759';
        inventory.Building__c = building.Id;
        insert inventory;
        
        Product2 product = new Product2( Name = 'Month 1', IsActive = true, ProductCode= '1',Family ='Workspace', Product_UUID__c = 'Month 1');
        insert product;
        List<Product2> products = new List<Product2>();
        for(integer i= 0;i<10;i++){
            Product2 product1 = new Product2();
            product1.Name = 'Month '+i;
            product1.IsActive = true;
            product1.ProductCode= string.valueof(i);
            product1.Family ='Workspace';
            product1.Product_UUID__c = 'Month'+ i;
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
        
        SBQQ__Quote__c quote = new SBQQ__Quote__c();
        quote.Building_Id__c = building.Id;
        quote.SBQQ__PricebookId__c = standardPricebook.Id;
        insert quote;
        
        SBQQ__QuoteLine__c quoteLine1 = new SBQQ__QuoteLine__c();
        quoteLine1.SBQQ__Quote__c = quote.Id;
        quoteLine1.SBQQ__Product__c = product.Id;
        quoteLine1.Building_Id__c = building.Id;
        quoteLine1.Inventory_Id__c = inventory.Id;
        quoteLine1.SBQQ__StartDate__c = System.today();
        quoteLine1.Commitment_Term__c = '1';
        quoteLine1.SBQQ__Number__c = 1;
        insert quoteLine1;
        
        SBQQ__QuoteLine__c quoteLine2 = new SBQQ__QuoteLine__c();
        quoteLine2.SBQQ__Quote__c = quote.Id;
        quoteLine2.SBQQ__Product__c = product.Id;
        quoteLine2.Building_Id__c = building.Id;
        quoteLine2.Inventory_Id__c = inventory.Id;
        quoteLine2.SBQQ__StartDate__c = System.today();
        quoteLine2.Commitment_Term__c = '6';
        quoteLine2.SBQQ__Number__c = 1;
        quoteLine2.SBQQ__RequiredBy__c = quoteLine1.Id;
        insert quoteLine2;
        
        List<SBQQ__ProductOption__c> productOptions = new List<SBQQ__ProductOption__c>();
        for(Integer i= 0 ;i<10;i++){
            SBQQ__ProductOption__c productOption = new SBQQ__ProductOption__c();
            productOption.SBQQ__ConfiguredSKU__c = product.Id;
            productOption.SBQQ__Number__c = i;
            productOptions.add(productOption);
        }        
        insert productOptions;
        
        Promo_Code__c promocode = new Promo_Code__c();
        promocode.Name = 'test';
        promocode.Type__c = inventory.Type__c;
        promocode.Percent__c = 0.5;
        promocode.Duration__c = '6';
        promocode.Expiry_Date__c = date.today();
        insert promocode;
    }
    @isTest 
    static void checkQuoteData() {
        Test.startTest();
        SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        TermBasedDiscountController.getTermDiscountsWrapper(quote.Id);        
        Product2 product = [SELECT Id, ProductCode FROM Product2 LIMIT 1];
        product.ProductCode = 'M2M-WRKSPC';
        update product;
        DatabaseResult result = TermBasedDiscountController.getTermDiscountsWrapper(quote.Id);
        system.assert(result.success == true,'Quote data retrived successfully');        
        Test.stopTest();
    }

    @isTest 
    static void createQuoteLinesByCommitmentTermPositive() {
        Test.startTest();
        List<String> commitmentTermList = new List<String>();
        commitmentTermList.add('6');
        SBQQ__QuoteLine__c quoteLine = [SELECT Id,SBQQ__RequiredBy__c,SBQQ__Product__r.ProductCode,Inventory_Id__r.UUID__c,SBQQ__RequiredBy__r.SBQQ__ProductFamily__c,
                                       SBQQ__Quote__r.SBQQ__PricebookId__c,SBQQ__Quote__c,Inventory_Id__r.Name,Commitment_Term__c,
                                       SBQQ__StartDate__c,SBQQ__Number__c,Promo_Code_Id__r.Name FROM SBQQ__QuoteLine__c WHERE SBQQ__RequiredBy__c != null];
        Test.setMock(HttpCalloutMock.class, new CPQAddPromosAPIMock(quoteLine.Inventory_Id__r.UUID__c,'200'));
        List<TermDiscountWrapper> termDiscountWrapList = new List<TermDiscountWrapper>();
        TermCommitmentWrapper commitmentTermData = new TermCommitmentWrapper(commitmentTermList, quoteLine.Commitment_Term__c);
        TermDiscountWrapper termDiscountWrap = new TermDiscountWrapper('PHYS-MBRSHP', quoteLine.Inventory_Id__r.Name, commitmentTermData, quoteLine, false, false);
        termDiscountWrap.quoteLineId = quoteLine.SBQQ__RequiredBy__c;
        termDiscountWrapList.add(termDiscountWrap);
        
        String jsonString = JSON.serialize(termDiscountWrapList);
        
        DatabaseResult result = TermBasedDiscountController.addDiscount(jsonString);
        System.assert(result.success == true, 'QuoteLines created successfully');
        commitmentTermList = new  List<String>();
        commitmentTermList.add('10');
        quoteLine.Commitment_Term__c = '8';
        update quoteLine;
        Test.stopTest();
        SBQQ__QuoteLine__c quoteLine1 = [SELECT Id,SBQQ__RequiredBy__c,SBQQ__Product__r.ProductCode,Inventory_Id__r.UUID__c,
                                       SBQQ__Quote__r.SBQQ__PricebookId__c,SBQQ__Quote__c,Inventory_Id__r.Name,Commitment_Term__c,
                                       SBQQ__StartDate__c,SBQQ__Number__c,Promo_Code_Id__r.Name FROM SBQQ__QuoteLine__c WHERE SBQQ__RequiredBy__c != null];
         
        Test.setMock(HttpCalloutMock.class, new CPQAddPromosAPIMock(quoteLine1.Inventory_Id__r.UUID__c,'200'));
        List<TermDiscountWrapper> termDiscountWrapList1 = new List<TermDiscountWrapper>();
        TermCommitmentWrapper commitmentTermData1 = new TermCommitmentWrapper(commitmentTermList, quoteLine1.Commitment_Term__c);
        TermDiscountWrapper termDiscountWrap1 = new TermDiscountWrapper('PHYS-MBRSHP', quoteLine1.Inventory_Id__r.Name, commitmentTermData1, quoteLine1, false, false);
        termDiscountWrap1.quoteLineId = quoteLine1.SBQQ__RequiredBy__c;
        termDiscountWrapList1.add(termDiscountWrap);
        String jsonString1 = JSON.serialize(termDiscountWrapList1);        
        DatabaseResult updatedresult = TermBasedDiscountController.addDiscount(jsonString1);
        System.assert(updatedresult.success == true, 'QuoteLines are not created');        
    }
     @isTest 
     static void createQuoteLinesByCommitmentTermNegative() {
        Test.startTest();
        List<String> commitmentTermList = new List<String>();
        commitmentTermList.add('6');
        SBQQ__QuoteLine__c quoteLine = [SELECT Id,SBQQ__RequiredBy__c,SBQQ__Product__r.ProductCode,Inventory_Id__r.UUID__c,SBQQ__RequiredBy__r.SBQQ__ProductFamily__c,
                                       SBQQ__Quote__r.SBQQ__PricebookId__c,SBQQ__Quote__c,Inventory_Id__r.Name,Commitment_Term__c,SBQQ__Product__c,
                                       SBQQ__StartDate__c,SBQQ__Number__c,Promo_Code_Id__r.Name FROM SBQQ__QuoteLine__c WHERE SBQQ__RequiredBy__c != null];
        List<TermDiscountWrapper> termDiscountWrapList = new List<TermDiscountWrapper>();
        TermCommitmentWrapper commitmentTermData = new TermCommitmentWrapper(commitmentTermList, quoteLine.Commitment_Term__c);
        TermDiscountWrapper termDiscountWrap = new TermDiscountWrapper('PHYS-MBRSHP', quoteLine.Inventory_Id__r.Name, commitmentTermData, quoteLine, false, false);
         termDiscountWrap.quoteLineId = quoteLine.SBQQ__RequiredBy__c;
        termDiscountWrapList.add(termDiscountWrap);
        String jsonString = JSON.serialize(termDiscountWrapList);
        Test.setMock(HttpCalloutMock.class, new CPQAddPromosAPIMock(quoteLine.Inventory_Id__r.UUID__c,'200'));
        TermBasedDiscountController.addDiscount(jsonString);
        commitmentTermList = new List<String>();
        commitmentTermList.add('10');
        quoteLine.Commitment_Term__c = '4';
        update quoteLine;
        Test.stopTest();
        SBQQ__QuoteLine__c quoteLine1 = [SELECT Id,SBQQ__RequiredBy__c,SBQQ__Product__r.ProductCode,Inventory_Id__r.UUID__c,SBQQ__Product__c,
                                       SBQQ__Quote__r.SBQQ__PricebookId__c,SBQQ__Quote__c,Inventory_Id__r.Name,Commitment_Term__c,
                                       SBQQ__StartDate__c,SBQQ__Number__c,Promo_Code_Id__r.Name FROM SBQQ__QuoteLine__c WHERE SBQQ__RequiredBy__c != null];         
        Test.setMock(HttpCalloutMock.class, new CPQAddPromosAPIMock(quoteLine1.Inventory_Id__r.UUID__c,'200'));
        List<TermDiscountWrapper> termDiscountWrapList1 = new List<TermDiscountWrapper>();
        TermCommitmentWrapper commitmentTermData1 = new TermCommitmentWrapper(commitmentTermList, quoteLine1.Commitment_Term__c);
        TermDiscountWrapper termDiscountWrap1 = new TermDiscountWrapper('PHYS-MBRSHP', quoteLine1.Inventory_Id__r.Name, commitmentTermData1, quoteLine1, false, false);
         termDiscountWrap1.quoteLineId = quoteLine1.SBQQ__RequiredBy__c;
        termDiscountWrapList1.add(termDiscountWrap);
        String jsonString1 = JSON.serialize(termDiscountWrapList1);        
        DatabaseResult result = TermBasedDiscountController.addDiscount(jsonString1);
        System.assert(result.success == true, 'QuoteLines are not created');
        
    }

    @isTest 
     static void createQuoteLinesSetupFeeTest() {
        List<String> commitmentTermList = new List<String>();
        commitmentTermList.add('6');
        SBQQ__QuoteLine__c quoteLine = [SELECT Id,SBQQ__RequiredBy__c,SBQQ__Product__r.ProductCode,Inventory_Id__r.UUID__c,SBQQ__RequiredBy__r.SBQQ__ProductFamily__c,
                                       SBQQ__Quote__r.SBQQ__PricebookId__c,SBQQ__Quote__c,Inventory_Id__r.Name,Commitment_Term__c,SBQQ__Product__c,
                                       SBQQ__StartDate__c,SBQQ__Number__c,Promo_Code_Id__r.Name FROM SBQQ__QuoteLine__c WHERE SBQQ__RequiredBy__c != null];

        Product2 prod = [SELECT Id, Name FROM Product2 WHERE Id = :quoteLine.SBQQ__Product__c];
        prod.Name = 'Setup Fee';
        update prod;

        List<TermDiscountWrapper> termDiscountWrapList = new List<TermDiscountWrapper>();
        TermCommitmentWrapper commitmentTermData = new TermCommitmentWrapper(commitmentTermList, quoteLine.Commitment_Term__c);
        TermDiscountWrapper termDiscountWrap = new TermDiscountWrapper('PHYS-MBRSHP', quoteLine.Inventory_Id__r.Name, commitmentTermData, quoteLine, false, false);
        termDiscountWrap.quoteLineId = quoteLine.SBQQ__RequiredBy__c;
        termDiscountWrapList.add(termDiscountWrap);
        
        String jsonString = JSON.serialize(termDiscountWrapList);
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new CPQAddPromosAPIMock(quoteLine.Inventory_Id__r.UUID__c,'200'));
        DatabaseResult result = TermBasedDiscountController.addDiscount(jsonString);
        
        commitmentTermList = new List<String>();
        commitmentTermList.add('10');
        quoteLine.Commitment_Term__c = '4';
        update quoteLine;
        
        Test.stopTest();

        System.assert(result.success, 'QuoteLines are not created');
    }

    @isTest 
    static void checkQuoteDataCommitProduct() {
        SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        Product2 product = [SELECT Id, ProductCode, Family FROM Product2 LIMIT 1];
        product.ProductCode = CPQConstants.PRODUCTCODE_COMMIT;
        product.Family = CPQConstants.ALL_ACCESS;
        update product;

        Test.startTest();
        DatabaseResult result = TermBasedDiscountController.getTermDiscountsWrapper(quote.Id);
        Test.stopTest();

        System.assert(result.success, 'Quote data retrived successfully');
    }
}