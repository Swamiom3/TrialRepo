/************************************************************************************************************************************
    Author      :   Liubomyr Mishchykha
    Description :   Trigger handler for Opportunity Contact Role which validates that no duplicate records are created
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION     DATE                AUTHOR                  DETAIL
    1           May 27, 2021        Liubomyr Mishchykha     Initial version
    1.1         May 9, 2022         Oleksandr Liesnik       Removed duplicate logic in scope of TWSPG-10753
**************************************************************************************************************************************/
public with sharing class OpportunityContactRoleTrH extends SObjectTriggerHandler {

    private List<OpportunityContactRole> newOpportunityContactRoles;
    private Map<Id, OpportunityContactRole> oldOpportunityContactRolesMap;
    private Map<String, OpportunityContactRole> existingOpportunityRoles = new Map<String, OpportunityContactRole>();
    private Map<Id, List<OpportunityContactRole>> opportunityIdsToOpportunityContactRolesLists = new Map<Id, List<OpportunityContactRole>>();
    private OpportunityContactRoleSelector oppContRoleSelector = new OpportunityContactRoleSelector();
    
    public OpportunityContactRoleTrH() {
        this(
            (List<OpportunityContactRole>) Trigger.new,
            (Map<Id, OpportunityContactRole>) Trigger.oldMap
        );
    }

    @TestVisible
    private OpportunityContactRoleTrH(List<OpportunityContactRole> newRecords, Map<Id, OpportunityContactRole> oldRecords) {
        newOpportunityContactRoles = newRecords; 
        oldOpportunityContactRolesMap = oldRecords;
    }
    
    public override void beforeInsert() {
        getExistingRoles();
        checkRelatedRolesOnInsert();
    }
    
    public override void beforeUpdate() {
        getExistingRoles();
        checkRelatedRolesOnUpdate();
    }

    private void checkRelatedRolesOnInsert() {
        for (OpportunityContactRole opportunityRole : newOpportunityContactRoles) {
            if (existingOpportunityRoles.containsKey(constructMapKey(opportunityRole))) {
                opportunityRole.addError(Label.Opportunity_Contact_Role_Same_Parents_Error_Message);
            }
        }
    }

    private void checkRelatedRolesOnUpdate() {
        for (OpportunityContactRole opportunityRole : newOpportunityContactRoles) {
            if (TriggerUtility.isFieldsValueChanged(oldOpportunityContactRolesMap.get(opportunityRole.Id), opportunityRole, new Set<String>{'OpportunityId', 'ContactId'})
                    && existingOpportunityRoles.containsKey(constructMapKey(opportunityRole))) {
                opportunityRole.addError(Label.Opportunity_Contact_Role_Same_Parents_Error_Message);
            }
        }
    }

    private void getExistingRoles() {
        Set<Id> opportunityIds = new Set<Id>();
        Set<Id> contactIds = new Set<Id>();    
        for (OpportunityContactRole opportunityRole : newOpportunityContactRoles) {
            opportunityIds.add(opportunityRole.OpportunityId);
            contactIds.add(opportunityRole.ContactId);
        }
        for (OpportunityContactRole role : oppContRoleSelector.getOpportunityContactRolesByOppIds(opportunityIds)) {
            List<OpportunityContactRole> contactRoles = opportunityIdsToOpportunityContactRolesLists.containsKey(role.OpportunityId) 
                                                            ? opportunityIdsToOpportunityContactRolesLists.get(role.OpportunityId)
                                                            : new List<OpportunityContactRole>();
            contactRoles.add(role);
            opportunityIdsToOpportunityContactRolesLists.put(role.OpportunityId, contactRoles);
            if (contactIds.contains(role.ContactId)) {
                existingOpportunityRoles.put(constructMapKey(role), role); 
            }
        }
    }

    private String constructMapKey(OpportunityContactRole role) {
        return role.OpportunityId + '-' + role.ContactId;
    }
}