/*************************************************************************************************************************************
Author      :   Salesforce
Description :   This class provides sufficient test coverage for ProductOptionSelector class
--------------------------------------------------------------------------------------------------------------------------------------
VERSION         DATE            AUTHOR              DETAIL
1               7/21/2021       Salesforce         Initial Deployment
**************************************************************************************************************************************/
@isTest
private class ProductOptionSelectorTest {
    private static ProductOptionSelector prodOptionSelector = new ProductOptionSelector();
   
   @testSetup 
   static void setup(){
        SBQQ__ProductOption__c productOption = new SBQQ__ProductOption__c();        
        productOption.SBQQ__Number__c =1;
        insert productOption;
    }
    @isTest
    static void getProductOptionByProductCodeTest(){ 
       List<String> productCodes = new List<String>{'01'};
       List<SBQQ__ProductOption__c> productOptions = prodOptionSelector.getProductOptionByProductCode(productCodes);
       System.assert(productOptions !=null, 'Product Options are not retrieved');
    }
    
    @isTest
    static void getProductOptionsBySBQQNumberTest(){
       List<SBQQ__ProductOption__c> productOptions = prodOptionSelector.getProductOptionsBySBQQNumber(2);
       System.assert(productOptions !=null, 'Product Options are not retrieved');
    }
    
    @isTest
    static void getProductOptionsNegativeTest(){
       List<SBQQ__ProductOption__c> productOptions = prodOptionSelector.getProductOptionsBySBQQNumber(0);
       System.assert(productOptions.isEmpty(), 'Product Options are retrieved');
       List<String> productCodes = new List<String>{'0'};
       List<SBQQ__ProductOption__c> productOptionsWithProductCodes = prodOptionSelector.getProductOptionByProductCode(productCodes);
       System.assert(productOptionsWithProductCodes.isEmpty(), 'Product Options are not retrieved');
    }
}