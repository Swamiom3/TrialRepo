/***********************************************************************************************************************
    Author        :  Krishna Somwanshi
    Description   :  This trigger updates campaign member status creation and deletion if the campaign type is Webinar
    Issue No.     :  ST-9869
------------------------------------------------------------------------------------------------------------------------
    VERSION        DATE          AUTHOR               DETAIL
      1         08-Dec-2021    Krishna Somwanshi      ST-9869
***********************************************************************************************************************/
public without sharing class CampaignInsertCampaignMemberStatusTrH extends SObjectTriggerHandler {

    @TestVisible
    private List<Campaign> newCampaigns;
    @TestVisible
    private CampaignMemberStatusSelector campaignMemberStatusSelector = new CampaignMemberStatusSelector();
    public static final String CAMPAIGN_TYPE_WEBINAR = 'Webinar';
    public static final String CAMPAIGNMEMBERSTATUS_LABEL_REGISTERED = 'Registered';
    public static final String CAMPAIGNMEMBERSTATUS_LABEL_ATTENDED_LIVE = 'Attended: Live';
    public static final String CAMPAIGNMEMBERSTATUS_LABEL_ATTENDED_ON_DEMAND = 'Attended: On Demand';
    public static final String CAMPAIGNMEMBERSTATUS_LABEL_NO_SHOW = 'No Show';
    public static final String CAMPAIGNMEMBERSTATUS_LABEL_SENT = 'Sent';
    public static final String CAMPAIGNMEMBERSTATUS_LABEL_RESPENDED = 'Responded';
    
    public CampaignInsertCampaignMemberStatusTrH() {
        this((List<Campaign>) Trigger.new);        
    }
    
    @TestVisible
    private CampaignInsertCampaignMemberStatusTrH(List<Campaign> newCampaigns) {
        this.newCampaigns = newCampaigns;
    }
    
    public override void afterInsert() {
        insertCampaignMemberStatus();
    }
    
    private void insertCampaignMemberStatus() {
        Set<Id> campaignIds = new Set<Id>();
        List<CampaignMemberStatus> campaignMemberStatusToInsert = new List<CampaignMemberStatus>();
        for(Campaign campaign: newCampaigns) {
            if(campaign.Type == CAMPAIGN_TYPE_WEBINAR){ 
                campaignMemberStatusToInsert.add(new CampaignMemberStatus(CampaignId=campaign.Id, IsDefault=true, Label=CAMPAIGNMEMBERSTATUS_LABEL_REGISTERED)); 
                campaignMemberStatusToInsert.add(new CampaignMemberStatus(CampaignId=campaign.Id, HasResponded=true, Label=CAMPAIGNMEMBERSTATUS_LABEL_ATTENDED_LIVE)); 
                campaignMemberStatusToInsert.add(new CampaignMemberStatus(CampaignId=campaign.Id, HasResponded=true, Label=CAMPAIGNMEMBERSTATUS_LABEL_ATTENDED_ON_DEMAND)); 
                campaignMemberStatusToInsert.add(new CampaignMemberStatus(CampaignId=campaign.Id, Label=CAMPAIGNMEMBERSTATUS_LABEL_NO_SHOW));  
                campaignIds.add(campaign.Id); 
            }
        }
        insert campaignMemberStatusToInsert;
        List<CampaignMemberStatus> campaignMemberStatusToDelete = new List<CampaignMemberStatus>();
        for(CampaignMemberStatus campaignMemberStatus : campaignMemberStatusSelector.getCampaignMemberStatusById(new List<Id>(campaignIds))){
            if(campaignMemberStatus.Label == CAMPAIGNMEMBERSTATUS_LABEL_RESPENDED) { 
                campaignMemberStatusToDelete.add(campaignMemberStatus);
            }
            if(campaignMemberStatus.Label == CAMPAIGNMEMBERSTATUS_LABEL_SENT){ 
                campaignMemberStatusToDelete.add(campaignMemberStatus);
            }
        }
        delete campaignMemberStatusToDelete;
    }
}