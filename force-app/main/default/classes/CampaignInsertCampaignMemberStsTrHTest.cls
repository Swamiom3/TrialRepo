/***********************************************************************************************************************
    Author        :  Krishna Somwanshi
    Description   :  This is a test class for CampaignInsertCampaignMemberStatusTrH
    Issue No.     :  ST-9869
------------------------------------------------------------------------------------------------------------------------
    VERSION        DATE          AUTHOR               DETAIL
      1         09-Dec-2021    Krishna Somwanshi      ST-9869
***********************************************************************************************************************/
@isTest
public class CampaignInsertCampaignMemberStsTrHTest {
    @testSetup
    private static void setup() {
        List<Campaign> campaigns = new List<Campaign>();
        campaigns.add(new Campaign(Name = 'Test Campaign 1', Type = 'Webinar'));
        campaigns.add(new Campaign(Name = 'Test Campaign 2', Type = 'Webinar'));
        TestingUtility.insertListWithAssert(campaigns);
    }
    
    @isTest
    private static void insertCampaignMemberStatus() {
        Test.startTest();
        Set<Id> campaignIds = new Set<Id>();
        List<Campaign> campaigns = [SELECT Id FROM Campaign];
        for(Campaign campaign: campaigns) {
            campaignIds.add(campaign.Id);
        }
        List<CampaignMemberStatus> campaignMemberStatus = [SELECT ID, CampaignId, Label FROM CampaignMemberStatus WHERE CampaignId IN : campaignIds];
        Test.stopTest();
        System.assertEquals(campaignMemberStatus[0].Label, 'Registered', 'CampaignMemberStatus Label should be Registered');
        System.assertEquals(campaignMemberStatus[1].Label, 'Attended: Live', 'CampaignMemberStatus Label should be Attended: Live');
        System.assertEquals(campaignMemberStatus[2].Label, 'Attended: On Demand', 'CampaignMemberStatus Label should be Attended: On Demand');
        System.assertEquals(campaignMemberStatus[3].Label, 'No Show', 'CampaignMemberStatus Label should be No Show');
        System.assertNotEquals(campaignMemberStatus[4].Label, 'Responded', 'CampaignMemberStatus Label should not be Responded');
        System.assertNotEquals(campaignMemberStatus[5].Label, 'Responded', 'CampaignMemberStatus Label should not be Responded');
        System.assertNotEquals(campaignMemberStatus[6].Label, 'Sent', 'CampaignMemberStatus Label should not be Sent');
        System.assertNotEquals(campaignMemberStatus[7].Label, 'Sent', 'CampaignMemberStatus Label should not be Sent');
    }
}