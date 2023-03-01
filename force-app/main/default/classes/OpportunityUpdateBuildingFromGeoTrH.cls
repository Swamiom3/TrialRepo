/************************************************************************************************************************************
    Author      :   Liubomyr Mishchykha	
    Description :   Trigger handler class for modifying opportunities based on Building and Geography values.
                    Created during trigger redesign (ST-6867)
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION     DATE                AUTHOR                  DETAIL
    1           Sep 9, 2020         Liubomyr Mishchykha     Initial version
**************************************************************************************************************************************/
public with sharing class OpportunityUpdateBuildingFromGeoTrH extends SObjectTriggerHandler {

    @TestVisible
    private List<Opportunity> newOpportunities;
    @TestVisible
    private Map<Id, Opportunity> oldOpportunitiesMap;
    @TestVisible
    private GeographySelector geographySelector = new GeographySelector();

    public OpportunityUpdateBuildingFromGeoTrH() {
        this((List<Opportunity>) Trigger.new, (Map<Id, Opportunity>) Trigger.oldMap);
    }

    @TestVisible
    private OpportunityUpdateBuildingFromGeoTrH(List<Opportunity> newOpportunities, Map<Id, Opportunity> oldOpportunitiesMap) {
        this.newOpportunities = newOpportunities;
        this.oldOpportunitiesMap = oldOpportunitiesMap;
    }

    public override void beforeInsert() {
        updateOpportunityFromBuilding();
    }

    public override void beforeUpdate() {
        updateOpportunityFromBuilding();
    }

    private void updateOpportunityFromBuilding() {
        Map<Id, List<Opportunity>> geoIdsToOpportunities = filterOpportunities();
        if (!geoIdsToOpportunities.isEmpty()) {
            updateBuilding(geoIdsToOpportunities);
        }
    }

    /**
    * @author Gad Sharon
    * @date 02/10/18
    * @description Find relevant opps we need to run the logic on.
    * @param List<Opportunity> - The opps this trigger is running on.
             Map<Id, sObject> - The old stage of the opps this trigger is running on.
    * @return map <Id, list <Opportunity>> - Map of geography id to list of opps that have that geography. 
    */
    @TestVisible
    private Map<Id, List<Opportunity>> filterOpportunities() {
        Map <Id, List<Opportunity>> geoIdsToOpportunities = new Map <Id, List<Opportunity>>();

        for (Opportunity opp : newOpportunities) {
            Opportunity oldOpp = oldOpportunitiesMap != null && oldOpportunitiesMap.containsKey(opp.Id) ? oldOpportunitiesMap.get(opp.Id) : null;
            if (requireBuildingAssignment(opp, oldOpp)) { //Do we need to assign a building according to the geography?
                if (!geoIdsToOpportunities.containsKey(opp.Geography__c)) {
                    geoIdsToOpportunities.put(opp.Geography__c, new List<Opportunity>());
                }
                geoIdsToOpportunities.get(opp.Geography__c).add(opp);
            }
        }
        return geoIdsToOpportunities;
    }

    /**
    * @author Gad Sharon
    * @date 02/10/18
    * @description Find relevant opps we need to run the logic on.
    * @param map <Id, list <Opportunity>> - Map of geography id to list of opps that have that geography.
    * @return None. 
    */
    @TestVisible
    private void updateBuilding(Map<Id, List<Opportunity>> geoIdsToOpportunities) {
        List<Geography__c> geographies = (geographySelector.getGeographiesByIdAndNotNullNearestBuilding(new List<Id>(geoIdsToOpportunities.keySet())));
        for (Geography__c geography : geographies) {
            updateOpportunitiesFromGeography(geography, geoIdsToOpportunities);
        }
    }

    private void updateOpportunitiesFromGeography(Geography__c geography, Map<Id, List<Opportunity>> geoIdsToOpportunities) {
        for (Opportunity opp : geoIdsToOpportunities.get(geography.Id)) {
            opp.Building__c = geography.Nearest_Building__c;
            Building__c building = BuildingUtility.getBuildingById(opp.Building__c);
            OpportunityHelper.updateDataFromRelatedObject(building, opp);
        }
    }

    /**
    * @author Gad Sharon
    * @date 13 Aug, 2019
    * @description Check if there's no building and we need to set one according to the geography.
    * @param Opportunity - The current opportunity.
    * @param Opportunity - The opportunity state prior to an update action. Can be null if it's insert.
    * @return boolean - true if we need to set a building, false otherwise. 
    */
    @TestVisible
    private Boolean requireBuildingAssignment(Opportunity newOpp, Opportunity oldOpp) {
        Boolean isNew = oldOpp == null;
        Boolean doNothaveBuilding = newOpp.Building__c == null;
        Boolean haveGeography = newOpp.Geography__c != null;
        Boolean geographyChanged = !isNew && newOpp.Geography__c != oldOpp.Geography__c;
        return doNothaveBuilding && haveGeography && (isNew || geographyChanged);
    }

    /**
    * @author Gad Sharon
    * @date 13 Aug, 2019
    * @description Check if the user selected a building manually in an opportunity that was set as a sub market based opportunity.
    * @param Opportunity - The current opportunity.
    * @param Opportunity - The opportunity state prior to an update action. Can be null if it's insert.
    * @return boolean - true if the user selected a building manually, false otherwise. 
    */
    @TestVisible
    private Boolean buildingSelectedManually(Opportunity newOpp, Opportunity oldOpp) {
        Boolean isUpdate = oldOpp != null;
        Boolean haveBuilding = newOpp.Building__c != null;
        Boolean buildingChanged = isUpdate && oldOpp.Building__c != newOpp.Building__c;
        return isUpdate && haveBuilding && buildingChanged;
    }
}