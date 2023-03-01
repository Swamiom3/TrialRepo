@isTest
private class OIDT_XMLGenerateCtrlTest {
    @testSetup
    static void makeData() {
        OIDT_TestDataFactory.createTestRecords();
    }
    @isTest
    static void generateTaxCalculationReqTest() {
    
        SBQQ__Quote__c quote =[SELECT Id,Name,CurrencyIsoCode,SBQQ__BillingCity__c,SBQQ__BillingCountry__c,SBQQ__BillingName__c,Billing_Account__c,
                                        SBQQ__BillingPostalCode__c,Billing_Account__r.Member_Short_Code__c,SBQQ__Status__c,Billing_Account__r.name,SBQQ__BillingState__c,SBQQ__Account__r.name,SBQQ__Account__r.BillingCity,
                                        SBQQ__Account__r.BillingCountry,SBQQ__Account__r.BillingPostalCode,SBQQ__Account__r.BillingState,
                                        SBQQ__Account__r.shippingCity,SBQQ__Type__c,Building_Id__r.VAT_Id__c,SBQQ__Account__r.Member_Short_Code__c,Building_Id__r.Name,
                                        SBQQ__Account__r.shippingCountry,SBQQ__Account__r.shippingPostalCode,SBQQ__Account__r.shippingState,Building_Id__r.Legal_Entity_Id__r.blng__ZipPostalCode__c, Building_Id__r.Legal_Entity_Id__r.blng__City__c,
                                        Building_Id__r.Legal_Entity_Id__r.blng__State__c,Building_Id__r.Legal_Entity_id__r.External_Id__c ,Building_Id__r.Legal_Entity_Id__r.blng__Country__c  
                                FROM SBQQ__Quote__c 
                                LIMIT 1 ];
        List<SBQQ__QuoteLine__c> quotelineList = [SELECT Id,Name,SBQQ__NetTotal__c,SBQQ__Quantity__c,Capital_Improvements_Projects__c,SBQQ__Product__r.ProductCode
                                                  FROM SBQQ__QuoteLine__c];
        OIDT_ProductWrapper productWrapper = new OIDT_ProductWrapper();  
        productWrapper.recordId = quote.id;
        productWrapper.invNumber = quote.name;
        productWrapper.customerNum = quote.Billing_Account__r.Member_Short_Code__c;
        productWrapper.currencyCode = quote.CurrencyIsoCode;
        productWrapper.companyId = quote.Building_Id__r.Legal_Entity_id__r.External_Id__c;
        productWrapper.customerName = quote.SBQQ__Account__r.name;
        productWrapper.billToName = quote.Billing_Account__r.name;
        productWrapper.billToCountry = quote.SBQQ__Account__r.BillingCountry;
        productWrapper.billToCity = quote.SBQQ__Account__r.BillingCity;
        productWrapper.billToState = quote.SBQQ__Account__r.BillingState;
        productWrapper.billToPostcode = quote.SBQQ__Account__r.BillingPostalCode;
        productWrapper.shipToCountry = quote.SBQQ__Account__r.BillingCountry;
        productWrapper.shipToCity = quote.SBQQ__Account__r.BillingCity;
        productWrapper.shipToState = quote.SBQQ__Account__r.BillingState;
        productWrapper.shipToPostcode = quote.SBQQ__Account__r.BillingPostalCode;
        productWrapper.memShortCode = quote.SBQQ__Account__r.Member_Short_Code__c;
        productWrapper.shipFromState = quote.Building_Id__r.Legal_Entity_Id__r.blng__State__c;
        productWrapper.shipFromCity = quote.Building_Id__r.Legal_Entity_Id__r.blng__City__c;
        productWrapper.shipFromPostcode = quote.Building_Id__r.Legal_Entity_Id__r.blng__ZipPostalCode__c;
        productWrapper.shipFromCountry = quote.Building_Id__r.Legal_Entity_Id__r.blng__Country__c != null ? quote.Building_Id__r.Legal_Entity_Id__r.blng__Country__c:'US' ;
        productWrapper.sellerRegistration = quote.Building_Id__r.VAT_Id__c;
        productWrapper.ProductItems = new List<OIDT_ProductWrapper.ProductItemWrapper>();
        
        for(SBQQ__QuoteLine__c quoteline: quoteLineList){
            OIDT_ProductWrapper.ProductItemWrapper proditem=new OIDT_ProductWrapper.ProductItemWrapper();
            String quoteAutoNumber=quoteline.name; 
            proditem.lineNumber= String.Valueof(quoteAutoNumber.split('-')[1]);
            proditem.quantity = quoteline.SBQQ__Quantity__c; 
            proditem.grossAmount = quoteline.SBQQ__NetTotal__c;
            proditem.productCode = quoteline.SBQQ__Product__r.ProductCode;
            productWrapper.ProductItems.add(proditem); 
        }
        
        User_Settings__c us = new User_Settings__c();       
        us.User_Name__c = 'XldlV29yay1TRi1TU0lELVVBVA==';
        us.User_Password__c = 'V2V3b3JrLXNmLVNTSUQtdWF0JA==';
        us.Name = 'test';
        insert us;        
        System.assertNotEquals(us, null);
        String request=OIDT_XMLGenerateCtrl.generateTaxCalculationReq(productWrapper);
        System.assertEquals(String.isNotBlank(request),true,'Request generated with given inputs');
    }
 
     @isTest
    static void generateTaxCalculationRequestTest() {
        OIDT_ProductWrapper productWrapper = new OIDT_ProductWrapper();  
        String request=OIDT_XMLGenerateCtrl.generateTaxCalculationReq(productWrapper);
        System.assertEquals(String.isNotBlank(request),false,'Exception occured');
        System.assertEquals(OIDT_XMLGenerateCtrl.isExceptionOccured,true,'Exception occured');
    }
     @isTest
    static void taxCalcResTest() {
        OIDT_ProductWrapper productWrapper = new OIDT_ProductWrapper();  
		String responseXML=  new OIDT_TestDataFactory.MockHttpResponseGenerator().respBody;
    	Map<String,String> fieldMapping=OIDT_XMLGenerateCtrl.taxCalcRes(responseXML);
        System.assertEquals(fieldMapping.isEmpty(),false,'Tax calculation field mapping failed.');
	    System.assertEquals(fieldMapping.get('totalTax'),'-26.00','Tax calculation field mapping failed.');
    }
   
}