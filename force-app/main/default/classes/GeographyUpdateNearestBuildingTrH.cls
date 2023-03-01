/**********************************************************************************************************
    Author        :  Rohit Nimase
    Description   :  This trigger manages nearest building on geography .
    Issue No.     :  ST-8735
    History       :  ST-3200 ST-4337
-----------------------------------------------------------------------------------------------------------
    VERSION        DATE             AUTHOR             DETAIL
      1            07, Mar 2017     Priyanka Ambre     Initial Developement
      2            23,July 2019     Roshan Kankrayane  ST-4337 Update Nearest Building market on Georgraphy.
      3            9-Aug-2021       Rohit Nimase       Refactor and move to new framework
**********************************************************************************************************/
public class GeographyUpdateNearestBuildingTrH extends SObjectTriggerHandler {
    @TestVisible
    private BuildingSelector buildingSelector = new BuildingSelector();
    @TestVisible
    private List<Geography__c> newGeographies;
    @TestVisible
    private Map<Id, Geography__c> oldGeographiesMap;
    private static final String MILES = 'mi';
    private static final Set<String> FIELDS = new Set<String> {'Geocode__Latitude__s', 'Geocode__Longitude__s'};
        
    public GeographyUpdateNearestBuildingTrH(){
        this((List<Geography__c>) trigger.new, (Map<Id, Geography__c>) trigger.oldMap);
    }
    
    @TestVisible
    private GeographyUpdateNearestBuildingTrH(List<Geography__c> newGeography, Map<Id, Geography__c> oldGeographyMap) {
        this.newGeographies = newGeography;
        this.oldGeographiesMap = oldGeographyMap;
    }
    
    public override void beforeInsert() {        
        updateNearestBuilding();
        setPortfolioOnGeography();
    }
    
    public override void beforeUpdate() {
        updateNearestBuilding();
        setPortfolioOnGeography();
    }
    
    private void updateNearestBuilding() {
        Set<String> cities = new Set<String>();
        Set<String> states = new Set<String>();
        Set<String> countries = new Set<String>();
        List<Geography__c> geographies = new List<Geography__c>();
        
        for(Geography__c newGeo : newGeographies){
            Geography__c oldGeography = oldGeographiesMap?.get(newGeo.Id);
            if(oldGeography == null || (oldGeography != null && (newGeo.Nearest_Building__c == null 
                                                                 || TriggerUtility.isFieldsValueChanged(newGeo, oldGeography, FIELDS)))) {
                geographies.add(newGeo);
                cities.add(newGeo.City__c);
                states.add(newGeo.State__c);
                countries.add(newGeo.Country__c);
            }
        }
        if(geographies.isEmpty()) {
            return;
        }
        
        Map<String, List<Building__c>> locationTobuildingsWithGeo = new Map<String, List<Building__c>>();
        Map<String, List<Building__c>> locationTobuildingsWithoutGeo = new Map<String, List<Building__c>>();
        
        for(Building__c building : buildingSelector.getBuildingsByAddresses(new List<String>(cities), 
                                                                            new List<String>(states), 
                                                                            new List<String>(countries))) {
            addGeographyInMap('City__c', building, locationTobuildingsWithoutGeo, locationTobuildingsWithGeo);
            addGeographyInMap('State__c', building, locationTobuildingsWithoutGeo, locationTobuildingsWithGeo);
            addGeographyInMap('Country__c', building, locationTobuildingsWithoutGeo, locationTobuildingsWithGeo);
        }
        
        for(Geography__c geography : geographies) {
            Id buildingId;
            Geography__c oldGeography = oldGeographiesMap?.get(geography.Id);
            if(String.isBlank(buildingId)) {
                buildingId = getNearestBuilding('City__c', geography, locationTobuildingsWithGeo, oldGeography == null);
            }
            if(String.isBlank(buildingId)) {
                buildingId = getNearestBuilding('State__c', geography, locationTobuildingsWithGeo, oldGeography == null);
            }
            if(String.isBlank(buildingId)) {
                buildingId = getNearestBuilding('Country__c', geography, locationTobuildingsWithGeo, oldGeography == null);
            }
            if(String.isBlank(buildingId)) {
                buildingId = getNearestBuilding('City__c', geography, locationTobuildingsWithoutGeo, oldGeography == null);
            }
            if(String.isBlank(buildingId)) {
                buildingId = getNearestBuilding('State__c', geography, locationTobuildingsWithoutGeo, oldGeography == null);
            }
            if(String.isBlank(buildingId)) {
                buildingId = getNearestBuilding('Country__c', geography, locationTobuildingsWithoutGeo, oldGeography == null);
            }
            if(String.isBlank(buildingId)) {
                buildingId = getNearestBuilding(geography, Settings.getAllBuildings(), oldGeography == null, false);                        
            }
            if(String.isNotBlank(buildingId)) {
                geography.Nearest_Building__c = buildingId;
            }
        }
    }
    
    private void setPortfolioOnGeography() {
        for(Geography__c newGeo : newGeographies) {
            Geography__c oldGeography = oldGeographiesMap?.get(newGeo.Id);
            if(String.isNotBlank(newGeo.Nearest_Building__c)) {
                Building__c nearestBuilding = BuildingUtility.getBuildingById(newGeo.Nearest_Building__c);
                Id marketId = nearestBuilding?.Market__c;
                if(oldGeography == null || (marketId != newGeo.Building_Portfolio__c 
                                            || (oldGeography != null && TriggerUtility.isFieldValueChanged(newGeo, oldGeography, 'Nearest_Building__c')))) {
                    newGeo.Building_Portfolio__c = marketId;
                }
            }
        }
    }
    
    private void addGeographyInMap(String fieldName, Building__c building, 
                                   Map<String, List<Building__c>> locationTobuildingsWithoutGeo, 
                                   Map<String, List<Building__c>> locationTobuildingsWithGeo) {
        if(String.isNotBlank(building.Geography__c) && building.Geography__r.get(fieldName) != null) {
            addBuildingInMap(String.valueOf(building.Geography__r.get(fieldName)), building, locationTobuildingsWithGeo);
        }else if(String.isNotBlank((String)building.get(fieldName))) {
            addBuildingInMap((String)building.get(fieldName), building, locationTobuildingsWithoutGeo);
        }
    }
    
    private void addBuildingInMap(String geography, Building__c building, Map<String, List<Building__c>> buildings) {
        List<Building__c> geographyRelatedBuildings = buildings.containsKey(geography) ? buildings.get(geography) : new List<Building__c>();
        geographyRelatedBuildings.add(building);
        buildings.put(geography, geographyRelatedBuildings);
    }
    
    private Id getNearestBuilding(String fieldName, Geography__c geographyRec, Map<String, List<Building__c>> buildings, Boolean isInsert) {
        if(!String.isBlank((String)geographyRec.get(fieldName)) 
            && !buildings.isEmpty() 
            && buildings.containsKey((String)geographyRec.get(fieldName)) 
            && !buildings.get((String)geographyRec.get(fieldName)).isEmpty()){
            return getNearestBuilding(geographyRec, buildings.get((String)geographyRec.get(fieldName)), isInsert, true);
        }
        return null;
    }
    
    private Id getNearestBuilding(Geography__c geographyRec, List<Building__c> buildings, Boolean isInsert, Boolean isGeographyBlank) {
        Building__c nearestBuilding;
        Double distance;
        for(Building__c buildingRec : buildings) {
            if(!isInsert || (isInsert && (String.isBlank(geographyRec.Nearest_Building__c) 
                                          || (String.isNotBlank(geographyRec.Nearest_Building__c) && !geographyRec.Nearest_Building__c.equals(buildingRec.Id))))) {
                Double newDistance;
                if(String.isNotBlank(buildingRec.Geography__c)) {
                    newDistance = getDistance(geographyRec, buildingRec);
                    if(newDistance != null && (distance == null || newDistance < distance)) {
                        distance = newDistance;
                        nearestBuilding = buildingRec;
                    }
                }
                if(String.isBlank(buildingRec.Geography__c) && isGeographyBlank) {
                    return buildingRec.Id;
                }
            }
        }
        return nearestBuilding?.Id;
    }
    
    private Double getDistance(Geography__c geographyRec, Building__c buildingRec) {
        if(geographyRec.Geocode__Latitude__s == null || geographyRec.Geocode__Longitude__s == null) {
            return null;
        }
        return Location.getDistance(Location.newInstance(geographyRec.Geocode__Latitude__s, geographyRec.Geocode__Longitude__s), buildingRec.Geography__r.Geocode__c, MILES);
    }
}