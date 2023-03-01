/************************************************************************************************************************************
Author      :   Andrei Dedovets
Description :   This method is used to set Agency Broker field value on Building__c 
                as Opportunity Contact team member with role as 'Agency Broker - Lead' or 'Agency Broker - Support'.
Issue No    :   ST-9005
----------------------------------------------------------------------------------------------------------------------------------
VERSION        DATE                AUTHOR                ISSUE NO        DETAIL
1           20 Oct 2021            Andrei Dedovets       ST-9005         Initial Developement
2           14 Apr 2022            Oleg Krasko           ST-9461         Refactoring and covering more scenarios
**************************************************************************************************************************************/
public with sharing class BuildingSetOpportunityContactTeamTrH extends SObjectTriggerHandler{ 
    
    @TestVisible
    private Map<Id, Building__c> newBuildingsMap;
    @TestVisible
    private Map<Id, Building__c> oldBuildingsMap;
    @TestVisible
    private static final List<String> OPPORTUNITY_CLOSED_STATUSES = new List<String>{GlobalConstants.OPP_CLOSED_WON_STAGE_NAME, GlobalConstants.OPP_CLOSED_LOST_STAGE_NAME};
    OpportunitySelector oppSelector;

    @TestVisible 
    public BuildingSetOpportunityContactTeamTrH(){
        this((Map<Id, Building__c>) Trigger.newMap, (Map<Id, Building__c>) Trigger.oldMap);
    }
    
    @TestVisible
    private BuildingSetOpportunityContactTeamTrH(Map<Id, Building__c> newBuildingsMap, Map<Id, Building__c> oldBuildingsMap){
        this.newBuildingsMap = newBuildingsMap;
        this.oldBuildingsMap = oldBuildingsMap;            
    }

    public override void afterUpdate(){
        setAgencyBrokerTeamMemberOnUpdate();
    }

    private void setAgencyBrokerTeamMemberOnUpdate(){
        Set<Id> agencyBrokerChangedBuildingIds = new Set<Id>();  

        for (Id item : newBuildingsMap.keySet()) {
            Building__c buildingRecord = newBuildingsMap.get(item);
            if (TriggerUtility.isFieldValueChanged(buildingRecord, oldBuildingsMap.get(buildingRecord.Id), 'Agency_Broker__c')) {
                agencyBrokerChangedBuildingIds.add(buildingRecord.Id);
            }
        }

        if (agencyBrokerChangedBuildingIds.isEmpty()) {
            return;
        }

        Map<OpportunityWithBuilding, OpportunityContactRole> oppWithBuildingToOppContactRole = new Map<OpportunityWithBuilding, OpportunityContactRole>();
        
        List<OpportunityContactRole> teamMembersToInsert = new List<OpportunityContactRole>();
        Set<OpportunityContactRole> teamMembersToDelete = new Set<OpportunityContactRole>();

        iterateOverOpportunities(agencyBrokerChangedBuildingIds, teamMembersToDelete, oppWithBuildingToOppContactRole);

        for (OpportunityWithBuilding pair : oppWithBuildingToOppContactRole.keySet()) {
            Building__c buildingRecord = newBuildingsMap.get(pair.buildingId);
            if (buildingRecord.Agency_Broker__c == null 
                || (oppWithBuildingToOppContactRole.get(pair).Role == GlobalConstants.OPP_CONTACT_ROLE_MAIN_CONTACT
                && oppWithBuildingToOppContactRole.get(pair).ContactId == buildingRecord.Agency_Broker__c)) {
                continue;
            }
            teamMembersToInsert.add(createContactRole(pair, buildingRecord.Agency_Broker__c));
        }

        if (!teamMembersToDelete.isEmpty()) {
            delete new List<OpportunityContactRole>(teamMembersToDelete);
        }
        
        if (!teamMembersToInsert.isEmpty()) {
            dmlPartial.add(teamMembersToInsert, DmlConsolidator.Operation.FOR_INSERT);
        }
    }

    private void iterateOverOpportunities(Set<Id> buildingIds, Set<OpportunityContactRole> teamMembersToDelete, 
                                        Map<OpportunityWithBuilding, OpportunityContactRole> oppWithBuildingToOppContactRole) {
        oppSelector = new OpportunitySelector();
        for (Opportunity opp : oppSelector.getOpportunitiesWithContactRolesByBuildIds(buildingIds, OPPORTUNITY_CLOSED_STATUSES)) {
            OpportunityWithBuilding pair = new OpportunityWithBuilding(opp.Id, opp.Building__c, opp.Opportunity_Creation_Source__c == 'VTS');
            for (OpportunityContactRole oppContRole : opp.OpportunityContactRoles) {
                if (oppContRole.Role == GlobalConstants.OPP_CONTACT_ROLE_AGENCY_BROKER) {
                    teamMembersToDelete.add(oppContRole);
                } else {
                    oppWithBuildingToOppContactRole.put(pair, oppContRole);
                }
            }
        }
    }

    private OpportunityContactRole createContactRole(OpportunityWithBuilding pair, Id contactId) {
        OpportunityContactRole oppConRole = new OpportunityContactRole();
        oppConRole.OpportunityId = pair.opporunityId;
        oppConRole.ContactId = contactId;
        oppConRole.Role = GlobalConstants.OPP_CONTACT_ROLE_AGENCY_BROKER;
        oppConRole.IsPrimary = pair.isVTS;
        
        return oppConRole;
    }

    class OpportunityWithBuilding{
        OpportunityWithBuilding(Id opporunityId, Id buildingId, Boolean isVTS){
            this.opporunityId = opporunityId;
            this.buildingId = buildingId;
            this.isVTS = isVTS; 
        }
        Id opporunityId;
        Id buildingId;
        Boolean isVTS;
    }
}