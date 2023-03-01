@isTest
public class CPQTestUtils {
    public void setupCPQTestData() {
        Inventory__c inventory = new Inventory__c();
        inventory.Name = 'testinv';
        inventory.List_Price__c = 100;
        inventory.Type__c = 'Office';
        inventory.UUID__c = '3665lghjh27mnb';
        insert inventory;
        
        Product2 product = new Product2( Name = 'Month 1', IsActive = true, ProductCode= '1',Family ='Workspace',Product_UUID__c = UUIDHandler.generateVersion4());
        insert product;
        
        Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        update standardPricebook;
        
        Building__c building = new Building__c();
        building.Name = 'testbuild-001';
        building.Building_ID__c = 'test';
        building.UUID__c = 'test';
        building.Time_Zone__c ='America/Denver';
        insert building;
        
        SBQQ__Quote__c quote = new SBQQ__Quote__c();
        quote.Building_Id__c = building.Id;
        quote.SBQQ__PricebookId__c = standardPricebook.Id;
        insert quote;
        
        SBQQ__QuoteLine__c quoteLine1 = new SBQQ__QuoteLine__c();
        quoteLine1.SBQQ__Quote__c = quote.Id;
        quoteLine1.SBQQ__Product__c = product.Id;
        quoteLine1.Building_Id__c = building.Id;
        quoteLine1.SBQQ__StartDate__c = System.today();
        quoteLine1.Commitment_Term__c = '1';
        quoteLine1.SBQQ__Number__c = 1;
        insert quoteLine1;
    }

    public SObject mockSObject(SObject sObj, Map<String, Object> fieldValues) {
        String jsonString = JSON.serialize(sObj);
        Map<String,Object> dataMap = (Map<String,Object>)JSON.deserializeUntyped(jsonString);
        dataMap.putAll(fieldValues);
        jsonString = JSON.serialize(dataMap);
        return (SObject)JSON.deserialize(jsonString, SObject.class);
    }
}