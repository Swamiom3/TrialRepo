public with sharing class BuildingHandler {
    @TestVisible
    private static final BuildingSelector buildingSelector = new BuildingSelector();
    //	Returns the Building buildingUUID from the associated won Opportunity of the given account ID
    public static String getBuildingUUIDByAccount(Id pAccountID) {
        if (String.isBlank(pAccountID)) {
            return null;
        }
        String result;
        Set<String> stagesToSync = new Set<String>{'Closed Won','Closing'};
        Opportunity o = [ SELECT Building__r.UUID__c FROM Opportunity WHERE AccountID =: pAccountID AND stageName IN :stagesToSync LIMIT 1 ];
        result = o.Building__r.UUID__c;
        return result;
    }

    public static String getMultipicklistValuesFromUUID(List<String> buildingUUIDs){
        if (buildingUUIDs == null || buildingUUIDs.isEmpty()) {
            return null;
        }
        List<String> buildingNames = new List<String>{};
        for(Building__c building : buildingSelector.getBuildingsByUuid(buildingUUIDs)) {
            buildingNames.add(building.Name);
        }
        if(buildingNames.isEmpty()){
            return null;
        }
        return String.join(buildingNames, ';');
    }

    public static String[] getUUIDsFromMultipicklistValues(String pMultipicklistField) {
        if (String.isBlank(pMultipicklistField)) {
            return new String[]{};
        }
        String[] result = new String[]{};
        List<String> names = Common.splitStringToList(pMultipicklistField, ';');
        for (Building__c building : buildingSelector.getBuildingsByName(names)) {
            result.add(building.uuid__c);
        }
        return result;
    }

    public static Id getBuildingIdByUUID(String buildingUUID) {
        if (String.isBlank(buildingUUID)) {
            return null;
        }
        return BuildingUtility.getBuildingByUUID(buildingUUID).Id;
    }
    public static Map<Id, Building__c> allBuildings;
    public static Map<Id, Building__c> getAllBuildings(){
        if(allBuildings == null){
            allBuildings = new Map<Id, Building__c>(Settings.getAllBuildings());
        }
        return allBuildings;
    }
    public static List<Building__c> getSpecificBuildings(Set<String> buildingNames){
        List<Building__c> buildings = new List<Building__c>();
        for(Building__c building : BuildingHandler.getAllBuildings().values()){
            if(buildingNames.contains(building.Name)){
                buildings.add(building);
            }
        }
        return buildings;
    }
    public class BuildingHandlerException extends Exception{}
}