@isTest
private class CPQ_ApiDataModelsTest {

    @isTest static void testProductLoadContext() {
        Building__c building = new Building__c();
        building.Name = 'testbuild-001';
        building.Building_ID__c = 'test';
        building.UUID__c = 'test';
        building.Time_Zone__c ='America/Denver';
        building.CurrencyIsoCode = 'CAD';
        insert building;

        CPQ_ApiDataModels.ProductLoadContext loadContext = new CPQ_ApiDataModels.ProductLoadContext();
        System.assertEquals(loadContext.pricebookId, null);
        System.assertEquals(loadContext.currencyCode, null);

        Id pricebookId = Test.getStandardPricebookId();
        String currencyCode = 'CAD';
        
        Product2 product = new Product2( Name = 'Commitment Test',IsActive = true,ProductCode='COMMIT-TEST',Product_UUID__c = UUIDHandler.generateVersion4());
        insert product;
        
        SBQQ__Quote__c quote = new SBQQ__Quote__c();
        quote.Subscription_Type__c ='Commitment Term';
        quote.Building_Id__c = building.Id;
        quote.CurrencyIsoCode = 'CAD';
        insert quote;
        
        CPQ_ApiDataModels.QuoteReader reader = new CPQ_ApiDataModels.QuoteReader();
        CPQ_ApiDataModels.QuoteModel quoteModel = reader.read(quote.Id);    

        CPQ_ApiDataModels.ProductLoadContext loadContextWithPricebookAndCurrency = new CPQ_ApiDataModels.ProductLoadContext(pricebookId, currencyCode);
        System.assertEquals(loadContextWithPricebookAndCurrency.pricebookId, pricebookId);
        System.assertEquals(loadContextWithPricebookAndCurrency.currencyCode, currencyCode);
        
        CPQ_ApiDataModels.ProductReader productReader = new CPQ_ApiDataModels.ProductReader();
        productReader.Read(product.Id, pricebookId, currencyCode);
        CPQ_ApiDataModels.ProductReaderContext prodReaderContext = new CPQ_ApiDataModels.ProductReaderContext(pricebookId, currencyCode);
        
        CPQ_ApiDataModels.QuoteReader quoteReader = new CPQ_ApiDataModels.QuoteReader();
        quoteReader.Read(quote.Id);        
        List<CPQ_ApiDataModels.ProductModel> products = new List<CPQ_ApiDataModels.ProductModel>();       
        CPQ_ApiDataModels.ProductModel productBundleHeader = productReader.read(product.Id,quote.SBQQ__PricebookId__c ,quote.CurrencyIsoCode );
        products.add(productBundleHeader);       
        CPQ_ApiDataModels.ProductAdder adder = new CPQ_ApiDataModels.ProductAdder();
        CPQ_ApiDataModels.QuoteModel quoteWithProducts = adder.add(quoteModel, products, 0);
        CPQ_ApiDataModels.QuoteSaver saver = new CPQ_ApiDataModels.QuoteSaver();
        CPQ_ApiDataModels.QuoteModel savedQuote = saver.save(quoteWithProducts);        
        SBQQ__Quote__c quoteRecord = [SELECT Id, SBQQ__LineItemCount__c FROM SBQQ__Quote__c where Id =:quote.Id];
        System.assertEquals(quoteRecord.SBQQ__LineItemCount__c, 1);
    }
    
    @isTest static void testProductAddContext() {
        CPQ_ApiDataModels.ProductAddContext addContextDefault = new CPQ_ApiDataModels.ProductAddContext();
        System.assertEquals(addContextDefault.quote, null);
        System.assertEquals(addContextDefault.products, new List<CPQ_ApiDataModels.ProductModel>());
        System.assertEquals(addContextDefault.groupKey, null);

        CPQ_ApiDataModels.QuoteModel quote = new CPQ_ApiDataModels.QuoteModel();
        List<CPQ_ApiDataModels.ProductModel> products = new List<CPQ_ApiDataModels.ProductModel>();

        CPQ_ApiDataModels.ProductAddContext addContextquoteProducts = new CPQ_ApiDataModels.ProductAddContext(quote, products);
        System.assertEquals(addContextquoteProducts.quote, quote);
        System.assertEquals(addContextquoteProducts.products, products);
        System.assertEquals(addContextquoteProducts.groupKey, null);

        CPQ_ApiDataModels.ProductAddContext addContextquoteProductsIgnoreCalculate = new CPQ_ApiDataModels.ProductAddContext(true, quote, products);
        System.assertEquals(addContextquoteProductsIgnoreCalculate.quote, quote);
        System.assertEquals(addContextquoteProductsIgnoreCalculate.products, products);
        System.assertEquals(addContextquoteProductsIgnoreCalculate.groupKey, null);
        System.assertEquals(addContextquoteProductsIgnoreCalculate.ignoreCalculate, true);

        CPQ_ApiDataModels.ProductAddContext addContextquoteProductsIgnoreCalculateWithGroup =
            new CPQ_ApiDataModels.ProductAddContext(true, quote, products, 1);
        System.assertEquals(addContextquoteProductsIgnoreCalculateWithGroup.quote, quote);
        System.assertEquals(addContextquoteProductsIgnoreCalculateWithGroup.products, products);
        System.assertEquals(addContextquoteProductsIgnoreCalculateWithGroup.groupKey, 1);
        System.assertEquals(addContextquoteProductsIgnoreCalculateWithGroup.ignoreCalculate, true);
    }

    @isTest static void testCalculatorContext() {
        CPQ_ApiDataModels.CalculatorContext calcContext = new CPQ_ApiDataModels.CalculatorContext();
        System.assertEquals(calcContext.quote, null);

        CPQ_ApiDataModels.QuoteModel quote = new CPQ_ApiDataModels.QuoteModel();
        CPQ_ApiDataModels.CalculatorContext calcContextWithQuote = new CPQ_ApiDataModels.CalculatorContext(quote);
        System.assertEquals(calcContextWithQuote.quote, quote);
    }

    @isTest static void testProductModel() {
        String productModelJson = '{' +
          '"record": {' +
            '"attributes": {' +
              '"type": "Product2",' +
              '"url": "/services/data/v42.0/sobjects/Product2/01t0q000000gaO9AAI"' +
            '},' +
            '"Id": "01t0q000000gaO9AAI",' +
            '"CurrencyIsoCode": "CAD",' +
            '"Name": "API - Overage",' +
            '"ProductCode": "API - Overage",' +
            '"Description": "atg",' +
            '"SBQQ__SubscriptionPricing__c": "Fixed Price",' +
            '"SBQQ__PriceEditable__c": false,' +
            '"SBQQ__DefaultQuantity__c": 1.00000,' +
            '"SBQQ__QuantityEditable__c": true,' +
            '"SBQQ__CostEditable__c": false,' +
            '"SBQQ__NonDiscountable__c": false,' +
            '"SBQQ__NonPartnerDiscountable__c": false,' +
            '"SBQQ__SubscriptionTerm__c": 1,' +
            '"SBQQ__PricingMethod__c": "List",' +
            '"SBQQ__PricingMethodEditable__c": true,' +
            '"SBQQ__OptionSelectionMethod__c": "Click",' +
            '"SBQQ__Optional__c": false,' +
            '"SBQQ__Taxable__c": false,' +
            '"SBQQ__CustomConfigurationRequired__c": false,' +
            '"SBQQ__Hidden__c": false,' +
            '"SBQQ__ReconfigurationDisabled__c": false,' +
            '"SBQQ__ExcludeFromOpportunity__c": true,' +
            '"SBQQ__DescriptionLocked__c": false,' +
            '"SBQQ__ExcludeFromMaintenance__c": false,' +
            '"SBQQ__IncludeInMaintenance__c": false,' +
            '"SBQQ__AllocatePotOnOrders__c": false,' +
            '"SBQQ__NewQuoteGroup__c": false,' +
            '"SBQQ__SubscriptionType__c": "Renewable",' +
            '"SBQQ__HasConfigurationAttributes__c": false,' +
            '"SBQQ__ExternallyConfigurable__c": false,' +
            '"SBQQ__BillingFrequency__c": "Monthly",' +
            '"SBQQ__ChargeType__c": "Usage",' +
            '"PricebookEntries": {' +
              '"totalSize": 1,' +
              '"done": true,' +
              '"records": [' +
                '{' +
                  '"attributes": {' +
                    '"type": "PricebookEntry",' +
                    '"url": "/services/data/v42.0/sobjects/PricebookEntry/01u0q000001jwBjAAI"' +
                  '},' +
                  '"Product2Id": "01t0q000000gaO9AAI",' +
                  '"Id": "01u0q000001jwBjAAI",' +
                  '"Pricebook2Id": "01s0q000000CbjqAAC",' +
                  '"UnitPrice": 0.08,' +
                  '"IsActive": true,' +
                  '"CurrencyIsoCode": "CAD"' +
                '}' +
              ']' +
            '}' +
          '},' +
          '"options": [],' +
          '"features": [],' +
          '"featureCategoryLabels": {' +
            '"Reporting": "Reporting",' +
            '"Implementation": "Implementation",' +
            '"Software": "Software",' +
            '"Hardware": "Hardware"' +
          '},' +
          '"featureCategories": [],' +
          '"currencySymbol": "CAD",' +
          '"currencyCode": "CAD",' +
          '"constraints": [],' +
          '"configurationAttributes": []' +
        '}';

        CPQ_ApiDataModels.ProductModel productModel = (CPQ_ApiDataModels.ProductModel) JSON.deserialize(productModelJson, CPQ_ApiDataModels.ProductModel.class);
        System.assertEquals(productModel.record.Name, 'API - Overage');
        System.assertEquals(productModel.upgradedAssetId, null);
        System.assertEquals(productModel.currencySymbol, 'CAD');
        System.assertEquals(productModel.currencyCode, 'CAD');
        System.assertEquals(productModel.featureCategories, new String[]{});
        System.assertEquals(productModel.options, new CPQ_ApiDataModels.OptionModel[]{});
        System.assertEquals(productModel.features, new CPQ_ApiDataModels.FeatureModel[]{});
        System.assertEquals(productModel.configuration, null);
        System.assertEquals(productModel.configurationAttributes, new CPQ_ApiDataModels.ConfigAttributeModel[]{});
        System.assertEquals(productModel.inheritedConfigurationAttributes, null);
    }
}