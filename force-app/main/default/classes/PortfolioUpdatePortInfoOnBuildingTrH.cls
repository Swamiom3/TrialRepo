/************************************************************************************************************************************
Author      : Milanjeet
Description : This class contains logic for changing portfolios info on buildings after portfolio update

History :
----------------------------------------------------------------------------------------------------------------------------------
VERSION    DATE           AUTHOR            DETAIL
1          9 Nov 2017     Milanjeet         Initial development
2          16 Aug 2021    Pawel Biszczak    Refactor, moving handler logic to the new framework
**************************************************************************************************************************************/
public with sharing class PortfolioUpdatePortInfoOnBuildingTrH extends SObjectTriggerHandler {
    @TestVisible
    private BuildingSelector buildingSelector = new BuildingSelector();
    @TestVisible
    private List<Market__c> newPortfolios;
    @TestVisible
    private Map<Id, Market__c> oldPortfoliosMap;

    public PortfolioUpdatePortInfoOnBuildingTrH() {
        this(
            (List<Market__c>) Trigger.new,
            (Map<Id, Market__c>) Trigger.oldMap
        );
    }

    @TestVisible
    private PortfolioUpdatePortInfoOnBuildingTrH(List<Market__c> newPortfolios, Map<Id, Market__c> oldPortfoliosMap) {
        this.newPortfolios = newPortfolios;
        this.oldPortfoliosMap = oldPortfoliosMap;
    }

    public override void afterUpdate(){
        this.updatePortfolioInfoOnBuilding();
    }

    public void updatePortfolioInfoOnBuilding() {
        updateRecords(prepareBuildingsForPortfolioUpdate());
    }

    @TestVisible
    private List<Building__c> prepareBuildingsForPortfolioUpdate() {
        Set<Id> changedPortfoliosIds = getChangedPortfoliosIds();
        if (changedPortfoliosIds.isEmpty()) {
            return new List<Building__c>();
        }
        List<Building__c> buildingsFromPortfolios = buildingSelector.getBuildingsByMarkets(new List<Id>(changedPortfoliosIds));
        if (buildingsFromPortfolios.isEmpty()) {
            return new List<Building__c>();
        }
        return getBuildingsRecords(buildingsFromPortfolios);
    }

    @TestVisible
    private Set<Id> getChangedPortfoliosIds() {
        Set<Id> changedPortfoliosIds = new Set<Id>();
        for (Market__c marketRecord : newPortfolios) {
            if (!marketRecord.No_Longer_in_Use__c
                && ((marketRecord.Portfolio__c == null
                     || TriggerUtility.isFieldsValueChanged(marketRecord,
                                                            oldPortfoliosMap.get(marketRecord.Id),
                                                            new Set<String> {'Portfolio__c' ,'Sub_Territory__c',
                                                                             'Portfolio_Sales_Manager__c','TerritoryID__c',
                                                                             'Name'})))) {
                changedPortfoliosIds.add(marketRecord.Id);
            }
        }
        return changedPortfoliosIds;
    }

    @TestVisible
    private List<Building__c> getBuildingsRecords(List<Building__c> buildingsFromPortfolios) {
        List<Building__c> buildingsToUpdate = new List<Building__c>();
        for (Building__c building : buildingsFromPortfolios) {
            Building__c buildingForUpdate = new Building__c(Id = building.Id,
                                                            Portfolio_Name__c = building.Market__r.Portfolio__c,
                                                            Portfolio_Standard_Name__c = building.Market__r.Name,
                                                            Portfolio_Sales_Manager_Name__c = building.Market__r.Portfolio_Sales_Manager__r?.Name,
                                                            Territory_Name__c = building.Market__r.TerritoryId__r?.Territory__c,
                                                            Region_Name__c = building.Market__r.TerritoryId__r.RegionId__r.Region__c,
                                                            Territory_Sales_Manager_Name__c = building.Market__r.TerritoryId__r.Territory_Sales_Manager__r?.Name,
                                                            Regional_Sales_Manager_Name__c = building.Market__r.TerritoryId__r.RegionId__r.Regional_Sales_Manager__r?.Name,
                                                            Portfolio_Sales_Manager_Email__c = building.Market__r.Portfolio_Sales_Manager__r?.Email,
                                                            Territory_Sales_Manager_Email__c = building.Market__r.TerritoryId__r.Territory_Sales_Manager__r?.Email,
                                                            Regional_Sales_Manager_Email__c = building.Market__r.TerritoryId__r.RegionId__r.Regional_Sales_Manager__r?.Email,
                                                            Sub_Territory__c = building.Market__r.Sub_Territory__c
            );
            buildingsToUpdate.add(buildingForUpdate);
        }
        return buildingsToUpdate;
    }

    @TestVisible
    private void updateRecords(List<Building__c> records) {
        if (records.isEmpty()) {
            return;
        }
        try {
            update records;
        } catch (DmlException exp) {
            ApexDebugLog.logException(exp, String.join(new List<Id>(new Map<Id, Building__c>(records).keySet()), ','), 'PortfolioUpdatePortInfoOnBuildingTrH', 'updatePortfolioInfoOnBuilding');
            throw new PortfolioUpdatePortInfoOnBuildingTrHException(exp.getMessage());
        }
    }

    public class PortfolioUpdatePortInfoOnBuildingTrHException extends Exception{}
}