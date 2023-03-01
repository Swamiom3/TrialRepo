/************************************************************************************************************************************
Author      :   Salesforce
Description :   This class have testmethods to cover CPQAddPromos class
----------------------------------------------------------------------------------------------------------------------------------
VERSION     DATE                AUTHOR                  DETAIL
1           26 AUG 2021         Salesforce            Initial Developement
**************************************************************************************************************************************/
@isTest
public class CPQAddPromosTest {
    @testSetup
    static void setup() {
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
        inventory.UUID__c = '3665lghjh27mnb';
        inventory.Building__c = building.Id;
        insert inventory;
        
        SBQQ__Quote__c quote = new SBQQ__Quote__c();
        quote.Building_Id__c = building.Id;
        insert quote;
        
        Product2 product = new Product2( Name = 'Physical', IsActive = true, ProductCode= '01', Product_UUID__c = UUIDHandler.generateVersion4());
        insert product;
        Product2 monthProduct = new Product2( Name = 'Month', IsActive = true, ProductCode= '02', Product_UUID__c = UUIDHandler.generateVersion4());
        insert monthProduct;
        
        Product2 allAcessProduct = new Product2( Name = 'All Access', IsActive = true, ProductCode= '01',Family='All Access', Product_UUID__c = UUIDHandler.generateVersion4());
        insert allAcessProduct;
        
        SBQQ__QuoteLine__c quoteLine1 = new SBQQ__QuoteLine__c();
        quoteLine1.SBQQ__Quote__c = quote.Id;
        quoteLine1.SBQQ__Product__c = monthProduct.Id;
        quoteLine1.Building_Id__c = building.Id;
        quoteLine1.Inventory_Id__c = inventory.Id;
        quoteLine1.SBQQ__StartDate__c = System.today();
        quoteLine1.Commitment_Term__c = '1';
        quoteLine1.SBQQ__Number__c = 1;
        insert quoteLine1;
        
        SBQQ__QuoteLine__c quoteLine = new SBQQ__QuoteLine__c();
        quoteLine.SBQQ__Quote__c = quote.Id;
        quoteLine.SBQQ__Product__c = product.Id;
        quoteLine.Building_Id__c = building.Id;
        quoteLine.Inventory_Id__c = inventory.Id;
        quoteLine.SBQQ__StartDate__c = System.today();
        quoteLine.Commitment_Term__c = '1';
        quoteLine.SBQQ__Number__c = 1;
        insert quoteLine;
        
        SBQQ__QuoteLine__c allAccessQuoteLine = new SBQQ__QuoteLine__c();
        allAccessQuoteLine.SBQQ__Quote__c = quote.Id;
        allAccessQuoteLine.SBQQ__Product__c = allAcessProduct.Id;
        allAccessQuoteLine.Building_Id__c = building.Id;
        allAccessQuoteLine.SBQQ__StartDate__c = System.today();
        allAccessQuoteLine.Commitment_Term__c = '1';
        allAccessQuoteLine.SBQQ__Number__c = 1;
        insert allAccessQuoteLine;

        Promo_Code__c promocode = new Promo_Code__c();
        promocode.Name = 'test';
        promocode.Type__c = inventory.Type__c;
        promocode.Percent__c = 0.5;
        promocode.Duration__c = '6';
        promocode.Expiry_Date__c = date.today();
        insert promocode;
    }
    
    @isTest
    static void addPrmosServiceTestPositive(){
        Test.startTest();
        SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        Inventory__c inventory = [SELECT Id, Name, UUID__c FROM Inventory__c LIMIT 1];        
        Test.setMock(HttpCalloutMock.class, new CPQAddPromosAPIMock(inventory.UUID__c,'200'));
        List<CPQAddPromosWrapper.ResponseWithInventory> response = CPQAddPromos.getPromos(quote.Id,'AddPromos');
        System.assert(!response.isEmpty(), 'Response not recieved from add promo service');
        System.assert(response[0].inventoryName == inventory.Name, 'response not recieved for different Inventory');
        Test.stopTest();
    }
    
    @isTest
    static void addPrmosServiceTestNegative(){
        Test.startTest();
        SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        Inventory__c inventory = [SELECT Id, Name, UUID__c FROM Inventory__c LIMIT 1];        
        Test.setMock(HttpCalloutMock.class, new CPQAddPromosAPIMock(inventory.UUID__c,'201'));
        List<CPQAddPromosWrapper.ResponseWithInventory> response = CPQAddPromos.getPromos(quote.Id,'AddPromos');
        System.assert(response[0].response==null, 'Response recieved from add promo service');
        Test.stopTest();
    }
    
    @isTest
    static void saveCurevesTest(){
        Test.startTest();
        SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        Inventory__c inventory = [SELECT Id, Name, UUID__c FROM Inventory__c LIMIT 1];
        Promo_Code__c promocode = [SELECT Id,Duration__c FROM Promo_Code__c LIMIT 1];        
        Test.setMock(HttpCalloutMock.class, new CPQAddPromosAPIMock(inventory.UUID__c,'200'));
        List<CPQAddPromosWrapper.ResponseWithInventory> response = CPQAddPromos.getPromos(quote.Id,'AddPromos');
        List<CPQAddPromosWrapper.CurveSelect> curveSelections = new List<CPQAddPromosWrapper.CurveSelect>();
        CPQAddPromosWrapper.CurveSelect curveSelect = new CPQAddPromosWrapper.CurveSelect();
        curveSelect.curvename ='curve1';
        curveSelect.uuid = inventory.UUID__c;
        curveSelections.add(curveSelect);
        List<CPQAddPromosWrapper.PromoSelect> promoSelections = new List<CPQAddPromosWrapper.PromoSelect>();       
        CPQAddPromos.savePromosAndCurves(quote.Id, JSON.serialize(response), JSON.serialize(curveSelections), JSON.serialize(promoSelections));
        SBQQ__QuoteLine__c quoteLine = [SELECT Id, SBQQ__PartnerDiscount__c from SBQQ__QuoteLine__c where SBQQ__Product__r.Name =:'Month'];
        System.assert(quoteLine.SBQQ__PartnerDiscount__c != null, 'Partner discount not updated with curve value');
        Test.stopTest();
    }
    
    @isTest
    static void savePromosTest(){
        Test.startTest();
        SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        Inventory__c inventory = [SELECT Id, Name, UUID__c FROM Inventory__c LIMIT 1];
        Promo_Code__c promocode = [SELECT Id,Duration__c FROM Promo_Code__c LIMIT 1];        
        Test.setMock(HttpCalloutMock.class, new CPQAddPromosAPIMock(inventory.UUID__c,'200'));
        List<CPQAddPromosWrapper.ResponseWithInventory> response = CPQAddPromos.getPromos(quote.Id,'AddPromos');
        List<CPQAddPromosWrapper.CurveSelect> curveSelections = new List<CPQAddPromosWrapper.CurveSelect>();        
        List<CPQAddPromosWrapper.PromoSelect> promoSelections = new List<CPQAddPromosWrapper.PromoSelect>();
        CPQAddPromosWrapper.PromoSelect promoSelect = new CPQAddPromosWrapper.PromoSelect();
        promoSelect.percent = '25';
        promoSelect.promoId = promocode.Id;
        promoSelect.uuid = inventory.UUID__c;
        promoSelect.duration ='2';
        promoSelections.add(promoSelect);
        
        CPQAddPromosWrapper.PromoSelect promoSelect1 = new CPQAddPromosWrapper.PromoSelect();
        promoSelect1.percent = '25';
        promoSelect1.promoId = promocode.Id;
        promoSelect1.uuid = 'All Access';
        promoSelect1.duration ='2';
        promoSelections.add(promoSelect1);
        
        CPQAddPromos.savePromosAndCurves(quote.Id, JSON.serialize(response), JSON.serialize(curveSelections), JSON.serialize(promoSelections));
        SBQQ__QuoteLine__c quoteLine = [SELECT Id, Promo_Code_Id__c, SBQQ__PartnerDiscount__c FROM SBQQ__QuoteLine__c LIMIT 1];
        System.assert(quoteLine.Promo_Code_Id__c != null, 'Partner discount not updated with promo Id');
        System.assert(quoteLine.SBQQ__PartnerDiscount__c != null, 'Partner discount not updated with promo value');
        Test.stopTest();
    }
}