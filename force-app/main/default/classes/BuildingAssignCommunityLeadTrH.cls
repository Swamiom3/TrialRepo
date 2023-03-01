/*********************************************************************************************************
    Author        :  Krishna Somwanshi
    Description   :  This class is used to Updated the Value of Community Lead On Insertion and Update.
    Issue No.     :  ST-8736
    History       :
-----------------------------------------------------------------------------------------------------------
    VERSION        DATE            AUTHOR             DETAIL
    1          24-Aug-2021      Krishna Somwanshi     Refactor
**********************************************************************************************************/
public with sharing class BuildingAssignCommunityLeadTrH extends SObjectTriggerHandler {
    @TestVisible
    private List<Building__c> newBuildings;
    
    public BuildingAssignCommunityLeadTrH() {
        this(
            (List<Building__c>) Trigger.new
        );
    }
    
    @TestVisible
    private BuildingAssignCommunityLeadTrH(List<Building__c> newBuildings) {
        this.newBuildings = newBuildings;
    }
    
    public override void beforeInsert() {
        setCommunitySalesLeadOnBuildings();
    }

    public override void beforeUpdate() {
        setCommunitySalesLeadOnBuildings();
    }

    private void setCommunitySalesLeadOnBuildings() {
        for(Building__c building : newBuildings) {
            building.Community_Lead__c = building.Community_Sales_Lead__c;
        }
    }
}