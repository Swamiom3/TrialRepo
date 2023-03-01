/*************************************************************************************************************************************
    Author      :   Ashish Sharma
    Description :   This trigger updates the campaign fields on lead when campaign type is Splash.
    Issue No.   :   ST-7080
    --------------------------------------------------------------------------------------------------------------------------------------
    VERSION    DATE            AUTHOR            DETAIL
    1          14 Oct, 2020    Ashish Sharma     Initial Deployment
    2          7 Feb, 2022     Pawel Biszczak    Refactor and logic aligned
**************************************************************************************************************************************/
public without sharing class CampaignMemberUpdateSplashLeadsTrH extends SObjectTriggerHandler {
    private final static String SPLASH_EVENT = 'Splash Event';
    @TestVisible
    private List<CampaignMember> newCampaignMembers;
    @TestVisible
    private LeadSelector leadSelector = new LeadSelector();
    @TestVisible
    private CampaignSelector campaignSelector = new CampaignSelector();

    public CampaignMemberUpdateSplashLeadsTrh() {
        this((List<CampaignMember>) Trigger.new);
    }
    
    @TestVisible
    private CampaignMemberUpdateSplashLeadsTrh(List<CampaignMember> newCampaignMembers) {
        this.newCampaignMembers = newCampaignMembers;
    }
    
    public override void afterInsert() {
        updateLeadFromSplashCampaigns();
    }
    
    private void updateLeadFromSplashCampaigns() {
        Map<Id, Lead> leads;
        Map<Id, Lead> leadsToUpdate;
        Map<Id, Campaign> campaigns;
        Set<Id> leadIds = new Set<Id>();
        Set<Id> campaignIds = new Set<Id>();
        
        for(CampaignMember member : newCampaignMembers) {
            if(String.isNotBlank(member.LeadId)) {
                leadIds.add(member.LeadId);
            }
            if(String.isNotBlank(member.CampaignId)) {
                campaignIds.add(member.CampaignId);
            }
        }
        
        leads = new Map<Id, Lead>(getLeads(leadIds));
        campaigns = new Map<Id, Campaign>(getCampaigns(campaignIds));
        if(leads.isEmpty() || campaigns.isEmpty()) {
            return;
        }
        
        leadsToUpdate = new Map<Id, Lead>();
        for(CampaignMember member : newCampaignMembers) {
            Lead queriedLead = leads.get(member.LeadId);
            Campaign queriedCampaign = campaigns.get(member.CampaignId);
            if(queriedLead == null || queriedCampaign == null || queriedCampaign.Type != SPLASH_EVENT) {
                continue;
            }
            setLeadFields(queriedLead, queriedCampaign, leadsToUpdate);
        }
        if(!leadsToUpdate.isEmpty()) {
            update leadsToUpdate.values();
        }
    }
    
    private List<Lead> getLeads(Set<Id> leadIds) {
        if(!leadIds.isEmpty()) {
            return leadSelector.getLeadsById(new List<Id>(leadIds));
        }
        return new List<Lead>();
    }
    
    private List<Campaign> getCampaigns(Set<Id> campaignIds) {
        if(!campaignIds.isEmpty()) {
            return campaignSelector.getCampaignsById(new List<Id>(campaignIds));
        }
        return new List<Campaign>();
    }

    @TestVisible
    private void setLeadFields(Lead queriedLead, Campaign queriedCampaign, Map<Id, Lead> leadsToUpdate) {
        if(!String.isBlank(queriedLead.City) && !String.isBlank(queriedLead.State)) {
            return;
        }
        if(String.isBlank(queriedLead.City)) {
            queriedLead.City = queriedCampaign.City__c;
        }
        if(String.isBlank(queriedLead.State)) {
            queriedLead.State = queriedCampaign.State__c;
        }
        leadsToUpdate.put(queriedLead.Id, queriedLead);
    }
}