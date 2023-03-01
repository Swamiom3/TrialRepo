/************************************************************************************************************************************
        Author              : Tomasz Sadowski
        Description         : https://jira.weworkers.io/browse/ST-7046
        Last Modified Date  : 13 Sep 2020
        Last Modified By    : Tomasz Sadowski
        Issue No            : ST-7046
********************************************************************************************************************************/
public with sharing class OpportunityVtsTrH extends SObjectTriggerHandler{
    private final List<Opportunity> newRecords;

    public OpportunityVtsTrH() {
        this((List<Opportunity>) Trigger.new); 
    }

    @TestVisible
    private OpportunityVtsTrH(List<Opportunity> newRecords) {
        this.newRecords = newRecords; 
    }

    public override void afterInsert() {
        createContactRolesAndReferrals();
    }
    
    private void createContactRolesAndReferrals() {
        Map<Id, Id> oppIdToAgencyBrokerId = new Map<Id, Id>();
        for (Opportunity opportunity : newRecords) {
            if (opportunity.Building__c == null) {
                continue;
            }
            Building__c building = BuildingUtility.getBuildingById(opportunity.Building__c);
            if (building?.Agency_Broker__c == null) {
                continue;
            }
            oppIdToAgencyBrokerId.put(opportunity.Id, building.Agency_Broker__c);
        }
        Map<Id, Contact> contactIdToContact = new Map<Id, Contact>([SELECT Id, Name, Email, Company__c FROM Contact WHERE Id IN :oppIdToAgencyBrokerId.values()]);
        List<OpportunityContactRole> oppConRoles = new List<OpportunityContactRole>();
        List<Referral__c> referralsToInsert = new List<Referral__c>();
        for (Opportunity opportunity : newRecords) {
            if (!oppIdToAgencyBrokerId.containsKey(opportunity.Id)) {
                continue;
            }
            Boolean isVtsCreationSource = opportunity.Opportunity_Creation_Source__c == GlobalConstants.OPPORTUNITY_CREATION_SOURCE_VTS;
            OpportunityContactRole leadRole = createContactRole(opportunity.Id, 
                                                                oppIdToAgencyBrokerId.get(opportunity.Id), 
                                                                isVtsCreationSource);
            oppConRoles.add(leadRole);
            
            if (!isVtsCreationSource) {
                continue;
            }
            Referral__c referral = createReferral(opportunity, opportunity.Id, contactIdToContact.get(oppIdToAgencyBrokerId.get(opportunity.Id)));
            referralsToInsert.add(referral);
        }
        if (!oppConRoles.isEmpty()) {
            dml.add(oppConRoles, DmlConsolidator.Operation.FOR_INSERT);
        }
        if (!referralsToInsert.isEmpty()) {
            dml.add(referralsToInsert, DmlConsolidator.Operation.FOR_INSERT);
        }
    }
    
    private OpportunityContactRole createContactRole(Id oppId, Id contactId, Boolean isLead) {
        OpportunityContactRole oppConRole = new OpportunityContactRole();
        oppConRole.OpportunityId = oppId;
        oppConRole.ContactId = contactId;
        oppConRole.Role = GlobalConstants.OPP_CONTACT_ROLE_AGENCY_BROKER;
        oppConRole.IsPrimary = isLead;
        
        return oppConRole;
    }

    private Referral__c createReferral(Opportunity opportunity, Id opportunityId, Contact contact) {
        Referral__c referral = new Referral__c();
        referral.Opportunity__c = opportunityId;
        referral.Referral_Portal_Event__c = 'Manual Opportunity Creation';
        referral.Referral_Contact__c = opportunity.Primary_Member__c;
        referral.Agency_Broker_Company__c = contact.Company__c;
        referral.Agency_Broker_Email__c = contact.Email;
        referral.Agency_Broker_Name__c = contact.Name;
        referral.Agency_Broker_Role__c = GlobalConstants.OPP_CONTACT_ROLE_AGENCY_BROKER;
        referral.Referrer__c = opportunity.Referrer__c;
        referral.IsRenewalOpportunity__c = false;

        return referral;
    }
}