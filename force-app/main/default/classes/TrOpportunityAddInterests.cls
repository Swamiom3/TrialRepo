/******************************************************************
    Author      :   Jake Flynt
    Description :   When an Opportunity is created and tied to a 
					Building, an Interest record will also be created
					and tied to that Building. When the Opportunity
					is updated and the Building changes, a new Interest
					for that Building should also be created.
    Issue No    :	ST-5637
    History     :
    ---------------------------------------------------------------
    VERION      DATE                AUTHOR          DETAIL
    1           30 January 2020     Jake Flynt      Initial Development
    2           1 September 2020    Maciej Miłosz   Trigger Redesign
*******************************************************************/
public class TrOpportunityAddInterests extends SObjectTriggerHandler {

    /*
    *   Trigger context variables
    *   note: create only the ones required by business logic
    */
    @testVisible
    private List<Opportunity> newOpportunities;
    @testVisible
    private Map<Id, Opportunity> oldOpportunitiesMap;

    /*
    *   Constructors
    *   note: constructors should have only required trigger context variables
    */
    public TrOpportunityAddInterests(){
        this((List<Opportunity>) Trigger.new,
             (Map<Id, Opportunity>)Trigger.oldMap);
    }
    @testVisible
    private TrOpportunityAddInterests(List<Opportunity> newOpportunities,
                                      Map<Id, Opportunity> oldOpportunitiesMap){
        this.newOpportunities = newOpportunities;
        this.oldOpportunitiesMap = oldOpportunitiesMap;
    }


    public override void afterInsert(){
        List<Interest__c> interestsToInsert = new List<Interest__c>();
        for (Opportunity newOpportunity : newOpportunities) {
            if (newOpportunity.Building__c != null) {
                interestsToInsert.add(new Interest__c(Opportunity__c = newOpportunity.Id, Building__c = newOpportunity.Building__c));
            }
        }
        insertInterests(interestsToInsert);
    }

    public override void afterUpdate(){
        List<Interest__c> interestsToInsert = new List<Interest__c>();
        Set<Id> buildingIds = getChangedBuildingIds();
        
        Map<Id,Set<Id>> opportunityToBuildingWithInterestMap = getOpportunityToBuildingWithInterestIds(buildingIds);
        for (Opportunity newOpportunity : newOpportunities) {
            if (!buildingIds.contains(newOpportunity.Building__c)) {
                continue;
            }
            Set<Id> buildingsWithInterestIds = opportunityToBuildingWithInterestMap.get(newOpportunity.Id);
            // if there are NO interests with buildings tied to this opportunity OR
            // if there ARE interests with buildings tied to this opportunity but none with the new building
            if (buildingsWithInterestIds == null || !buildingsWithInterestIds.contains(newOpportunity.Building__c)) {
                interestsToInsert.add(new Interest__c(Opportunity__c = newOpportunity.Id, Building__c = newOpportunity.Building__c));
            }
        }
        insertInterests(interestsToInsert);
    }

    private Set<Id> getChangedBuildingIds(){
        Set<Id> buildingIds = new Set<Id>();
        for (Opportunity newOpportunity : newOpportunities) {
            Opportunity oldOpportunity = oldOpportunitiesMap.get(newOpportunity.Id);
            if (newOpportunity.Building__c != oldOpportunity.Building__c) {
                buildingIds.add(newOpportunity.Building__c);
            }
        }
        return buildingIds;
    }
    
    /* Creates map of opportunities to the list of buildings for which 
     * an interest record already exists. This allows us to avoid creating
     * a new interest record for the updated opportunity building if it
     * already exists.
     */
    private Map<Id,Set<Id>> getOpportunityToBuildingWithInterestIds(Set<Id> buildingIds) {
        Map<Id,Set<Id>> opportunityToBuildingWithInterestMap = new Map<Id,Set<Id>>();
        for (Interest__c interest : [SELECT Opportunity__c, Building__c FROM Interest__c WHERE Building__c IN :buildingIds]) {
            Set<Id> buildingsWithInterest;
            if (opportunityToBuildingWithInterestMap.get(interest.Opportunity__c) != null) {
                buildingsWithInterest = opportunityToBuildingWithInterestMap.get(interest.Opportunity__c);
            } else {
                buildingsWithInterest = new Set<Id>();
            }
            buildingsWithInterest.add(interest.Building__c);
            opportunityToBuildingWithInterestMap.put(interest.Opportunity__c, buildingsWithInterest);
        }        
        return opportunityToBuildingWithInterestMap;
    }
    
    /* If the list is not empty, calls Database.insert to insert the new 
     * Interest records
	*/
    private void insertInterests(List<Interest__c> lstInterestsToInsert) {
        if (!lstInterestsToInsert.isEmpty()) {
            try {
                Database.insert(lstInterestsToInsert, false);
            } catch (Exception ex) {
                ApexDebugLog.logException(ex, 'lstInterestsToInsert==>'+lstInterestsToInsert, 'TrOpportunityAddInterests', 'handle');
            }
        }
    }
}