@isTest
public class BuildingHandlerTest {
    public static void test_getSpecificBuildings(List<Building__c> lstBuildings) {
        Set<String> setBuildingNames = new Set<String>{lstBuildings[0].name, lstBuildings[1].name};
        Set<String> setfetchedBulidingNames = new Set<String>();
        List<Building__c> fetchedBulidings = BuildingHandler.getSpecificBuildings(setBuildingNames);
        for(Building__c objBuilding : fetchedBulidings){
            setfetchedBulidingNames.add(objBuilding.Name);
        }
        System.assert(setfetchedBulidingNames.containsAll(setBuildingNames), 'Building Not found with this name');
    }
    
    public static void test_get_buildings_uuids_by_multipicklist(List<Building__c> lstBuildings) {
        List<String> lstResults = BuildingHandler.getUUIDsFromMultipicklistValues('B2;B1');
        Set<String> setBuildingNameResults = new Set<String>();
        setBuildingNameResults.addAll(lstResults);
        System.assertNotEquals(NULL, lstResults, 'existing buidlings must return a value');        
        System.assertEquals(2, lstResults.size(), 'elements in response are incorrect');
        system.assert(setBuildingNameResults.contains(BuildingTriggersTest.buildinguuid2) && setBuildingNameResults.contains(BuildingTriggersTest.buildinguuid1) , 'wrong uuids calculated');
    }
    
    public static void test_get_buildings_by_uuid(List<Building__c> lstBuldings) {
        String strResult = BuildingHandler.getMultipicklistValuesFromUUID(NULL);
        System.assertEquals(NULL, strResult, 'empty uuids should return null');        
        List<String> lstBuildingUUIDs = new List<String>{BuildingTriggersTest.buildinguuid1, BuildingTriggersTest.buildinguuid2};
        strResult = BuildingHandler.getMultipicklistValuesFromUUID(lstBuildingUUIDs);
        System.assertNotEquals(NULL, strResult, 'existing uuids must return a value');
        system.assert(strResult.contains('B1') && strResult.contains('B2') && strResult.contains(';'), 'result should contain buildings names separated by semi-colon');        
    }
    
     public static void update_get_building_uuid_By_Account(List<Building__c> lstBuldings, Map<String, Building__c> mapsObjectForUpdate, Map<String, Opportunity> mapOpportunity) {
        Opportunity objOpp = [SELECT Id, Name, AccountID, Primary_Member__c, StageName, CloseDate, Building__c, Actual_Start_Date__c  FROM Opportunity];
        objOpp.StageName = 'Closed Won';
        mapOpportunity.put(objOpp.StageName, objOpp);
    }
    
    public static void test_update_get_building_uuid_By_Account(List<Building__c> lstBuldings){
        Account objAccount = [SELECT Id FROM Account WHERE Name = 'Test Account'];
        String actual = BuildingHandler.getBuildingUUIDByAccount(objAccount.Id);
        system.assertEquals(lstBuldings[0].UUID__c, actual);
        system.assertEquals(NULL, BuildingHandler.getBuildingUUIDByAccount(NULL));
    }
    
    public static void test_get_building_id_by_uuid(List<Building__c> lstBuldings) {
        system.assertEquals(lstBuldings[0].Id, BuildingHandler.getBuildingIdByUUID(BuildingTriggersTest.buildinguuid1), 'The building should be selected with the provided uuid');
        system.assertEquals(NULL, BuildingHandler.getBuildingIdByUUID(''),'No building with the provided uuid');
    }
    
}