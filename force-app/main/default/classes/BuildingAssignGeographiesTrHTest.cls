/*********************************************************************************************************
    Author        :  Krishna Somwanshi
    Description   :  Test class for BuildingAssignGeographiesTrH
    Issue No.     :  ST-8736
    History       :
-----------------------------------------------------------------------------------------------------------
    VERSION        DATE            AUTHOR             DETAIL
    1          24-Aug-2021      Krishna Somwanshi     Refactor
**********************************************************************************************************/
@isTest
public class BuildingAssignGeographiesTrHTest {
    
    @isTest
    private static void buildingAssignGeographies(){
        List<Building__c> testBuildings = getBuildings();
        TestingUtility.insertListWithAssert(testBuildings);
        System.assertEquals(1, Limits.getQueueableJobs(), 'QueueInsertGeographyForBuilding queable job should be executed');
    }
    
    private static List<Building__c> getBuildings() {
        List<Building__c> testBuildings = new List<Building__c>();
        for(Integer i = 0; i < 4; i++) {
            testBuildings.add(new Building__c(
                Name = 'Test Building ' + i
            ));
        }        
        return testBuildings;
    }
    
}