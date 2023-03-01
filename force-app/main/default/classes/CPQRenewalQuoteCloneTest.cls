@isTest
public class CPQRenewalQuoteCloneTest {
    @testSetup 
    static void setup(){
        OperatingHours operatingHour = new OperatingHours(Name = 'EDT: Standard 9AM - 5PM Weekday');
        insert operatingHour;
        
         Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        update standardPricebook;
        
        List<Product2> products = new List<Product2>();

        Product2 product = new Product2( Name = 'Physical Membership', IsActive = true, ProductCode= 'PHY', Product_UUID__c = UUIDHandler.generateVersion4());

        products.add(product);
        
        Product2 monthProduct = new Product2( Name = 'Month 1', IsActive = true, ProductCode= '1', Product_UUID__c = UUIDHandler.generateVersion4());
        products.add(monthProduct);

        Product2 allAccessProduct = new Product2( Name = 'All Access', IsActive = true, ProductCode= 'ALLAccess', Product_UUID__c = UUIDHandler.generateVersion4());

        products.add(allAccessProduct);
        
        insert products;
        
        List<PricebookEntry> pricebookEntries = new List<PricebookEntry>();
        PricebookEntry pricebookEntry = new PricebookEntry(
            Pricebook2Id = standardPricebook.Id,
            Product2Id = products.get(0).Id,
            UnitPrice = 1020,
            IsActive = true
        );
        pricebookEntries.add(pricebookEntry);
        
        PricebookEntry pricebookEntry2 = new PricebookEntry(
            Pricebook2Id = standardPricebook.Id,
            Product2Id = products.get(1).Id,
            UnitPrice = 1020,
            IsActive = true
        );
        pricebookEntries.add(pricebookEntry2);
        
        PricebookEntry pricebookEntry3 = new PricebookEntry(
            Pricebook2Id = standardPricebook.Id,
            Product2Id = products.get(2).Id,
            UnitPrice = 1020,
            IsActive = true
        );
        pricebookEntries.add(pricebookEntry3);

        insert pricebookEntries;
        
        List<Product2> monthlyProducts = new List<Product2>();
        for(integer i= 0;i<20;i++){
            Product2 product1 = new Product2();
            product1.Name = 'Month '+i;
            product1.IsActive = true;
            product1.ProductCode= string.valueof(i);
            product1.Product_UUID__c = UUIDHandler.generateVersion4();
            monthlyProducts.add(product1); 
        }
        insert monthlyProducts;
        
        List<SBQQ__ProductOption__c> productOptions = new List<SBQQ__ProductOption__c>();
        for(Integer i= 0 ;i<20;i++){
            SBQQ__ProductOption__c productOption = new SBQQ__ProductOption__c();
            productOption.SBQQ__Number__c = i;
            productOptions.add(productOption);
        }        
        insert productOptions;
        
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
        inventory.UUID__c = '1234';
        inventory.Building__c = building.Id;
        insert inventory;        
        
        List<SBQQ__Quote__c> quotes = new List<SBQQ__Quote__c>();
        SBQQ__Quote__c ammendQuote = new SBQQ__Quote__c();
        ammendQuote.Building_Id__c = building.Id;
        ammendQuote.SBQQ__Type__c = 'Amendment';
        ammendQuote.Subscription_Type__c = 'Commitment Term';
        quotes.add(ammendQuote);
        
        SBQQ__Quote__c renewalQuote = new SBQQ__Quote__c();
        renewalQuote.Building_Id__c = building.Id;
        renewalQuote.SBQQ__Type__c = 'Renewal';
        renewalQuote.Subscription_Type__c = 'Commitment Term';
        renewalQuote.SBQQ__PricebookId__c = standardPricebook.Id;
        quotes.add(renewalQuote);
        
        insert quotes;
        
        List<SBQQ__QuoteLine__c> parentQuoteLines = new List<SBQQ__QuoteLine__c>();
        SBQQ__QuoteLine__c quoteLine = new SBQQ__QuoteLine__c();
        quoteLine.SBQQ__Quote__c = ammendQuote.Id;
        quoteLine.SBQQ__Product__c = product.Id;
        quoteLine.Building_Id__c = building.Id;
        quoteLine.Inventory_Id__c = inventory.Id;
        quoteLine.SBQQ__StartDate__c = System.today();
        quoteLine.Commitment_Term__c = '1';
        quoteLine.SBQQ__Number__c = 1;
        quoteLine.New_Move_in_Date__c = System.today()+90;
        quoteLine.SBQQ__EndDate__c = System.today()+90;
        quoteLine.New_End_Date__c = System.today()+180;
        quoteLine.Segment_End_Date__c = System.today()+90;
        quoteLine.SBQQ__PricebookEntryId__c = pricebookEntries.get(0).Id;
        parentQuoteLines.add(quoteLine);
        
        SBQQ__QuoteLine__c quoteLine2 = new SBQQ__QuoteLine__c();
        quoteLine2.SBQQ__Quote__c = ammendQuote.Id;
        quoteLine2.SBQQ__Product__c = product.Id;
        quoteLine2.Building_Id__c = building.Id;
        quoteLine2.Inventory_Id__c = inventory.Id;
        quoteLine2.SBQQ__StartDate__c = System.today();
        quoteLine2.Commitment_Term__c = '1';
        quoteLine2.SBQQ__Number__c = 1;
        quoteLine2.New_Move_in_Date__c = System.today()+90;
        quoteLine2.SBQQ__EndDate__c = System.today()+90;
        quoteLine2.New_End_Date__c = System.today()-31;
        quoteLine2.Segment_End_Date__c = System.today()+90;
        quoteLine2.SBQQ__PricebookEntryId__c = pricebookEntries.get(1).Id;
        parentQuoteLines.add(quoteLine2);
        
        SBQQ__QuoteLine__c quoteLine3 = new SBQQ__QuoteLine__c();
        quoteLine3.SBQQ__Quote__c = ammendQuote.Id;
        quoteLine3.SBQQ__Product__c = allAccessProduct.Id;
        quoteLine3.Building_Id__c = building.Id;
        quoteLine3.SBQQ__StartDate__c = System.today();
        quoteLine3.Commitment_Term__c = '1';
        quoteLine3.SBQQ__Number__c = 1;
        quoteLine3.New_Move_in_Date__c = System.today()+90;
        quoteLine3.SBQQ__EndDate__c = System.today()+90;
        quoteLine3.New_End_Date__c = System.today()+94;
        quoteLine3.Segment_End_Date__c = System.today()+90;
        quoteLine3.SBQQ__PricebookEntryId__c = pricebookEntries.get(2).Id;
        parentQuoteLines.add(quoteLine3);
        
        insert parentQuoteLines;
        
        List<SBQQ__QuoteLine__c> childQuoteLines = new List<SBQQ__QuoteLine__c>();
        
        SBQQ__QuoteLine__c mthlyQuoteLine1 = new SBQQ__QuoteLine__c();
        mthlyQuoteLine1.SBQQ__Quote__c = ammendQuote.Id;
        mthlyQuoteLine1.SBQQ__Product__c = monthProduct.Id;
        mthlyQuoteLine1.Building_Id__c = building.Id;
        mthlyQuoteLine1.Inventory_Id__c = inventory.Id;
        mthlyQuoteLine1.SBQQ__StartDate__c = System.today();
        mthlyQuoteLine1.Commitment_Term__c = '1';
        mthlyQuoteLine1.SBQQ__Number__c = 1;
        mthlyQuoteLine1.SBQQ__PricebookEntryId__c = pricebookEntries.get(1).Id;
        mthlyQuoteLine1.SBQQ__RequiredBy__c = parentQuoteLines.get(0).Id;
        childQuoteLines.add(mthlyQuoteLine1);
        
        SBQQ__QuoteLine__c mthlyQuoteLine2 = new SBQQ__QuoteLine__c();
        mthlyQuoteLine2.SBQQ__Quote__c = ammendQuote.Id;
        mthlyQuoteLine2.SBQQ__Product__c = monthProduct.Id;
        mthlyQuoteLine2.Building_Id__c = building.Id;
        mthlyQuoteLine2.Inventory_Id__c = inventory.Id;
        mthlyQuoteLine2.SBQQ__StartDate__c = System.today();
        mthlyQuoteLine2.Commitment_Term__c = '1';
        mthlyQuoteLine2.SBQQ__Number__c = 1;
        mthlyQuoteLine2.SBQQ__PricebookEntryId__c = pricebookEntries.get(1).Id;
        mthlyQuoteLine2.SBQQ__RequiredBy__c = parentQuoteLines.get(1).Id;
        childQuoteLines.add(mthlyQuoteLine2);
        insert childQuoteLines;
    }
    
    @isTest 
    static void createRenewalQuoteLinesTestPositive(){
        Test.startTest();
        SBQQ__Quote__c renewalQuote =[SELECT Id FROM SBQQ__Quote__c WHERE SBQQ__Type__c ='Renewal'];
        List<String> selectedBundleLines = new List<String>();
        List<String> ammendQuoteIds = new List<String>();
        for(SBQQ__QuoteLine__c quoteLine :[SELECT Id,Inventory_Id__c,SBQQ__Quote__c FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__r.SBQQ__Type__c='Amendment']){
            selectedBundleLines.add(quoteLine.Id);
            ammendQuoteIds.add(quoteLine.SBQQ__Quote__c);
        }
        List<CPQRenewalQuoteClone.RenewalQuoteCloneWrapper> renwalQuoteCloneWrapperList= new List<CPQRenewalQuoteClone.RenewalQuoteCloneWrapper>();
        CPQRenewalQuoteClone.RenewalQuoteCloneWrapper renewalQuoteClone = new CPQRenewalQuoteClone.RenewalQuoteCloneWrapper();
        renewalQuoteClone.selectedBundleLines = selectedBundleLines;
        renewalQuoteClone.ammendQuoteIds = ammendQuoteIds;
        renewalQuoteClone.renewalQuoteId = renewalQuote.Id;
        renewalQuoteClone.action = 'Change Move in Date';
        renwalQuoteCloneWrapperList.add(renewalQuoteClone);
        
        List<CPQRenewalQuoteClone.CloneQuoteResponse> cloneQuoteResponses = new List<CPQRenewalQuoteClone.CloneQuoteResponse>();   
        
        cloneQuoteResponses = CPQRenewalQuoteClone.cloneQuoteWithQuoteLines(renwalQuoteCloneWrapperList);
        List<SBQQ__QuoteLine__c> clonedQuoteLines = [SELECT Id,SBQQ__Quote__c FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c =: renewalQuote.Id];
        System.assert(!clonedQuoteLines.isEmpty(), 'Quote lines are not create under renewal quote');
        Test.stopTest();
    }
    
     @isTest 
    static void craeteRenewalQuoteLinesAmmednTermTest(){
        Test.startTest();
        SBQQ__Quote__c renewalQuote =[SELECT Id FROM SBQQ__Quote__c WHERE SBQQ__Type__c ='Renewal'];
        
        List<String> selectedBundleLines = new List<String>();
        List<String> ammendQuoteIds = new List<String>();
        for(SBQQ__QuoteLine__c quoteLine :[SELECT Id,Inventory_Id__c,SBQQ__Quote__c FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__r.SBQQ__Type__c='Amendment']){
            selectedBundleLines.add(quoteLine.Id);
            ammendQuoteIds.add(quoteLine.SBQQ__Quote__c);
        }
        SBQQ__QuoteLine__c quoteLine = [SELECT Id, SBQQ__EffectiveEndDate__c,SBQQ__StartDate__c, Segment_End_Date__c, SBQQ__EndDate__c, New_End_Date__c, 
                                           Inventory_Id__c, SBQQ__EffectiveStartDate__c,CurrencyIsoCode 
                                           FROM SBQQ__QuoteLine__c  
                                           WHERE Id = :selectedBundleLines.get(0)];
        List<CPQRenewalQuoteClone.RenewalQuoteCloneWrapper> renwalQuoteCloneWrapperList= new List<CPQRenewalQuoteClone.RenewalQuoteCloneWrapper>();
        CPQRenewalQuoteClone.RenewalQuoteCloneWrapper renewalQuoteClone = new CPQRenewalQuoteClone.RenewalQuoteCloneWrapper();
        renewalQuoteClone.selectedBundleLines = selectedBundleLines;
        renewalQuoteClone.ammendQuoteIds = ammendQuoteIds;
        renewalQuoteClone.renewalQuoteId = renewalQuote.Id;
        renewalQuoteClone.action = 'Extend Term';
        renwalQuoteCloneWrapperList.add(renewalQuoteClone);
        
        List<CPQRenewalQuoteClone.CloneQuoteResponse> cloneQuoteResponses = new List<CPQRenewalQuoteClone.CloneQuoteResponse>();
        cloneQuoteResponses = CPQRenewalQuoteClone.cloneQuoteWithQuoteLines(renwalQuoteCloneWrapperList);
        List<SBQQ__QuoteLine__c> clonedQuoteLines = [SELECT Id,SBQQ__Quote__c FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c =: renewalQuote.Id];        
        Test.stopTest();
        System.assert(!clonedQuoteLines.isEmpty(), 'Quote lines are not create under renewal quote');
    }
    
    @isTest 
    static void createRenewalQuoteLinesTestNegative(){
        List<CPQRenewalQuoteClone.RenewalQuoteCloneWrapper> renwalQuoteCloneWrapperList= new List<CPQRenewalQuoteClone.RenewalQuoteCloneWrapper>();
        List<CPQRenewalQuoteClone.CloneQuoteResponse> cloneQuoteResponses = CPQRenewalQuoteClone.cloneQuoteWithQuoteLines(renwalQuoteCloneWrapperList);
        System.assert(cloneQuoteResponses == null, 'Ammend quote lines are returned');
    }
}