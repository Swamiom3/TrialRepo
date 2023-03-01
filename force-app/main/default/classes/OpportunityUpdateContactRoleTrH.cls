/*************************************************************************************************************************************
    Author      :   Pawel Biszczak
    Description :   This class handles Opportunity Contact Role update on Opportunity changes
    --------------------------------------------------------------------------------------------------------------------------------------
    VERSION    DATE            AUTHOR             	DETAIL
    1          14 Feb, 2022    Pawel Biszczak     	Initial Deployment
    2          13 May,2022     Salesforce           TWSPG-10802 This class runs on inherited sharing as to support Tours (Book a Tour Flow)
                                                    that runs on system context which updates Opportunity and Opportunity Contact Roles 
                                                    regardless of sharing rules. 		
**************************************************************************************************************************************/
public inherited sharing class OpportunityUpdateContactRoleTrH extends SObjectTriggerHandler {
    @TestVisible
    private List<Opportunity> newOpportunities;
    @TestVisible
    private Map<Id, Opportunity> oldOpportunitiesMap;
    private Map<String, List<OpportunityContactRole>> relatedOpportunitiesRolesMap;
    @TestVisible
    private List<OpportunityContactRole> opportunityRolesForUpsert;
    @TestVisible
    private List<OpportunityContactRole> opportunityRolesToUpdate;
    private OpportunityContactRoleSelector oppContRoleSelector = new OpportunityContactRoleSelector();

    public OpportunityUpdateContactRoleTrH() {
        this((List<Opportunity>) Trigger.new, (Map<Id, Opportunity>) Trigger.oldMap);
    }

    @TestVisible
    private OpportunityUpdateContactRoleTrH(List<Opportunity> newOpportunities, Map<Id, Opportunity> oldOpportunitiesMap) {
        this.newOpportunities = newOpportunities;
        this.oldOpportunitiesMap = oldOpportunitiesMap;
    }

    public override void afterInsert() {
        proceedWithRolesUpdateOnInsert();
    }

    public override void afterUpdate() {
        proceedWithRolesUpdateOnUpdate();
    }

    private void proceedWithRolesUpdateOnUpdate(){
        getRelateOpportunitiesRolesMap();
        if(relatedOpportunitiesRolesMap.isEmpty()) return;
        prepareOpportunityContactRolesOnUpdate();
        prepareRecordsForUpsert();
        
    }

    private void proceedWithRolesUpdateOnInsert(){
        prepareOpportunityContactRolesOnInsert();
        prepareRecordsForUpsert();
    }

    @TestVisible
    private void prepareOpportunityContactRolesOnInsert(){
        opportunityRolesForUpsert = new List<OpportunityContactRole>();
        for(Opportunity opportunityRecord : newOpportunities) {
            if(opportunityRecord.Primary_Member__c != null && opportunityRecord.Do_Not_Create_Opportunity_Role__c == false){
                OpportunityContactRole opportunityRoleToInsert = new OpportunityContactRole();
                opportunityRoleToInsert.OpportunityId = opportunityRecord.Id;
                opportunityRoleToInsert.ContactId = opportunityRecord.Primary_Member__c;
                opportunityRoleToInsert.IsPrimary = true;
                opportunityRoleToInsert.Role = GlobalConstants.OPP_CONTACT_ROLE_MAIN_CONTACT;
                opportunityRolesForUpsert.add(opportunityRoleToInsert);
            }
        }
    }

    private void getRelateOpportunitiesRolesMap(){
        relatedOpportunitiesRolesMap = new Map<String, List<OpportunityContactRole>>();
        Set<Id> opportunityIds = new Set<Id>();
        for(Opportunity opportunityRecord : newOpportunities) {
            if(TriggerUtility.isFieldsValueNotNullAndChanged(opportunityRecord,
                    oldOpportunitiesMap.get(opportunityRecord.Id),
                    new Set<String>{'Primary_Member__c'})){
                opportunityIds.add(opportunityRecord.Id);
            }
        }
        if(opportunityIds.isEmpty()) {
            return;
        }
        for (OpportunityContactRole opportunityRole : oppContRoleSelector.getOpportunityContactRolesByOppIds(opportunityIds)) {
            List<OpportunityContactRole> opportunityRoles = relatedOpportunitiesRolesMap.containsKey(opportunityRole.OpportunityId) ? relatedOpportunitiesRolesMap.get(opportunityRole.OpportunityId)
                    : new List<OpportunityContactRole>();
            opportunityRoles.add(opportunityRole);
            relatedOpportunitiesRolesMap.put(opportunityRole.OpportunityId, opportunityRoles);
        }
    }

    @TestVisible
    private void prepareOpportunityContactRolesOnUpdate(){
        opportunityRolesForUpsert = new List<OpportunityContactRole>();
        opportunityRolesToUpdate = new List<OpportunityContactRole>();
        for(Opportunity opportunityRecord : newOpportunities) {
            if (TriggerUtility.isFieldsValueNotNullAndChanged(opportunityRecord,
                                                              oldOpportunitiesMap.get(opportunityRecord.Id),
                                                              new Set<String>{
                                                                  'Primary_Member__c'
                                                              })
                  && relatedOpportunitiesRolesMap.get(opportunityRecord.Id) != null) {
                Boolean hasPrimaryContactRole = false;
                for (OpportunityContactRole opportunityRole : relatedOpportunitiesRolesMap.get(opportunityRecord.Id)) {
                    if (opportunityRole.ContactId == opportunityRecord.Primary_Member__c) {
                        opportunityRole.IsPrimary = true;
                        opportunityRole.Role = GlobalConstants.OPP_CONTACT_ROLE_MAIN_CONTACT;
                        hasPrimaryContactRole = true;
                        opportunityRolesForUpsert.add(opportunityRole);
                    } else if (opportunityRole.Role == GlobalConstants.OPP_CONTACT_ROLE_MAIN_CONTACT) {
                        opportunityRole.IsPrimary = false;
                        opportunityRole.Role = GlobalConstants.OPP_CONTACT_ROLE_BUSINESS_USER;
                        opportunityRolesToUpdate.add(opportunityRole);
                    }
                }

                if (hasPrimaryContactRole) continue;
                OpportunityContactRole opportunityRoleToInsert = new OpportunityContactRole();
                opportunityRoleToInsert.OpportunityId = opportunityRecord.Id;
                opportunityRoleToInsert.ContactId = opportunityRecord.Primary_Member__c;
                opportunityRoleToInsert.IsPrimary = true;
                opportunityRoleToInsert.Role = GlobalConstants.OPP_CONTACT_ROLE_MAIN_CONTACT;
                opportunityRolesForUpsert.add(opportunityRoleToInsert);
            } else if (TriggerUtility.isFieldsValueNotNullAndChanged(opportunityRecord,
                         oldOpportunitiesMap.get(opportunityRecord.Id),
                                          new Set<String>{
                                              'Primary_Member__c'
                                          })
                         && relatedOpportunitiesRolesMap.get(opportunityRecord.Id) == null) {
                OpportunityContactRole opportunityRoleToInsert = new OpportunityContactRole();
                opportunityRoleToInsert.OpportunityId = opportunityRecord.Id;
                opportunityRoleToInsert.ContactId = opportunityRecord.Primary_Member__c;
                opportunityRoleToInsert.IsPrimary = true;
                opportunityRoleToInsert.Role = GlobalConstants.OPP_CONTACT_ROLE_MAIN_CONTACT;
                opportunityRolesForUpsert.add(opportunityRoleToInsert);
            }
        }
    }

    private void prepareRecordsForUpsert(){
        if(opportunityRolesToUpdate != null && !opportunityRolesToUpdate.isEmpty()){
            update opportunityRolesToUpdate;
        }
        if(!opportunityRolesForUpsert.isEmpty()){
            dml.add(opportunityRolesForUpsert, DmlConsolidator.Operation.FOR_UPSERT);
        }
    }
}