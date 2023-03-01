/*********************************************************************************************************
    Author        :  Rohit Nimase
    Description   :  Test class for BuildingUtility
    Issue No.     :  ST-8836
    History       :
-----------------------------------------------------------------------------------------------------------
    VERSION        DATE            AUTHOR             DETAIL
    1              28-Sept-2021    Rohit Nimase       Optimize/Cleanup Setting Class Methods
**********************************************************************************************************/
@isTest
public class BuildingUtilityTest {

    @isTest
    private static void testBuildingUtilityAllMethods(){
        List<Building__c> testBuildings = getInsertedBuildings();
        insert testBuildings;
        Test.startTest();
        List<Building__c> buildings = BuildingUtility.getAllBuildings();
        System.assertEquals(4, buildings.size(), 'All buildings must be returned');
        
        buildings = BuildingUtility.getBuildingsByIds(new Set<Id>{testBuildings[0].Id,testBuildings[1].Id});
        System.assertEquals(2, buildings.size(), 'Buildings must be returned based on Ids passed to getBuildingsByIds method');
        
        Building__c buildingById = BuildingUtility.getBuildingById(testBuildings[3].Id);
        system.assert(buildingById != null, 'Building must be returned for ID passed to getBuildingById method');
        
        Building__c buildingByUUID = BuildingUtility.getBuildingByUUID('Building2');
        Test.stopTest();
        system.assert(buildingByUUID != null, 'Building must be returned for UUID passed to getBuildingByUUID method');
    }
    
    private static List<Building__c> getInsertedBuildings() {
        List<Building__c> testBuildings = new List<Building__c>();
        for(Integer i = 0; i < 4; i++) {
            testBuildings.add(new Building__c(
                Name = 'Test Building ' + i,
                uuid__c = 'Building'+i
            ));
        }
        return testBuildings;
    }
}