public  with sharing class CaseBuildingChangedTrH extends SObjectTriggerHandler{
    @TestVisible
    private List<Case> newCases;
    @TestVisible
    private Map<Id, Case> oldCaseMap;
    @TestVisible
    private List<Id> buildingIds;
    @TestVisible
    private BuildingSelector buildingClass = new BuildingSelector();

    public CaseBuildingChangedTrH() {
        this(
            (List<Case>) Trigger.new,
            (Map<Id,Case>) Trigger.oldMap
        );
    }
    @TestVisible
    private CaseBuildingChangedTrH(List<Case> newCases, Map<Id, Case> oldCaseMap) {
        this.newCases = newCases;
        this.oldCaseMap = oldCaseMap;
        this.buildingIds = new List<Id>();
        getBuildingsFromCases();
    }

    public override void beforeInsert() {
        buildingChangedInsert();    
    }

    public override void beforeUpdate() {
        buildingChangedUpdate();    
    }

    @TestVisible
    private void buildingChangedInsert(){
        Map<Id, Building__c> buildings = new Map<Id, Building__c>(buildingClass.getBuildingHoursIdList(buildingIds));
        for(Case c : newCases){
            findWorkingHousForCase(buildings, c);
        } 
    }

    @TestVisible
    private void buildingChangedUpdate(){
        Map<Id, Building__c> buildings = new Map<Id, Building__c>(buildingClass.getBuildingHoursIdList(buildingIds));
        for(Case c : newCases){
            Case caseOld = oldCaseMap.get(c.Id);
            if(c.Building_Nearest_Address__c != caseold.Building_Nearest_Address__c){  
                findWorkingHousForCase(buildings, c);
            }
        } 
    }

    @TestVisible
    private void getBuildingsFromCases(){
        for(Case c : newCases){
            buildingIds.add(c.Building_Nearest_Address__c);
        }
    }

    @TestVisible
    private void findWorkingHousForCase(Map<Id, Building__c> buildings, Case c){
        if(!buildings.containsKey(c.Building_Nearest_Address__c)){
            return;
        }
        Building__c building = buildings.get(c.Building_Nearest_Address__c);
        if (String.isBlank(building.Business_Hours_Id__c)) {
            return;
        }
        c.BusinessHoursId = building.Business_Hours_Id__c;
        c.Is_Business_Day__c = BusinessHours.isWithin(c.BusinessHoursId, System.now());
        c.Is_Holiday__c = !BusinessHours.isWithin(c.BusinessHoursId, System.now());
    }
}