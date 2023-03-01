/************************************************************************************************************************************
    Author : Salesforce
    Description : This class is used to create/update service territory record on building record insertion
   ----------------------------------------------------------------------------------------------------------------------------------
    VERSION      DATE              AUTHOR         DETAIL                    ISSUE
    1            21 July, 2021     Salesforce     Initial Developement      TWSPG-2142
**************************************************************************************************************************************/
public with sharing class BuildingAssociateServiceTerritoryTrH extends SObjectTriggerHandler {
    @TestVisible
    private List<Building__c> newBuildings;
    
    @TestVisible
    private Map<Id, Building__c> oldBuildingsMap;
    
    @TestVisible
    private Map<Id, Building__c> newBuildingsMap;
    
    @TestVisible
    private final List<String> DEFAULT_DAYS_OF_WEEK = new List<String>{'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'};

    @TestVisible
    private final String DEFAULT_TIME_ZONE = 'GMT';
    
    public BuildingAssociateServiceTerritoryTrH() {
        this((List<Building__c>) Trigger.new, (Map<Id, Building__c>) Trigger.newMap, (Map<Id, Building__c>) Trigger.oldMap);        
    }
    
    @TestVisible
    private BuildingAssociateServiceTerritoryTrH(List<Building__c> newBuildings, 
                                                Map<Id, Building__c> newBuildingsMap,
                                                Map<Id, Building__c> oldBuildingsMap) {
        this.newBuildings = newBuildings;
        this.newBuildingsMap = newBuildingsMap;
        this.oldBuildingsMap = oldBuildingsMap;
    }
    
    public override void beforeInsert() {
        manageIsTourable();
    }

    public override void beforeUpdate() {
        manageIsTourable();
    }

    public override void afterInsert() {
       createServiceTerritoryRecords();
    }
    
    public override void afterUpdate() {
       createServiceTerritoryRecords();
    }

    /**
     * This method will unset the Is Tourable flag If the Building is set to No Longer in Use.
     */
    @TestVisible
    private void manageIsTourable(){
        for(Building__c building: newBuildings){
            if(building.No_Longer_in_Use__c){
                building.Is_Tourable__c = false;
            }
        }
    }

    /**
     * This method creates/updates ServiceTerritory records based on Building Information
     * and Keeps the ServiceTerritory in sync with Building when building is updated.
     */
    @TestVisible
    private void createServiceTerritoryRecords(){
        // Get Operating Hours
        Map<Id, OperatingHours> buildingOperatingHoursMap =  getDefaultOperatingHours();
        List<ServiceTerritory> serviceTerritories = new List<ServiceTerritory>();
        for(Building__c building : newBuildings){
            ServiceTerritory servTerr = generateServiceTerritory(building);
            servTerr.Name = building.name;
            servTerr.OperatingHoursId = buildingOperatingHoursMap.get(building.Id).Id;
            serviceTerritories.add(servTerr);
        }
        upsert serviceTerritories Building_External_Id__c;
    }

    private ServiceTerritory generateServiceTerritory(Building__c building){
        ServiceTerritory st = new ServiceTerritory (
            Name = building.Name,
            Building_Id__c = building.Id,
            IsActive = building.Is_Tourable__c,
            OwnerId = building.OwnerId,
            Street = building.Address__c,
            City = building.City__c,
            State = building.State__c,
            Building_External_Id__c = building.Id,
            Country = building.Country__c,
            Postalcode = building.Postal_Code__c
            );
            if(building.Country__c == 'South Korea'){
                st.Country = 'Korea';
            }
            return st;
    }

    @TestVisible
    private Map<Id, OperatingHours> getDefaultOperatingHours(){
        // Get Operating Hours if already exist for building
        Map<Id, OperatingHours> buildingOperatingHoursMap = getBuildingOperatingHours();

        // Create Default Operating Hours records if doesn't exists already
        List<OperatingHours> opHoursToInsert = new List<OperatingHours>();        
        for(Building__c building : newBuildings){
            if(buildingOperatingHoursMap.isEmpty() || buildingOperatingHoursMap.get(building.Id) == null){
                OperatingHours oHour = new OperatingHours();
                oHour.Name = building.Name + ' - Operating Hours'; 
                oHour.Building_Id__c = building.Id;
                oHour.TimeZone = ((String.isBlank(building.Time_Zone__c) || building.Time_Zone__c.equalsIgnoreCase('Etc/UTC'))? DEFAULT_TIME_ZONE: building.Time_Zone__c);                
                opHoursToInsert.add(oHour);
            }
        }
        insert opHoursToInsert;

        // Create Default Time Slot records
        List<TimeSlot> timeSlotsToInsert = new List<TimeSlot>();
        for(OperatingHours opHour: opHoursToInsert){
            buildingOperatingHoursMap.put(opHour.Building_Id__c, opHour);
            for(String dayOfWeek: DEFAULT_DAYS_OF_WEEK){
                timeSlotsToInsert.add(generateDefaultTimeSlot(opHour.Id, dayOfWeek));
            }
        }
        insert timeSlotsToInsert;
        return buildingOperatingHoursMap;
    }

    private TimeSlot generateDefaultTimeSlot(Id operatingHourId, String dayOfWeek){
        return new TimeSlot (
            OperatingHoursId = operatingHourId,
            DayOfWeek = dayOfWeek,
            StartTime = Time.newInstance(9, 0, 0, 0),
            EndTime = Time.newInstance(17, 0, 0, 0)
        );
    }

    private Map<Id, OperatingHours> getBuildingOperatingHours(){
        Map<Id, OperatingHours> buildingOperatingHoursMap = new Map<Id, OperatingHours>();
        for(OperatingHours oHour: [SELECT Id, Building_Id__c 
                                   FROM OperatingHours 
                                   WHERE Building_Id__c IN : newBuildingsMap.keySet()
                                       AND Host_Id__c = null]) {
            buildingOperatingHoursMap.put(oHour.Building_Id__c, oHour);
        }
        return buildingOperatingHoursMap;
    }
    
}