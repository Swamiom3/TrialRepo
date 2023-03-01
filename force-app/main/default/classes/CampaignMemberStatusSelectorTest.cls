/*************************************************************************************************************************************
    Author      :   Krishna Somwanshi
    Description :   This class sufficient test coverage for PortfolioSelector class
--------------------------------------------------------------------------------------------------------------------------------------
    VERSION         DATE            AUTHOR              DETAIL
    1               30/8/2021       Krishna Somwanshi   Initial Deployment
**************************************************************************************************************************************/
@isTest
public class CampaignMemberStatusSelectorTest {
    @testSetup
    private static void setup() {
        MetadataDrivenTriggerHandler.disableExecution();
        Campaign campaign = new Campaign(Name = 'Test Campaign', IsActive = True, Type = 'Webinar', Status = 'Planned');
        insert campaign;
        CampaignMemberStatus cStatus = new CampaignMemberStatus(CampaignId = campaign.Id, IsDefault = true, Label = 'Registered');
        insert cStatus;
    }
    @isTest
    public static void getCampaignMemberStatusByIdTest(){
        Campaign campaign = [SELECT Id FROM Campaign LIMIT 1];
        CampaignMemberStatusSelector campaignMemberStatusSelector = new CampaignMemberStatusSelector();
        System.assert(!campaignMemberStatusSelector.getCampaignMemberStatusById(new List<Id>{campaign.Id}).isEmpty(), 'List should not be empty');
    }
}