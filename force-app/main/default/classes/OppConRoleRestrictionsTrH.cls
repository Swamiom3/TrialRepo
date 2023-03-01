/************************************************************************************************************************************
    Author       :  Shubham Nandwana   
    @Description :  Create validation for OpportunityContactRole records per opportunity
    Issue No     :  TWSPG-2928
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION     DATE                AUTHOR              ISSUE NO        DETAIL
    1           27 August 2021      Shubham Nandwana    TWSPG-2928      Initial Developement              
**************************************************************************************************************************************/
public with sharing class OppConRoleRestrictionsTrH extends SObjectTriggerHandler {
    private Set<Id> opportunityIdsToBeFiltered = new Set<Id>();
    private Set<String> roleNamesToBeFiltered = new Set<String>();
    private Map<String, List<OpportunityContactRole>> opportunityRoleToOppContactRoles = new Map<String, List<OpportunityContactRole>>();

    private Map<String, String> roleSettings = new Map<String, String>();
    private final String SUFFIX_COUNT = '_Count';
    private final String SUFFIX_ERROR = '_Error';

    @TestVisible
    private List<OpportunityContactRole> newOpportunityContactRoles;
    @TestVisible
    private Map<Id, OpportunityContactRole> oldOpportunityContactRolesMap;

    public OppConRoleRestrictionsTrH() {
        this((List<OpportunityContactRole>) Trigger.new, (Map<Id, OpportunityContactRole>) Trigger.oldMap);
        populateRoleSettingWrapperMap();
    }

    @TestVisible
    private OppConRoleRestrictionsTrH(List<OpportunityContactRole> newOpportunityContactRoles, Map<Id, OpportunityContactRole> oldOpportunityContactRolesMap) {
        this.newOpportunityContactRoles = newOpportunityContactRoles;
        this.oldOpportunityContactRolesMap = oldOpportunityContactRolesMap;
    }

    public override void beforeInsert() {
        List<OpportunityContactRole> oppContactRoles = filterOpportunityContactRole();
        populateOpportunityIdsWithRoles();
        validateRoleOCRs(oppContactRoles);
    }

    public override void beforeUpdate() {
        List<OpportunityContactRole> oppContactRoles = filterOpportunityContactRole();
        populateOpportunityIdsWithRoles();
        validateRoleOCRs(oppContactRoles);
    }

    private List<OpportunityContactRole> filterOpportunityContactRole() {
        List<OpportunityContactRole> oppContactRoles = new List<OpportunityContactRole>();
        for (OpportunityContactRole ocr : newOpportunityContactRoles) {
            String key = ocr.OpportunityId + ocr.Role;
            if (opportunityRoleToOppContactRoles.containsKey(key)) {
                opportunityRoleToOppContactRoles.get(key).add(ocr);
            } else {
                opportunityRoleToOppContactRoles.put(key, new List<OpportunityContactRole>{ ocr });
            }
            if (oldOpportunityContactRolesMap != null && oldOpportunityContactRolesMap.get(ocr.id).Role == ocr.Role) {
                continue;
            }
            opportunityIdsToBeFiltered.add(ocr.opportunityId);
            oppContactRoles.add(ocr);
            roleNamesToBeFiltered.add(ocr.Role);
        }
        return oppContactRoles;
    }

    private void populateOpportunityIdsWithRoles() {
        for (OpportunityContactRole ocr : getOppRolesByOppIdsAndRoleNames(opportunityIdsToBeFiltered, roleNamesToBeFiltered)) {
            String key = ocr.OpportunityId + ocr.Role;
            if (opportunityRoleToOppContactRoles.containsKey(key)) {
                opportunityRoleToOppContactRoles.get(key).add(ocr);
            } else {
                opportunityRoleToOppContactRoles.put(key, new List<OpportunityContactRole>{ ocr });
            }
        }
    }

    private void validateRoleOCRs(List<OpportunityContactRole> oppContactRoles) {
        for (OpportunityContactRole ocr : oppContactRoles) {
            if (!isRolePresentInConfiguration(ocr)) {
                continue;
            }
            String key = ocr.OpportunityId + ocr.Role;
            if (
                opportunityRoleToOppContactRoles.get(key) != null &&
                opportunityRoleToOppContactRoles.get(key).size() > Integer.valueOf(roleSettings.get(ocr.Role + SUFFIX_COUNT))
            ) {
                ocr.addError(roleSettings.get(ocr.Role + SUFFIX_ERROR));
            }
        }
    }

    private Boolean isRolePresentInConfiguration(OpportunityContactRole ocr) {
        return roleSettings.containsKey(ocr.Role + SUFFIX_COUNT);
    }

    private List<OpportunityContactRole> getOppRolesByOppIdsAndRoleNames(Set<Id> opportunityIdsToBeFiltered, 
                                                                        Set<String> roleNamesToBeFiltered){
        return [
            SELECT Id, Role, OpportunityId
            FROM OpportunityContactRole
            WHERE OpportunityId IN :opportunityIdsToBeFiltered AND Role IN :roleNamesToBeFiltered
        ];
    }

    public void populateRoleSettingWrapperMap() {
        Map<String, Opportunity_Contact_Role_Setting__mdt> oppConRoleSettings = Opportunity_Contact_Role_Setting__mdt.getAll();
        for (String roleName : oppConRoleSettings.keySet()) {
            String key = oppConRoleSettings.get(roleName).label;
            roleSettings.put(key + SUFFIX_COUNT, String.valueOf(oppConRoleSettings.get(roleName).Count__c));
            roleSettings.put(key + SUFFIX_ERROR, oppConRoleSettings.get(roleName).Error_Message__c);
        }
    }
}