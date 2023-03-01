/*************************************************************************************************************************************
    Author      :   Pawel Biszczak
    Description :   This class handles Broker Involved fields update on Opportunity changes
    --------------------------------------------------------------------------------------------------------------------------------------
    VERSION    DATE            AUTHOR             DETAIL
    1          14 Feb, 2022    Pawel Biszczak     Initial Deployment
**************************************************************************************************************************************/
public with sharing class OpportunitySetBrokerInvolvedTrH extends SObjectTriggerHandler {

    @TestVisible
    private List<Opportunity> newOpportunities;
    @TestVisible
    private Map<Id, Opportunity> oldOpportunitiesMap;
    @TestVisible
    private ContactSelector contactSelector = new ContactSelector();

    public OpportunitySetBrokerInvolvedTrH() {
        this((List<Opportunity>) Trigger.new, (Map<Id, Opportunity>) Trigger.oldMap);
    }

    @TestVisible
    private OpportunitySetBrokerInvolvedTrH(List<Opportunity> newOpportunities, Map<Id, Opportunity> oldOpportunitiesMap) {
        this.newOpportunities = newOpportunities;
        this.oldOpportunitiesMap = oldOpportunitiesMap;
    }

    public override void beforeInsert() {
        setBrokerInvolved();
    }

    public override void beforeUpdate() {
        setBrokerInvolved();
    }

    @TestVisible
    private void setBrokerInvolved(){
        Set<Id> referrerIds = new Set<Id>();
        Map<Id, Contact> idsByReferrerContactsMap = new Map<Id, Contact>();
        for(Opportunity opportunity : newOpportunities) {
            if(opportunity.Referrer__c != null && opportunity.Broker_Involvement_Indicated__c != GlobalConstants.YES) {
                referrerIds.add(opportunity.Referrer__c);
            }
        }
        if(!referrerIds.isEmpty()) {
            idsByReferrerContactsMap = new Map<Id, Contact>(contactSelector.getContactsByIds(referrerIds));
        }
        for(Opportunity opportunity : newOpportunities) {
            Boolean isLeadSourceBrokerReferral = String.isNotBlank(opportunity.LeadSource)
                                                 && opportunity.LeadSource.equalsIgnoreCase(GlobalConstants.OPP_LEAD_SOURCE_BROKER_REF)
                                                 && String.isNotBlank(opportunity.Referrer__c);
            Boolean isLeadSourceSubtypeBrokerReferral = String.isNotBlank(opportunity.LeadSource)
                                                        && opportunity.LeadSource.equalsIgnoreCase(GlobalConstants.OPP_LEAD_SOURCE_REFERRAL)
                                                        && String.isNotBlank(opportunity.LeadSource_Sub_Type__c)
                                                        && opportunity.LeadSource_Sub_Type__c.equalsIgnoreCase(GlobalConstants.OPP_LEAD_SOURCE_BROKER_REF)
                                                        && String.isNotBlank(opportunity.Referrer__c);
            Boolean isReferrerTypeBroker =
                    (String.isNotBlank(opportunity.LeadSource)
                         && (!opportunity.LeadSource.equalsIgnoreCase(GlobalConstants.OPP_LEAD_SOURCE_BROKER_REF)
                               || !opportunity.LeadSource.equalsIgnoreCase(GlobalConstants.OPP_LEAD_SOURCE_REFERRAL)))
                    && String.isNotBlank(opportunity.Referrer__c)
                    && (!idsByReferrerContactsMap.isEmpty()
                          && idsByReferrerContactsMap.get(opportunity.Referrer__c) != null ?
                                 (String.isNotBlank(idsByReferrerContactsMap.get(opportunity.Referrer__c).Type__c)
                                    && idsByReferrerContactsMap.get(opportunity.Referrer__c)
                                         .Type__c.equalsIgnoreCase(GlobalConstants.CONTACT_TYPE_BROKER)) :
                                 false);
            if ((isLeadSourceBrokerReferral || isLeadSourceSubtypeBrokerReferral || isReferrerTypeBroker)
                    && (oldOpportunitiesMap == null
                        || (opportunity.LeadSource != oldOpportunitiesMap.get(opportunity.Id).LeadSource
                            || opportunity.Referrer__c != oldOpportunitiesMap.get(opportunity.Id).Referrer__c))) {
                opportunity.Broker_Involvement_Indicated__c = GlobalConstants.YES;
            }
        }
    }
}