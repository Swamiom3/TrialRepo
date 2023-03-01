/**********************************************************************************************************************************
    Author      :   Vipul Chaudhari 
    Description :   This class handles the duplicate management of the Interest object.
    Issue No    :	ST-9052
    -------------------------------------------------------------------------------------------------------------------------------
    VERSION     DATE                  AUTHOR                     DETAIL
    1           23 Sep 2021       Vipul Chaudhari           Initial Developement
**********************************************************************************************************************************/
public class InterestDuplicateManagementTrH extends SObjectTriggerHandler {
    @TestVisible
    private List<Interest__c> newInterests;
    @TestVisible
    private Map<Id, Interest__c> oldInterestsMap;
    @TestVisible
    public static Boolean isFromGenerateProposal = false;
    @TestVisible
    private InterestSelector interestSelector = new InterestSelector();
    
    public InterestDuplicateManagementTrH(){
        this((List<Interest__c>) Trigger.new, (Map<Id, Interest__c>) Trigger.oldMap);
    }
    
    @TestVisible
    private InterestDuplicateManagementTrH( List<Interest__c> newInterest, Map<Id, Interest__c> oldInterestMap) {
        this.newInterests = newInterest;
        this.oldInterestsMap = oldInterestMap;
    }
    
    public override void beforeInsert() {
        manageDuplicateInterests();
    }
    
    public override void beforeUpdate() {
        manageDuplicateInterests();
    }
    
    public void manageDuplicateInterests() {
        if(isFromGenerateProposal) {
            return;
        }
        Map<Id, Map<Id, Id>> oppToMapBuildingToInventory = new Map<Id, Map<Id, Id>>();
        Set<Id> interestIds = new Set<Id>();
        Map<String, Interest__c> uniqueIdentifierToInterest = new Map<String, Interest__c>();
        String uniqueIdentifier;
        for(Interest__c interest : newInterests){
            if (interest.Opportunity__c != null) { // comparisons only matter against the same opportunity
                uniqueIdentifier = String.valueOf(interest.Opportunity__c) + String.valueOf(interest.Building__c); 
                uniqueIdentifierToInterest.put(uniqueIdentifier, interest);
                if (interest.Inventory_Id__c != null) {
                    uniqueIdentifier += String.valueOf(interest.Inventory_Id__c); // match on opportunity/building/inventory
                    uniqueIdentifierToInterest.put(uniqueIdentifier, interest);
                }
                Map<Id, Id> buildingToInventoryId = new Map<Id, Id>();
                buildingToInventoryId.put(interest.Building__c, interest.Inventory_Id__c);
                oppToMapBuildingToInventory.put(interest.Opportunity__c, buildingToInventoryId);
            }
            Interest__c oldInterest = oldInterestsMap?.get(interest.Id);
            if (oldInterest != null) {
                interestIds.add(interest.Id);
            }
        }
        if (oppToMapBuildingToInventory.isEmpty()) {
            return;
        }
        for (Interest__c interest : interestSelector.getInterestByOpportunity(interestIds,oppToMapBuildingToInventory.keySet())) {
            Map<Id, Id> buildingToInventoryId = oppToMapBuildingToInventory.get(interest.Opportunity__c); 
            for (Id buildingId : buildingToInventoryId.keySet()) {
                if (buildingId != interest.Building__c) {
                    continue;
                } 
                if (buildingToInventoryId.get(buildingId) == interest.Inventory_Id__c && interest.Inventory_Id__c != null) {
                    Interest__c duplicateInterest = uniqueIdentifierToInterest.get(String.valueOf(interest.Opportunity__c)+String.valueOf(interest.Building__c)+String.valueOf(interest.Inventory_Id__c));
                    if (duplicateInterest != null) {
                        duplicateInterest.addError('Interest (' + interest.Name + ') with the same Opportunity, Building, and Inventory already exists');
                    }
                } else if (interest.Inventory_Id__c == null) {
                    Interest__c duplicateInterest = uniqueIdentifierToInterest.get(String.valueOf(interest.Opportunity__c)+String.valueof(interest.Building__c));
                    if (duplicateInterest != null) {
                       duplicateInterest.addError('Interest (' + interest.Name + ') with the same Opportunity and Building exists with no Inventory. Add a Inventory to that Interest instead of creating a new one.');
                    }
                }
            }
        }
    }
}