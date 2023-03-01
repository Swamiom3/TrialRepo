@isTest
public class CPQQuoteLineNumberServiceTest {
    private static CPQTestUtils util = new CPQTestUtils();
    
    @testSetup
    private static void testSetup() {
        util.setupCPQTestData();
    }
    
    @isTest
    private static void testUpdateQLNumber() {
        Product2 prod = [SELECT Id, ProductCode FROM Product2 LIMIT 1];
        prod.ProductCode = 'Month-1';
        update prod;
        
        SBQQ__QuoteLine__c line = [SELECT Id, SBQQ__Quote__c, SBQQ__Product__c, Building_Id__c, SBQQ__StartDate__c, Commitment_Term__c, SBQQ__Number__c, 
                                   SBQQ__RequiredBy__c, SBQQ__ProductFamily__c, SBQQ__Product__r.Name, Inventory_Id__r.UUID__c FROM SBQQ__QuoteLine__c LIMIT 1];
        SBQQ__QuoteLine__c childLine = line.clone(false, true, false, false);
        childLine.SBQQ__RequiredBy__c = line.Id;
        insert childLine;
        
        Test.startTest();
        CPQQuoteLineNumberService service = new CPQQuoteLineNumberService(new List<SBQQ__QuoteLine__c>{line, childLine}, new Map<String,Decimal>());
        Test.stopTest();
        
        System.assert(!service.quoteLinesWithSBQQNumber.isEmpty());
    }
    
    @isTest
    private static void testUpdateQLNumberAddOns() {
        Product2 prod = [SELECT Id, Family FROM Product2 LIMIT 1];
        prod.Family = CPQConstants.ADDONS_PRODUCTFAMILY;
        update prod;
        
        SBQQ__QuoteLine__c line = [SELECT Id, SBQQ__Product__r.Name, SBQQ__ProductFamily__c, SBQQ__RequiredBy__c FROM SBQQ__QuoteLine__c LIMIT 1];
        
        Test.startTest();
        CPQQuoteLineNumberService service = new CPQQuoteLineNumberService(new List<SBQQ__QuoteLine__c>{line}, new Map<String,Decimal>());
        Test.stopTest();
        
        System.assert(!service.quoteLinesWithSBQQNumber.isEmpty());
    }
    
    @isTest
    private static void testUpdateQLNumberNullValues() {
        CPQQuoteLineNumberService service = new CPQQuoteLineNumberService(new List<SBQQ__QuoteLine__c>(), new Map<String,Decimal>());
        Boolean excepCaused = false;
        
        Test.startTest();
        try {
            service.updateQuoteLinesNumber(null, null);
        } catch(Exception e) {
            excepCaused = true;
        }
        Test.stopTest();
        
        System.assert(excepCaused, 'Failed to test null values');
    }
    
    @isTest
    private static void testUpdateQLNumberEmptyValues() {
        CPQQuoteLineNumberService service = new CPQQuoteLineNumberService(new List<SBQQ__QuoteLine__c>(), new Map<String,Decimal>());
        Boolean excepCaused = false;
        
        Test.startTest();
        List<SBQQ__QuoteLine__c> quoteLinesWithSBQQNumber = service.updateQuoteLinesNumber(new List<SBQQ__QuoteLine__c>(), new Map<String,Decimal>());
        Test.stopTest();
        
        System.assert(quoteLinesWithSBQQNumber.isEmpty());
    }
}