@isTest()
public class UtilInventory {
    public static List<Inventory__c> createInventory(Integer numOfRecords, Id buildingId, Boolean doInsert) {
        List<Map<String,Object>> lstOfMapRecordValues = new List<Map<String,Object>>();
        for(Integer i = 1; i <= numOfRecords; i++){
            Map<String,Object> mapRecordsValues = new Map<String,Object>();
            mapRecordsValues.put('Building__c', buildingId);
            mapRecordsValues.put('Name', 'Residential Unit-' + Math.random()*10000);
            mapRecordsValues.put('List_Price__c', 50);
            mapRecordsValues.put('Type__c', 'Office');
            mapRecordsValues.put('UUID__c', 'inventory-0001-000' + i);
            lstOfMapRecordValues.add(mapRecordsValues);
        }
        return UtilGeneral.createTestRecords(Inventory__c.sobjectType, lstOfMapRecordValues, doInsert);
    }
}