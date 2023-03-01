/************************************************************************************************************************************
    Author      :   Liubomyr Mishchykha	
    Description :   Trigger handler class for opportunities' child referrals based on fields modified on Opportunity.
                    Created during trigger redesign (ST-6867)
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION     DATE                AUTHOR                  DETAIL
    1           Sep 9, 2020         Liubomyr Mishchykha     Initial version
    2           Okt 20, 2021        Oleksandr Liesnik       ST-9265/Refactoring
**************************************************************************************************************************************/
public with sharing class OpportunityUpdateReferralActionsTrH extends SObjectTriggerHandler {

    private final String OPP_CLOSED_LOST_REFERRAL_EVENT = 'Opportunity Closed Lost';
    private final String OPP_REOPENED_REFERRAL_EVENT = 'Opportunity Re-opened';
    private final String OPP_PAPERWORK_SIGNED_REFERRAL_EVENT = 'Paperwork signed';
    private final String CONTRACT_STAGE_SENT = 'Contract Sent';
    private final String REFERRAL_PORTAL_EVENT_PAPERWORK_SENT = 'Paperwork Sent';
    private final String REFERRAL_PORTAL_EVENT_REFERRER_UPDATED = 'Referrer Updated';

    @TestVisible
    private OpportunitySelector oppSelector = new OpportunitySelector();
    @TestVisible
    private OpportunityContactRoleSelector oppContactRoleSelector = new OpportunityContactRoleSelector();
    @TestVisible
    private List<Opportunity> newOpportunities;
    @TestVisible
    private Map<Id, Opportunity> oldOpportunitiesMap;
    private Map<Id, List<Referral__c>> opportunityIdsToExistingChildReferrals;
    private Map<Id, List<Referral__c>> inProgressOppIdToUpsertReferrals;

    public OpportunityUpdateReferralActionsTrH() {
        this((List<Opportunity>) Trigger.new, (Map<Id, Opportunity>) Trigger.oldMap);
    }

    @TestVisible
    private OpportunityUpdateReferralActionsTrH(List<Opportunity> newOpportunities, Map<Id, Opportunity> oldOpportunitiesMap) {
        this.newOpportunities = newOpportunities;
        this.oldOpportunitiesMap = oldOpportunitiesMap;
        this.inProgressOppIdToUpsertReferrals = new Map<Id, List<Referral__c>>();
    }

    public override void afterUpdate() {
        setOpportunityReferralEvent();
    }

    @Testvisible
    private void setOpportunityReferralEvent() {
        List<Referral__c> referralsToUpsert = getReferralsToUpsert();
        if (referralsToUpsert != null && !referralsToUpsert.isEmpty()) {
            dml.add(referralsToUpsert, DmlConsolidator.Operation.FOR_UPSERT);
        }
    }

    @TestVisible
    private List<Referral__c> getReferralsToUpsert() {
        this.opportunityIdsToExistingChildReferrals = getOpportunityReferrals();
        return dispatchReferralActions(mapChangeEventsToOpportunities(), getOppIdToOppContactRoleMap());
    }

    private Map<ChangeEvents, Map<Id, Opportunity>> mapChangeEventsToOpportunities() {
        Map<ChangeEvents, Map<Id, Opportunity>> changeEventsToOpps = new Map<ChangeEvents, Map<Id, Opportunity>>{
            ChangeEvents.REFERRER_CHANGE => new Map<Id, Opportunity>(),
            ChangeEvents.STAGE_CHANGE => new Map<Id, Opportunity>(),
            ChangeEvents.BUILDING_CHANGE => new Map<Id, Opportunity>(),
            ChangeEvents.CONTRACT_STAGE_CHANGE => new Map<Id, Opportunity>(),
            ChangeEvents.REFERRER_EMPTY_RECORD_UPDATED => new Map<Id, Opportunity>()
        };
        for (Opportunity newOpp : newOpportunities) {
            Opportunity oldOpp = oldOpportunitiesMap.get(newOpp.Id);
            if (TriggerUtility.isFieldValueChanged(newOpp, oldOpp, 'Referrer__c')) {
                changeEventsToOpps.get(ChangeEvents.REFERRER_CHANGE).put(newOpp.Id, newOpp);
            } else if(newOpp.Referrer__c == null && oldOpp.Referrer__c == null){
                changeEventsToOpps.get(ChangeEvents.REFERRER_EMPTY_RECORD_UPDATED).put(newOpp.Id, newOpp);
            }
            if (TriggerUtility.isFieldValueChanged(newOpp, oldOpp, 'StageName')) {
                changeEventsToOpps.get(ChangeEvents.STAGE_CHANGE).put(newOpp.Id, newOpp);
            }
            if (TriggerUtility.isFieldValueChanged(newOpp, oldOpp, 'Building__c')) {
                changeEventsToOpps.get(ChangeEvents.BUILDING_CHANGE).put(newOpp.Id, newOpp);
            }
            if (TriggerUtility.isFieldValueChanged(newOpp, oldOpp, 'Contract_Stage__c')) {
                changeEventsToOpps.get(ChangeEvents.CONTRACT_STAGE_CHANGE).put(newOpp.Id, newOpp);
            }
        }
        return changeEventsToOpps;
    }
    
    private Map<Id, OpportunityContactRole> getOppIdToOppContactRoleMap() {
        Set<Id> oppIds = (new Map<Id,Opportunity>(newOpportunities)).keySet();
        Map<Id, OpportunityContactRole> mapOppIdToOppContactRole = new Map<Id, OpportunityContactRole>();
        for (OpportunityContactRole ocr: oppContactRoleSelector.getOpportunityContactRolesByOppIdsAndRole(oppIds,
                                                                                                        GlobalConstants.OPP_CONTACT_ROLE_AGENCY_BROKER)){
            if(!mapOppIdToOppContactRole.containsKey(ocr.OpportunityId)) {
                mapOppIdToOppContactRole.put(ocr.OpportunityId, ocr);
            }
        }
        return mapOppIdToOppContactRole;
    }

    private Map<Id, List<Referral__c>> getOpportunityReferrals() {
        Map<Id, List<Referral__c>> opportunityIdsToExistingChildReferrals = new Map<Id, List<Referral__c>>();
        for (Opportunity opp : oppSelector.getOppsWithRelatedReferrals(oldOpportunitiesMap.keyset())) {
            if (!opp.Referrals__r.isEmpty()) {
                opportunityIdsToExistingChildReferrals.put(opp.Id, opp.Referrals__r);
            }
        }
        return opportunityIdsToExistingChildReferrals;
    }

    private List<Referral__c> dispatchReferralActions(Map<ChangeEvents, Map<Id, Opportunity>> mapChangeEventToOpp, Map<Id, OpportunityContactRole> oppIdToOCR) {
        for (ChangeEvents changeEvent : mapChangeEventToOpp.keyset()) {
            Map<Id, Opportunity> currentChangeEventOppMap = mapChangeEventToOpp.get(changeEvent);
            switch on changeEvent {
                when REFERRER_CHANGE {
                    inProgressOppIdToUpsertReferrals.putAll(handleReferrerUpdated(currentChangeEventOppMap, oppIdToOCR));
                }
                when STAGE_CHANGE {
                    inProgressOppIdToUpsertReferrals.putAll(handleStageUpdated(currentChangeEventOppMap));
                }
                when BUILDING_CHANGE {
                    inProgressOppIdToUpsertReferrals.putAll(handleBuildingUpdated(currentChangeEventOppMap));
                }
                when CONTRACT_STAGE_CHANGE {
                    inProgressOppIdToUpsertReferrals.putAll(handleContractStageUpdated(currentChangeEventOppMap));
                }
                when REFERRER_EMPTY_RECORD_UPDATED {
                    inProgressOppIdToUpsertReferrals.putAll(handleOpportunityWithoutReferrerUpdated(currentChangeEventOppMap,oppIdToOCR));
                }
            }
        }
        List<Referral__c> allRefs = new List<Referral__c>();
        if (inProgressOppIdToUpsertReferrals.values().isEmpty()) {
            return allRefs;
        }
        for (List<Referral__c> listOfReffs : inProgressOppIdToUpsertReferrals.values()) {
            allRefs.addAll(listOfReffs);
        }
        return allRefs;
    }

    private Map<Id, List<Referral__c>> handleReferrerUpdated(Map<Id, Opportunity> currentChangeEventOppMap, Map<Id, OpportunityContactRole> oppIdToOCR) {
        for (Id oppId : currentChangeEventOppMap.keyset()) {
            Opportunity currentOpp = currentChangeEventOppMap.get(oppId);
            Referral__c oppRelatedReferral;
            List<Referral__c> oppRelatedRefs = new List<Referral__c>();
            if (oldOpportunitiesMap.get(oppId).Referrer__c == null && !opportunityIdsToExistingChildReferrals.containsKey(oppId)) {
                String referralPortalEvent = currentOpp.StageName == GlobalConstants.OPP_CLOSED_WON_STAGE_NAME ? 'Post-Opportunity Closed Won' : 'Opportunity Associated';
                oppRelatedReferral = UtilReferral.constructReferral(new Map<String, Object>{
                                                                        'Opportunity__c' => oppId,
                                                                        'Building_Interested_In__c' => currentOpp.Building__c,
                                                                        'Referrer__c' => currentOpp.Referrer__c,
                                                                        'Referral_Contact__c' => currentOpp.Primary_Member__c,
                                                                        'Referral_Portal_Event__c' => referralPortalEvent});
                oppRelatedRefs.add(oppRelatedReferral);
                if (oppIdToOCR.containsKey(oppId)) {
                    oppRelatedReferral.Agency_Broker_Company__c = oppIdToOCR.get(oppId).Contact?.Company__c;
                    oppRelatedReferral.Agency_Broker_Email__c = oppIdToOCR.get(oppId).Contact.Email;
                    oppRelatedReferral.Agency_Broker_Name__c = oppIdToOCR.get(oppId).Contact.Name;
                    oppRelatedReferral.Agency_Broker_Role__c = oppIdToOCR.get(oppId).Role;
                }
            } else if (opportunityIdsToExistingChildReferrals.containsKey(oppId)) {
                oppRelatedRefs.addAll(opportunityIdsToExistingChildReferrals.get(oppId));
                for (Referral__c oopRef : oppRelatedRefs) {
                    oopRef.Referrer__c = currentOpp.Referrer__c;
                    oopRef.Referral_Portal_Event__c = REFERRAL_PORTAL_EVENT_REFERRER_UPDATED;
                    if (oppIdToOCR.containsKey(currentOpp.Id)) {
                        oopRef.Agency_Broker_Company__c = oppIdToOCR.get(currentOpp.Id).Contact?.Company__c;
                        oopRef.Agency_Broker_Email__c = oppIdToOCR.get(currentOpp.Id)?.Contact?.Email;
                        oopRef.Agency_Broker_Name__c = oppIdToOCR.get(currentOpp.Id)?.Contact?.Name;
                        oopRef.Agency_Broker_Role__c = oppIdToOCR.get(currentOpp.Id)?.Role;
                    }
                }
            }
            if (!oppRelatedRefs.isEmpty()) {
                inProgressOppIdToUpsertReferrals.put(oppId, oppRelatedRefs);
            }
        }
        return inProgressOppIdToUpsertReferrals;
    }

    private Map<Id, List<Referral__c>> handleStageUpdated(Map<Id, Opportunity> currentChangeEventOppMap) {
        List<Referral__c> referralsToUpdate = getInProgressReferrals(currentChangeEventOppMap);
        for (Referral__c ref : referralsToUpdate) {
            String newOppStageName = currentChangeEventOppMap.get(ref.Opportunity__c).StageName;
            String oldOppStageName = (String) oldOpportunitiesMap.get(ref.Opportunity__c).get('StageName');
            if (newOppStageName == GlobalConstants.OPP_CLOSED_LOST_STAGE_NAME || (oldOppStageName == GlobalConstants.OPP_CLOSED_WON_STAGE_NAME || oldOppStageName == GlobalConstants.OPP_CLOSED_LOST_STAGE_NAME)) {
                ref.Referral_Portal_Event__c = getReferralEventFromStage(newOppStageName);
                addInProgressRefs(ref);
            }
        }
        return inProgressOppIdToUpsertReferrals;
    }
    
    private Map<Id, List<Referral__c>> handleOpportunityWithoutReferrerUpdated(Map<Id, Opportunity> currentChangeEventOppMap, Map<Id, OpportunityContactRole> oppIdToOCR) {           
        List<Referral__c> referralsToUpdate = getInProgressReferrals(currentChangeEventOppMap);        
            for(Opportunity opp : newOpportunities){
                Opportunity oldOpp = oldOpportunitiesMap.get(opp.Id);                
                if(opp.Referrer__c == null && oldOpp.Referrer__c == null && oppIdToOCR.containsKey(opp.Id)
                  && !opportunityIdsToExistingChildReferrals.containsKey(opp.Id)){
                    OpportunityContactRole oppConRole = oppIdToOCR.get(opp.Id);
                    Map<String,Object> recordValuesMap = new Map<String,Object>();
                    recordValuesMap.put('Opportunity__c',oppConRole.OpportunityId);
                    recordValuesMap.put('Referrer__c',oppConRole.ContactId);
                    recordValuesMap.put('Referral_Portal_Event__c','Manual Opportunity Creation');
                    recordValuesMap.put('Referral_Contact__c',opp.Primary_Member__c);
                    Referral__c referral=UtilReferral.constructReferral(recordValuesMap);
                    addInProgressRefs(referral);
                }
            }
        return inProgressOppIdToUpsertReferrals;
    }

    private String getReferralEventFromStage(String oppStageName) {
        return oppStageName == GlobalConstants.OPP_CLOSED_WON_STAGE_NAME
                                ? OPP_PAPERWORK_SIGNED_REFERRAL_EVENT
                                : oppStageName == GlobalConstants.OPP_CLOSED_LOST_STAGE_NAME
                                    ? OPP_CLOSED_LOST_REFERRAL_EVENT : OPP_REOPENED_REFERRAL_EVENT;
    }

    private Map<Id, List<Referral__c>> handleBuildingUpdated(Map<Id, Opportunity> currentChangeEventOppMap) {
        List<Referral__c> referralsToUpdate = getInProgressReferrals(currentChangeEventOppMap);
        for (Referral__c ref : referralsToUpdate) {
            ref.Building_Interested_In__c = currentChangeEventOppMap.get(ref.Opportunity__c).Building__c;
            addInProgressRefs(ref);
        }
        return inProgressOppIdToUpsertReferrals;
    }

    private Map<Id, List<Referral__c>> handleContractStageUpdated(Map<Id, Opportunity> currentChangeEventOppMap) {
        List<Referral__c> referralsToUpdate = getInProgressReferrals(currentChangeEventOppMap);
        for (Referral__c ref : referralsToUpdate) {
            if (currentChangeEventOppMap.get(ref.Opportunity__c).Contract_Stage__c != CONTRACT_STAGE_SENT) {
                continue;
            }
            ref.Referral_Portal_Event__c = REFERRAL_PORTAL_EVENT_PAPERWORK_SENT;
            addInProgressRefs(ref);
        }
        return inProgressOppIdToUpsertReferrals;
    }

    private void addInProgressRefs (Referral__c refToUpdate){
        if (inProgressOppIdToUpsertReferrals.containsKey(refToUpdate.Opportunity__c)) {
            inProgressOppIdToUpsertReferrals.get(refToUpdate.Opportunity__c).add(refToUpdate);
        } else {
            inProgressOppIdToUpsertReferrals.put(refToUpdate.Opportunity__c, new List<Referral__c> {refToUpdate});
        }
    }

    private List<Referral__c> getInProgressReferrals(Map<Id, Opportunity> currentChangeEventOppMap) {
        List<Referral__c> referralsToUpdate = new List<Referral__c>();
        for (Id oppId : currentChangeEventOppMap.keyset()) {
            List<Referral__c> oppRelatedReferrals = checkOppUpdateEligibility(oppId)
                                                        ? opportunityIdsToExistingChildReferrals.get(oppId)
                                                        : inProgressOppIdToUpsertReferrals.get(oppId);
            if (oppRelatedReferrals != null) {
                referralsToUpdate.addAll(oppRelatedReferrals);
            }
        }
        return referralsToUpdate;
    }

    private Boolean checkOppUpdateEligibility(Id oppId) {
        return (inProgressOppIdToUpsertReferrals.isEmpty() || !inProgressOppIdToUpsertReferrals.containsKey(oppId)) &&
                !opportunityIdsToExistingChildReferrals.isEmpty() && opportunityIdsToExistingChildReferrals.containsKey(oppId);    
    }

    public enum ChangeEvents{REFERRER_CHANGE, STAGE_CHANGE, BUILDING_CHANGE, CONTRACT_STAGE_CHANGE, REFERRER_EMPTY_RECORD_UPDATED}
}