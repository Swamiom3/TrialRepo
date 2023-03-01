/************************************************************************************************************************************
    Author      : Nicholas Zozaya
    Description : This class will handle Referral actions when a new Opportunity is created via Journey conversion or standalone creation.
    History:
----------------------------------------------------------------------------------------------------------------------------------
    VERSION     DATE                AUTHOR                  DETAIL                                                         ISSUE
    1           20 May, 2019        Nicholas Zozaya         Initial Developement                                           ST-3977
    2           5 June, 2019        Nicholas Zozaya         Move lead convert to Referral actions to Opp Insert trigger    ST-3976
    3           25 August, 2020     Oleg Krasko             Trigger redesign                                               ST-6866
**************************************************************************************************************************************/
public with sharing class TrOpportunityInsertReferralActions extends SObjectTriggerHandler{
    @TestVisible
    private List<Opportunity> newOpportunities;
    @TestVisible
    private JourneySelector journeySelector = new JourneySelector();
    @TestVisible
    private ReferralSelector referralSelector = new ReferralSelector();

    public TrOpportunityInsertReferralActions() {
        this((List<Opportunity>) Trigger.new);
    }
    @TestVisible
    private TrOpportunityInsertReferralActions(List<Opportunity> newOpps) {
        newOpportunities = newOpps;
    }

    public override void afterInsert() {
        dispatchOpportunityInsertReferralActions();
    }

    private void dispatchOpportunityInsertReferralActions() {
        List<Opportunity> nonConversionOpps = new List<Opportunity>();
        Map<Id, Referral__c> mapOppIdToReferral = prepareReferralsByOpportunities();
        Map<Id, OpportunityContactRole> mapOppIdToOppContactRole = getOppIdToOppContactRoleMap();
        if (mapOppIdToReferral.isEmpty() && mapOppIdToOppContactRole.isEmpty()) {
            nonConversionOpps = newOpportunities;
        } else {
            nonConversionOpps = handleExistingReferrals(mapOppIdToReferral, mapOppIdToOppContactRole, new Map<Id, Opportunity>(newOpportunities));
        }
        insertNewOppRelatedReferrals(nonConversionOpps);
    }

    private Map<Id, OpportunityContactRole> getOppIdToOppContactRoleMap() {
        Set<Id> oppIds = new Set<Id>();
        for (Opportunity opp : newOpportunities) {
            oppIds.add(opp.Id);
        }
        Map<Id, OpportunityContactRole> mapOppIdToOppContactRole = new Map<Id, OpportunityContactRole>();
        for (OpportunityContactRole ocr : [SELECT Id, ContactId, OpportunityId, Role FROM OpportunityContactRole
                                           WHERE OpportunityId IN: oppIds AND 
                                           Role =:GlobalConstants.OPP_CONTACT_ROLE_AGENCY_BROKER order by CreatedDate desc]) {
                                               //we need latest contact role only
                                               if (!mapOppIdToOppContactRole.containsKey(ocr.OpportunityId))
                                                   mapOppIdToOppContactRole.put(ocr.OpportunityId, ocr);
                                               
                                           }
        return mapOppIdToOppContactRole;
    }

    private Map<Id, Referral__c> prepareReferralsByOpportunities() {
        Map<Id, Referral__c> referralsByOpportunitiesFromContacts = getReferralsByOpportunitiesFromConvertedContacts();
        Map<Id, Referral__c> referralsByOpportunitiesFromJourneys = getReferralsByOpportunitiesFromJourneys();
        if (referralsByOpportunitiesFromContacts.isEmpty() && referralsByOpportunitiesFromJourneys.isEmpty()) {
            return new Map<Id, Referral__c>();
        }
        Map<Id, Referral__c> referralsByOpportunities = new Map<Id, Referral__c>();
        for (Opportunity opportunityRecord : newOpportunities) {
            if (referralsByOpportunitiesFromJourneys.containsKey(opportunityRecord.Id)) {
                referralsByOpportunities.put(opportunityRecord.Id, referralsByOpportunitiesFromJourneys.get(opportunityRecord.Id));
            } else if (referralsByOpportunitiesFromContacts.containsKey(opportunityRecord.Id)) {
                referralsByOpportunities.put(opportunityRecord.Id, referralsByOpportunitiesFromContacts.get(opportunityRecord.Id));
            }
        }
        return referralsByOpportunities;
    }

    private Map<Id, Referral__c> getReferralsByOpportunitiesFromConvertedContacts() {
        Map<Id, Referral__c> mapOppIdToReferral = new Map<Id, Referral__c>();
        Map<Id, Id> mapConvertedLeadIdToContactId = new Map<Id, Id>();
        Map<Id, Referral__c> mapConvertedLeadIdToReferral = new Map<Id, Referral__c>();
        Map<Id, Id> mapPrimaryContactIdToOppId = constructPrimaryContactIdToOppIdMap();
        if (mapPrimaryContactIdToOppId.isEmpty()) {
            return mapOppIdToReferral;
        }
        for (Lead lead : [SELECT Id, ConvertedContactId FROM Lead WHERE (ConvertedContactId IN: mapPrimaryContactIdToOppId.keyset() AND Referral_Expiration_Date__c >= TODAY)]) {
            mapConvertedLeadIdToContactId.put(lead.Id, lead.ConvertedContactId);
        }
        if (mapConvertedLeadIdToContactId.isEmpty()) {
            return mapOppIdToReferral;
        }
        for (Referral__c ref : referralSelector.getReferralsByLeadId(mapConvertedLeadIdToContactId)) {
            mapConvertedLeadIdToReferral.put(ref.Lead__c, ref);
        }
        mapOppIdToReferral = UtilReferral.getOppIdToReferralMap(mapPrimaryContactIdToOppId, mapConvertedLeadIdToContactId,mapConvertedLeadIdToReferral);
        return mapOppIdToReferral;
    }

    private Map<Id, Id> constructPrimaryContactIdToOppIdMap() {
        Map<Id, Id> mapPrimaryContactIdToOppId = new Map<Id, Id>();
        for (Opportunity currentOpp : newOpportunities) {
            if (currentOpp.Primary_Member__c != null) {
                mapPrimaryContactIdToOppId.put(currentOpp.Primary_Member__c, currentOpp.Id);
            }
        }
        return mapPrimaryContactIdToOppId;
    }

    private Map<Id, Referral__c> getReferralsByOpportunitiesFromJourneys() {
        return prepareReferralsFromJourneyByOpportunitiesIds(prepareJourneysToOpportunitiesIds());
    }

    @TestVisible
    private Map<Id, Id> prepareJourneysToOpportunitiesIds() {
        Map<Id, Id> journeyIdsByOpportunitiesIds = new Map<Id, Id>();
        for (Opportunity opportunityRecord : newOpportunities) {
            if (opportunityRecord.Journey__c != null) {
                journeyIdsByOpportunitiesIds.put(opportunityRecord.Id, opportunityRecord.Journey__c);
            }
        }
        return journeyIdsByOpportunitiesIds;
    }

    @TestVisible
    private Map<Id, Referral__c> prepareReferralsFromJourneyByOpportunitiesIds(Map<Id, Id> journeyIdsByOpportunitiesIds) {
        if (journeyIdsByOpportunitiesIds.isEmpty()) {
            return new Map<Id, Referral__c>();
        }
        return prepareReferralsForLeads(prepareOpportunitiesByLeads(journeyIdsByOpportunitiesIds));
    }

    private Map<Id, Id> prepareOpportunitiesByLeads(Map<Id, Id> journeyIdsByOpportunitiesIds) {
        Map<Id, Id> opportunitiesIdsByLeadsIds = new Map<Id, Id>();
        Map<Id, Journey__c> journeysByIds = new Map<Id, Journey__c>(journeySelector.getJourneysWithAdditionalFieldsByIds(journeyIdsByOpportunitiesIds.values()));
        for (Id opportunityId : journeyIdsByOpportunitiesIds.keySet()) {
            Id leadId = journeysByIds.get(journeyIdsByOpportunitiesIds.get(opportunityId)).Lead_Id__c;
            if (leadId != null) {
                opportunitiesIdsByLeadsIds.put(leadId, opportunityId);
            }
        }
        return opportunitiesIdsByLeadsIds;
    }

    private Map<Id, Referral__c> prepareReferralsForLeads(Map<Id, Id> opportunitiesIdsByLeadsIds) {
        if (opportunitiesIdsByLeadsIds.isEmpty()) {
            return new Map<Id, Referral__c>();
        }
        Map<Id, Referral__c> referralsIdsByOpportunitiesIds = new Map<Id, Referral__c>();
        for (Referral__c referralRecord : referralSelector.getReferralsByLeadsIds(new List<Id>(opportunitiesIdsByLeadsIds.keyset()))) {
            referralsIdsByOpportunitiesIds.put(opportunitiesIdsByLeadsIds.get(referralRecord.Lead__c), referralRecord);
        }
        return referralsIdsByOpportunitiesIds;
    }

    @TestVisible
    private List<Opportunity> handleExistingReferrals(Map<Id, Referral__c> mapOppIdToReferral, Map<Id, OpportunityContactRole> mapOppIdToOppContactRole, Map<Id, Opportunity> triggerNewMap) {
        List<Opportunity> nonConversionOpps = new List<Opportunity>();
        List<Referral__c> referralsToUpsert = new List<Referral__c>();
        for (Id opportunityId : mapOppIdToReferral.keyset()) {
            if (!mapOppIdToReferral.containsKey(opportunityId) && !mapOppIdToOppContactRole.containsKey(opportunityId)) {
                continue;
            }
            String contactId = mapOppIdToOppContactRole.containsKey(opportunityId) ? mapOppIdToOppContactRole.get(opportunityId).ContactId : null;
            Referral__c ref = mapOppIdToReferral.containsKey(opportunityId) ? mapOppIdToReferral.get(opportunityId) : new Referral__c();
            referralsToUpsert.add(UtilReferral.getReferralForConversionOpp(triggerNewMap.remove(opportunityId), ref, contactId));
        }
        if (!referralsToUpsert.isEmpty()) {
            //dml.add(referralsToUpsert, DmlConsolidator.Operation.FOR_UPSERT);
            upsert referralsToUpsert;
        }
        if (!triggerNewMap.isEmpty()) {
            nonConversionOpps = triggerNewMap.values();
        }
        return nonConversionOpps;
    }

    private void insertNewOppRelatedReferrals(List<Opportunity> nonConversionOpps) {
        List<Referral__c> oppRelatedReferralsToInsert = new List<Referral__c>();
        Map<Id, OpportunityContactRole> mapOppIdToOppContactRole = getOppIdToOppContactRoleMap();
        for (Opportunity currentOpp : nonConversionOpps) {
            if (currentOpp.Referrer__c == null && mapOppIdToOppContactRole.containsKey(currentOpp.Id)) {
                oppRelatedReferralsToInsert.add(UtilReferral.constructReferral(new Map<String, Object>{'Opportunity__c' => currentOpp.Id, 'Referral_Portal_Event__c' => GlobalConstants.OPP_REFERRAL_PORTAL_EVENT_MANUAL_CREATION, 'Referral_Contact__c' => mapOppIdToOppContactRole.get(currentOpp.Id).ContactId}));
            } else if (currentOpp.Referrer__c != null) {
                oppRelatedReferralsToInsert.add(UtilReferral.constructReferral(new Map<String, Object>{'Opportunity__c' => currentOpp.Id, 'Referral_Portal_Event__c' => GlobalConstants.OPP_REFERRAL_PORTAL_EVENT_MANUAL_CREATION, 'Referrer__c' => currentOpp.Referrer__c, 'Referral_Contact__c' => currentOpp.Primary_Member__c}));
            }
        }
        if (!oppRelatedReferralsToInsert.isEmpty()) {
            dml.add(oppRelatedReferralsToInsert, DmlConsolidator.Operation.FOR_INSERT);
        }
    }
}