/***********************************************************************************************************************
    Author        :  Ashish Sharma
    Description   :  This trigger updates CampaignId field on related Journey record.
    Issue No.     :  ST-7080
    History       :
------------------------------------------------------------------------------------------------------------------------
    VERSION        DATE          AUTHOR           DETAIL
      1         14-Oct-2020    Ashish Sharma      ST-7080
***********************************************************************************************************************/
public without sharing class CampaignMemberPopulateCampaignTrH extends SObjectTriggerHandler {
    @TestVisible
    private List<CampaignMember> newCampaignMembers;
    @TestVisible
    private JourneySelector journeySelector = new JourneySelector();
    
    public CampaignMemberPopulateCampaignTrh() {
        this((List<CampaignMember>) Trigger.new);        
    }
    
    @TestVisible
    private CampaignMemberPopulateCampaignTrh(List<CampaignMember> newCampaignMembers) {
        this.newCampaignMembers = newCampaignMembers;
    }
    
    public override void afterInsert() {        
        populateCampaignOnJourney();
    }
    
    public override void afterUpdate() {        
        populateCampaignOnJourney();
    }
    
    private void populateCampaignOnJourney() {
        List<Journey__c> journeysToUpdate;
        Map<Id, Id> contactOrLeadToCampaign = new Map<Id, Id>();        
        for(CampaignMember newCampaignMember : newCampaignMembers) {
            if(newCampaignMember.ContactId != null) {
                contactOrLeadToCampaign.put(newCampaignMember.ContactId, newCampaignMember.CampaignId);
            }
            if(newCampaignMember.LeadId != null) {
                contactOrLeadToCampaign.put(newCampaignMember.LeadId, newCampaignMember.CampaignId);
            }
        }
        if(contactOrLeadToCampaign.isEmpty()) {
            return;
        }
        journeysToUpdate = journeySelector.getJourneysByLeadOrContactPresent(new List<Id>(contactOrLeadToCampaign.keySet()));
        for(Journey__c journey : journeysToUpdate) {
            if(contactOrLeadToCampaign.containsKey(journey.Primary_Contact__c)) {
                journey.CampaignId__c = contactOrLeadToCampaign.get(journey.Primary_Contact__c);
            } else if(contactOrLeadToCampaign.containsKey(journey.Primary_Lead__c)) {
                journey.CampaignId__c = contactOrLeadToCampaign.get(journey.Primary_Lead__c);
            }
        }
        if(!journeysToUpdate.isEmpty()) {
            update journeysToUpdate;
        }
    }
}