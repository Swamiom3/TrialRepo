/************************************************************************************************************************************
    Author 		:   Shubham Nandwana
    Description : 	This class updates the building from Service Contract when created via CPQ Amendment API 
    Issue No    :   TWSPG-6254
	----------------------------------------------------------------------------------------------------------------------------------
	VERSION		DATE				AUTHOR					DETAIL
    1			19 November 2021	Shubham Nandwana     	Initial Development	 
**************************************************************************************************************************************/
public class OppUpdBuildingFromAmendmentTrH  extends SObjectTriggerHandler{
    @TestVisible
    private final List<Opportunity> newOpportunities;

    public OppUpdBuildingFromAmendmentTrH(){
        this((List<Opportunity>) Trigger.new);
    }

    @testVisible
    private OppUpdBuildingFromAmendmentTrH(List<Opportunity> newOpportunities){
        this.newOpportunities = newOpportunities;
    }

    public override void beforeInsert(){
        populateBuilding();
    }
    
    private void populateBuilding(){
        List<Opportunity> filteredOpps = getFilteredOpportunities();
        if(filteredOpps.isEmpty()){
            return;
        }
        Map<Id,ServiceContract> serviceContractToBuilding = getServiceContractToBuilding();
        for(Opportunity opp : filteredOpps){
            if(serviceContractToBuilding.containsKey(opp.SBQQSC__AmendedServiceContract__c)){
                opp.Building__c = serviceContractToBuilding.get(opp.SBQQSC__AmendedServiceContract__c).Building_Id__c;
            }
        }
    }
    
    private List<Opportunity> getFilteredOpportunities(){
        List<Opportunity> opportunitiesWithoutBuilding = new List<Opportunity>();
        for(Opportunity opp : newOpportunities){
            if(String.isBlank(opp.Building__c) && String.isNotBlank(opp.SBQQSC__AmendedServiceContract__c)){
                opportunitiesWithoutBuilding.add(opp);
            }
        }
        return opportunitiesWithoutBuilding;
    }
    
    private Map<Id,ServiceContract> getServiceContractToBuilding(){
        List<Id> serviceContractIds = new List<Id>();
        for(Opportunity opp : newOpportunities){
            serviceContractIds.add(opp.SBQQSC__AmendedServiceContract__c);
        }
        Map<Id,ServiceContract> serviceContractToBuilding = new Map<Id, ServiceContract> ([SELECT Id, Building_Id__c 
                                                               	                           FROM ServiceContract 
                                                               	                           WHERE Id IN : serviceContractIds]);
        return serviceContractToBuilding;
    }
}