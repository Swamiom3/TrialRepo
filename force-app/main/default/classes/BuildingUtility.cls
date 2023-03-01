/*********************************************************************************************************
    Author        :  Rohit Nimase
    Description   :  Contains Building methods to get data.
    Issue No.     :  ST-8836
    History       :
-----------------------------------------------------------------------------------------------------------
    VERSION        DATE            AUTHOR             DETAIL
    1              24-Sept-2021    Rohit Nimase       Optimize/Cleanup Setting Class Methods
**********************************************************************************************************/
public class BuildingUtility {

    @TestVisible
    private static BuildingSelector buildingSelector = new BuildingSelector();
    public static List<Building__c> buildings;
    public static Map<Id, Building__c> idToBuilding = new Map<Id, Building__c>();
    public static Map<String, Building__c> uuidToBuilding = new Map<String, Building__c>();

    public static void fetchBuildings() {
        if (buildings?.isEmpty() == false) {
            return ;
        }
        buildings = buildingSelector.getBuildingsWithoutFiltersHugeSetOfFields();
        for(Building__c currentBuilding : buildings){
            idToBuilding.put(currentBuilding.Id, currentBuilding);
            uuidToBuilding.put(currentBuilding.UUID__c, currentBuilding);
        }
    }

    public static List<Building__c> getBuildingsByIds(Set<Id> setOfBuildingIds){
        fetchBuildings();
        List<Building__c> buildings = new List<Building__c>();
        for(Id buildingId : setOfBuildingIds) {
            if(idToBuilding.containsKey(buildingId)){
                buildings.add(idToBuilding.get(buildingId));
            }
        }
        return buildings;
    }

    public static Building__c getBuildingById(Id buildingId){
        fetchBuildings();
        return idToBuilding.containsKey(buildingId) ? idToBuilding.get(buildingId) : null;
    }
    
    public static Building__c getBuildingByUUID(String buildingUUID){
        fetchBuildings();
        return uuidToBuilding.containsKey(buildingUUID) ? uuidToBuilding.get(buildingUUID) : null;
    }

    public static List<Building__c> getAllBuildings(){
        fetchBuildings();
        return buildings;
    }
}