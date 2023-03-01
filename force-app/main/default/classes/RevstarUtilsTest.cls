/************************************************************************************************************************************
    Author      :   Chandra Teja 
    Description :   This class contains the unit test logic for RevstarUtils class.
    History     :
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION     DATE                AUTHOR              DETAIL
    1           12 June 2020        Chandra Teja        Initial Developement
    2           12 Dec 2021         Pawel Biszczak      Improve test coverage
**************************************************************************************************************************************/
@isTest
public class RevstarUtilsTest {
    @TestSetup
    static void initData(){
        Test.startTest();
        revstarSetupHelper('From Manage/Book Tour');
        Test.stopTest();
    }
    @isTest
    static void testRevstarPriceUpdate(){
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponeGeneratorForRevstarAPI());
        List<OpportunityLineItem> lstOppLIToCallout= [SELECT Quantity, Opportunity.Opportunity_Creation_Source__c, Opportunity.Requirement_Quantity__c, 
                                                            Opportunity.Building_uuid__c, Opportunity.CurrencyIsoCode, 
                                                            Opportunity.Interested_in_Number_of_Desks__c, Product2Id, PricebookEntryId
                                                      FROM OpportunityLineItem];
        RevstarUtils.updateLineItemsWithRevstarPrice(lstOppLIToCallout);
        Test.stopTest();
        List<Opportunity> opps = [SELECT Id, CurrencyIsoCode FROM Opportunity];
        System.assertEquals('EUR', opps[0].CurrencyIsoCode);
    }

    @isTest
    static void shouldGetCalloutLimit(){
        Integer calloutLimitInBatch;

        Test.startTest();
            calloutLimitInBatch = RevstarUtils.getLimitFromSetting('Future_Callout_Limit', RevstarUtils.getExtendRevstarPriceMetadata());
        Test.stopTest();

        System.assertNotEquals(calloutLimitInBatch, null, 'Should get callout limit');
    }

    @isTest
    static void shouldGetFakeKey(){
        List<Building__c> buildings = getFakeBuildings();
        List<Opportunity> opportunities = getFakeOpportunities();
        opportunities[0].Building__c = buildings[0].Id;
        opportunities[0].Interested_in_Number_of_Desks__c = 5;
        String fakeKey;

        Test.startTest();
            fakeKey = RevstarUtils.getKeyForRevstarResult(opportunities[0]);
        Test.stopTest();

        System.assert(String.isNotBlank(fakeKey), 'Key should be retrieved');
    }

    static List<Building__c> getFakeBuildings() {
        Map<String, Object> recordsData = new Map<String, Object>();
        recordsData = new Map<String, Object>();
        recordsData.put('objectName', 'Building__c');
        recordsData.put('numberOfRecords', 1);
        return MockTestingUtility.getRecords(recordsData, true);
    }

    static List<Opportunity> getFakeOpportunities() {
        Map<String, Object> recordsData = new Map<String, Object>();
        recordsData = new Map<String, Object>();
        recordsData.put('objectName', 'Opportunity');
        recordsData.put('numberOfRecords', 1);
        return MockTestingUtility.getRecords(recordsData, true);
    }

    public static void revstarSetupHelper(String oppCreationSource){
        Map<String,Object> mapRecordMetadata = new Map<String, Object>();
        mapRecordMetadata.put('objName', 'Building__c');
        mapRecordMetadata.put('numberOfRecords', 1);
        mapRecordMetadata.put('doInsert', true);
        List<Building__c> lstBuildings = (List<Building__c>)TestingUtility.getRecords(mapRecordMetadata);
        mapRecordMetadata.clear();
        Map<String, List<Object>> mapFieldValues = new Map<String, List<Object>>();
        mapFieldValues.put('StageName', new List<Object>{'Selling'});
        mapFieldValues.put('CurrencyIsoCode', new List<Object>{'USD'});
        mapFieldValues.put('CloseDate', new List<Object>{system.today().addDays(3)});
        mapFieldValues.put('Opportunity_Creation_Source__c', new List<Object>{oppCreationSource});
        mapFieldValues.put('Interested_in_Number_of_Desks__c', new List<Object>{5});
        mapFieldValues.put('Building__c', new List<Object>{lstBuildings[0].Id});
        mapRecordMetadata.put('objName', 'Opportunity');
        mapRecordMetadata.put('numberOfRecords', 1);
        mapRecordMetadata.put('doInsert', true);
        mapRecordMetadata.put('mapFieldValues', mapFieldValues);
        List<Opportunity> lstOpps = (List<Opportunity>)TestingUtility.getRecords(mapRecordMetadata);
        mapRecordMetadata.clear();
        mapRecordMetadata.put('objName', 'Product2');
        mapRecordMetadata.put('numberOfRecords', 3);
        mapRecordMetadata.put('doInsert', true);
        TestingUtility.getRecords(mapRecordMetadata);
        Product2 objProduct = [SELECT Id, productcode FROM Product2 WHERE IsActive=true and productcode = :RevstarUtils.PRODUCT_CODE LIMIT 1];
        PricebookEntry objPriceBookEntry = [SELECT Id FROM PricebookEntry WHERE Product2Id =:objProduct.Id
                                            AND CurrencyIsoCode = 'USD' LIMIT 1];
        Test.setMock(HttpCalloutMock.class, new MockHttpResponeGeneratorForRevstarAPI());
        Insert new OpportunityLineItem(OpportunityId = lstOpps[0].Id, 
                                       Product2Id = objProduct.Id,
                                       PricebookEntryId = objPriceBookEntry.Id,
                                       Quantity = 5,
                                       UnitPrice = 2500);
    }
}