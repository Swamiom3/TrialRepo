/************************************************************************************************************************************
    Author      :   Andrei Dedovets
    Description :   Trigger handler for Opportunity Contact Role which validates Agency_Broker__c field 
    value on Building__c object to corresponding opportunity contact record with Agency Broker - Support 
    or Agency Broker - Lead role(1 to 1 relationship)
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION     DATE                AUTHOR                  DETAIL
    1           Nov 15, 2021        Andrei Dedovets     Initial version
**************************************************************************************************************************************/
public with sharing class OpportunityContactRoleValidationTrH extends SObjectTriggerHandler {

    private List<OpportunityContactRole> newOpportunityContactRoles;
    private Map<Id, OpportunityContactRole> oldOpportunityContactRolesMap;

    private Map<String, OpportunityContactRole> existingOpportunityRoles = new Map<String, OpportunityContactRole>();
    private Map<Id, List<OpportunityContactRole>> opportunityIdsToOpportunityContactRolesLists = new Map<Id, List<OpportunityContactRole>>();
    private List<OpportunityContactRole> opportunityRolesToUpdate = new List<OpportunityContactRole>();
    
    public OpportunityContactRoleValidationTrH() {
        this(
            (List<OpportunityContactRole>) Trigger.new,
            (Map<Id, OpportunityContactRole>) Trigger.oldMap
        );
    }

    @TestVisible
    private OpportunityContactRoleValidationTrH(List<OpportunityContactRole> newRecords, Map<Id, OpportunityContactRole> oldRecords) {
        newOpportunityContactRoles = newRecords; 
        oldOpportunityContactRolesMap = oldRecords;
    }
    
    public override void beforeInsert() {
        validateAgencyBrokerRole(newOpportunityContactRoles);
    }
    
    public override void beforeUpdate() {
        validateAgencyBrokerRole(newOpportunityContactRoles);
    }

    public override void beforeDelete() {
        validateAgencyBrokerRole((List<OpportunityContactRole>) oldOpportunityContactRolesMap.values());
    }

    private void validateAgencyBrokerRole(List<OpportunityContactRole> opportunityContactRoles) {
        Set<Id> opportunityIds = new Set<Id>();
        for (OpportunityContactRole item : opportunityContactRoles) {
            opportunityIds.add(item.OpportunityId);
        } 

        Map<Id,Opportunity> opportunitiesMap = new Map<Id,Opportunity>([
            SELECT Id, Building__r.Agency_Broker__c
            FROM Opportunity
            WHERE Id IN :opportunityIds
            LIMIT 50000
        ]);

        for (OpportunityContactRole contactRole : opportunityContactRoles) {
            Boolean isThrowErrorInsert = this.context == TriggerContext.BEFORE_INSERT
                && GlobalConstants.OPP_CONTACT_ROLE_AGENCY_BROKER == contactRole.Role 
                && opportunitiesMap?.get(contactRole.OpportunityId)?.Building__r?.Agency_Broker__c != contactRole.ContactId; 

            Boolean isThrowErrorUpdate = this.context == TriggerContext.BEFORE_UPDATE
                && ((TriggerUtility.isFieldsValueChanged(oldOpportunityContactRolesMap.get(contactRole.Id), contactRole, new Set<String>{'Role', 'ContactId'}) 
                        && GlobalConstants.OPP_CONTACT_ROLE_AGENCY_BROKER == oldOpportunityContactRolesMap.get(contactRole.Id)?.Role)
                    || (GlobalConstants.OPP_CONTACT_ROLE_AGENCY_BROKER == contactRole.Role
                        && opportunitiesMap?.get(contactRole.OpportunityId)?.Building__r?.Agency_Broker__c != contactRole.ContactId));
            
            Boolean isThrowErrorDelete = (this.context == TriggerContext.BEFORE_DELETE || this.context == TriggerContext.AFTER_DELETE)
                && contactRole.Role == GlobalConstants.OPP_CONTACT_ROLE_AGENCY_BROKER
                && opportunitiesMap?.get(contactRole.OpportunityId)?.Building__r?.Agency_Broker__c == contactRole.ContactId;
            
            if (isThrowErrorInsert || isThrowErrorUpdate || isThrowErrorDelete) {
                contactRole.addError(Label.BuildingAgencyBrokerValidationError);
            }
        }
    }
}