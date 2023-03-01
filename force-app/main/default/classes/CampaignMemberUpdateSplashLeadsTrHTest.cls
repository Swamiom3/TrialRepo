/*************************************************************************************************************************************
    Author      :   Ashish Sharma
    Description :   This is a test class for CampaignMemberUpdateSplashLeadsTrH
    Issue No.   :   ST-7080
    --------------------------------------------------------------------------------------------------------------------------------------
    VERSION    DATE            AUTHOR            DETAIL
    1          14 Oct, 2020    Ashish Sharma     Initial Deployment
    2          7 Feb, 2022     Pawel Biszczak    Refactor
**************************************************************************************************************************************/
@isTest
public class CampaignMemberUpdateSplashLeadsTrHTest {

    @isTest
    private static void verifyUpdateLeadFromSplashCampaignsWithDMls() {
        List<Lead> leadsToInsert = new List<Lead>();
        Map<String, Lead> phonesByLeadsMap = new Map<String, Lead>();
        List<Campaign> campaigns = new List<Campaign>();
        Campaign campaignToAssert;
        List<CampaignMember> campaignMembersToInsert = new List<CampaignMember>();
        Lead leadToAssert;
        List<CampaignMemberStatus> campaignMemberStatusToInsert = new List<CampaignMemberStatus>();

        Account insertedAccount = TestingUtility.createAccount('testAcc1', true);
        TestingUtility.createContact(insertedAccount.Id, 'testContact1', true);
        Map<String, Object> recordValuesMap = new Map<String, Object>{
                'Email' => 'testLead12@example.com',
                'LastName' => 'testLead1',
                'Phone' => '4526181992'
        };
        leadsToInsert.add(TestingUtility.createLead(recordValuesMap, false));
        recordValuesMap = new Map<String, Object>{
                'Email' => 'testLead13@example.com',
                'LastName' => 'testLead2',
                'Phone' => '7478652321'
        };
        leadsToInsert.add(TestingUtility.createLead(recordValuesMap, false));
        recordValuesMap = new Map<String, Object>{
                'Email' => 'testLead14@example.com',
                'LastName' => 'testLead3',
                'Phone' => '7478654343'
        };
        leadsToInsert.add(TestingUtility.createLead(recordValuesMap, false));
        TestingUtility.insertListWithAssert(leadsToInsert);
        campaigns.add(new Campaign(Name = 'Test Campaign 1', City__c = 'Chicago', State__c = 'IL',
                Email_Address__c = 'campaign1@example.com', Type = 'Splash Event'));
        campaigns.add(new Campaign(Name = 'Test Campaign 3', State__c = 'DC', City__c = 'Washington DC',
                Type = 'Splash Event', Email_Address__c = 'campaign2@example.com'));
        campaigns.add(new Campaign(Name = 'Test Campaign 3', State__c = 'MAH', City__c = 'Pune',
                Type = 'Splash Event', Email_Address__c = 'campaign3@example.com'));
        TestingUtility.insertListWithAssert(campaigns);

        campaignMemberStatusToInsert.add(new CampaignMemberStatus(CampaignId = campaigns[1].Id, IsDefault = true,
                HasResponded = true, Label = 'Test', SortOrder = 3));
        campaignMemberStatusToInsert.add(new CampaignMemberStatus(CampaignId = campaigns[2].Id, IsDefault = true,
                HasResponded = true, Label = 'Test', SortOrder = 3));
        TestingUtility.insertListWithAssert(campaignMemberStatusToInsert);


        Test.startTest();
        campaignMembersToInsert.add(new CampaignMember(LeadId = leadsToInsert[0].Id, CampaignId = campaigns[0].Id));
        campaignMembersToInsert.add(new CampaignMember(LeadId = leadsToInsert[1].Id, CampaignId = campaigns[1].Id));
        campaignMembersToInsert.add(new CampaignMember(LeadId = leadsToInsert[2].Id, CampaignId = campaigns[2].Id));
        TestingUtility.insertListWithAssert(campaignMembersToInsert);
        TestingUtility.createMapOfValues([SELECT Id, City, Phone, State FROM Lead],
                phonesByLeadsMap, 'Phone');
        Test.stopTest();


        leadToAssert = phonesByLeadsMap.get('4526181992');
        campaignToAssert = campaigns[0];
        System.assertEquals(campaignToAssert.City__c, leadToAssert.City, 'Lead and Campaign city should be the same.');
        System.assertEquals(campaignToAssert.State__c, leadToAssert.State, 'Lead and Campaign state should be the same.');
        leadToAssert = phonesByLeadsMap.get('7478654343');
        campaignToAssert = campaigns[2];
        System.assertEquals(campaignToAssert.City__c, leadToAssert.City, 'Lead and Campaign city should be the same.');
        System.assertEquals(campaignToAssert.State__c, leadToAssert.State, 'Lead and Campaign State should be the same.');
    }

    @isTest
    private static void shouldUpdateLeadFields() {
        List<Lead> leads = getFakeLeads();
        List<Campaign> campaigns = getFakeCampaigns();
        leads[0].City = 'Washington DC';
        leads[1].State = 'DC';
        campaigns[0].City__c = 'Pune';
        campaigns[0].State__c = 'MAH';
        campaigns[1].City__c = 'NYC';
        campaigns[1].State__c = 'New York';
        campaigns[2].City__c = 'Pune';
        campaigns[2].State__c = 'MAH';
        Map<Id, Lead> leadsToUpdateMap = new Map<Id, Lead>();

        Test.startTest();
        CampaignMemberUpdateSplashLeadsTrH triggerHandlerInstance = new CampaignMemberUpdateSplashLeadsTrH();
        triggerHandlerInstance.setLeadFields(leads[0], campaigns[0], leadsToUpdateMap);
        triggerHandlerInstance.setLeadFields(leads[1], campaigns[1], leadsToUpdateMap);
        triggerHandlerInstance.setLeadFields(leads[2], campaigns[2], leadsToUpdateMap);
        Test.stopTest();

        System.assertEquals(leadsToUpdateMap.values()[0].State, campaigns[0].State__c,
                'Lead and Campaign state should be the same.');
        System.assertEquals(leadsToUpdateMap.values()[1].City, campaigns[1].City__c,
                'Lead and Campaign city should be the same.');
        System.assertEquals(leadsToUpdateMap.values()[2].City, campaigns[2].City__c,
                'Lead and Campaign city should be the same.');
        System.assertEquals(leadsToUpdateMap.values()[2].State, campaigns[2].State__c,
                'Lead and Campaign state should be the same.');
    }

    @isTest
    private static void shouldNotUpdateLeadFields() {
        List<Lead> leads = getFakeLeads();
        List<Campaign> campaigns = getFakeCampaigns();
        leads[0].City = 'Chicago';
        leads[0].State = 'IL';
        leads[1].City = 'Washington DC';
        leads[1].State = 'DC';
        leads[2].City = 'Washington DC';
        leads[2].State = 'DC';
        campaigns[1].City__c = 'Chicago';
        campaigns[1].State__c = 'IL';
        campaigns[2].City__c = 'Chicago';
        campaigns[2].State__c = 'IL';
        Map<Id, Lead> leadsToUpdateMap = new Map<Id, Lead>();

        Test.startTest();
        CampaignMemberUpdateSplashLeadsTrH triggerHandlerInstance = new CampaignMemberUpdateSplashLeadsTrH();
        triggerHandlerInstance.setLeadFields(leads[0], campaigns[0], leadsToUpdateMap);
        triggerHandlerInstance.setLeadFields(leads[2], campaigns[2], leadsToUpdateMap);
        Test.stopTest();

        System.assert(leadsToUpdateMap.isEmpty(), 'Should contain no records to update');
    }

    static List<Lead> getFakeLeads() {
        Map<String, Object> recordsData = new Map<String, Object>();
        recordsData = new Map<String, Object>();
        recordsData.put('objectName', 'Lead');
        recordsData.put('numberOfRecords', 3);
        return MockTestingUtility.getRecords(recordsData, true);
    }

    static List<Campaign> getFakeCampaigns() {
        Map<String, Object> recordsData = new Map<String, Object>();
        recordsData = new Map<String, Object>();
        recordsData.put('objectName', 'Campaign');
        recordsData.put('numberOfRecords', 3);
        return MockTestingUtility.getRecords(recordsData, true);
    }
}