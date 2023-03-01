/*************************************************************************************************************************************
Author      :   Salesforce
Description :   This class provides sufficient test coverage for ProductSelector class
--------------------------------------------------------------------------------------------------------------------------------------
VERSION         DATE            AUTHOR              DETAIL
1               7/21/2021       Salesforce         Initial Deployment
**************************************************************************************************************************************/
@isTest
private class ProductSelectorTest {
    private static ProductSelector productSelector = new ProductSelector();
    
    @isTest
    static void getProductsTest(){
        Product2 product = new Product2( Name = 'Commitment Test2', IsActive = true, ProductCode='COMMIT-TEST',Product_UUID__c = UUIDHandler.generateVersion4());
        insert product;
        Set<String> productCodes = new Set<String>();
        productCodes.add(product.ProductCode);
        List<Product2> products = productSelector.getProductByProductCode(productCodes);
        System.assert(products != null, 'Products are not retrieved');
        List<String> productNames = new List<String>{product.Name};
        List<Product2> productswithNames = productSelector.getProductWithSubscriptionsOrderByProductName(productNames);
        System.assert(productswithNames !=null, 'Products are not retrieved');
    }  
    
    @isTest
    static void getProductsTestNegative(){
        Set<String> productCodes = new Set<String>{'123'};
        List<String> productNames = new List<String>{'123'};
        List<Product2> products = productSelector.getProductByProductCode(productCodes);
        System.assert(products.isEmpty(), 'Products are retrieved');
        List<Product2> productswithNames = productSelector.getProductWithSubscriptionsOrderByProductName(productNames);
        System.assert(productswithNames.isEmpty(), 'Products are retrieved');
    }
}