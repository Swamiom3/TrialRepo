/***********************************************************************************************************************
    Author        :  Ashish Sharma
    Description   :  This is a test class for CampaignMemberPopulateCampaignTrh.
    Issue No.     :  ST-7080
    History       :
------------------------------------------------------------------------------------------------------------------------
    VERSION        DATE          AUTHOR           DETAIL
      1         14-Oct-2020    Ashish Sharma      ST-7080
***********************************************************************************************************************/
@isTest
public class CampaignMemberPopulateCampaignTrHTest {
    @testSetup
    private static void setup() {
        List<Lead> leadsToInsert = new List<Lead>();
        List<Campaign> campaignsToInsert = new List<Campaign>();
        List<CampaignMember> campaignMembersToInsert = new List<CampaignMember>();
        List<Journey__c> journeysToInsert = new List<Journey__c>();
        Account insertedAcc = TestingUtility.createAccount('testAcc1', true);
        Contact insertedContact = TestingUtility.createContact(insertedAcc.Id, 'testContact1', true);
        Map<String, Object> recordValuesMap = new Map<String, Object> {
            'Email' => 'testLead12@example.com',
            'LastName' => 'testLead1',
            'Phone' => '4526181992'
        };
        leadsToInsert.add(TestingUtility.createLead(recordValuesMap, false));
        TestingUtility.insertListWithAssert(leadsToInsert);
        
        journeysToInsert.add(new Journey__c(Name = leadsToInsert[0].LastName, Primary_Lead__c = leadsToInsert[0].Id, Status__c = 'Known',
                                            Primary_Email__c = leadsToInsert[0].Email, NMD_Next_Contact_Date__c = Date.today()));
        journeysToInsert.add(new Journey__c(Name = insertedContact.LastName, Primary_Contact__c = insertedContact.Id, Status__c = 'Known', 
                                            Primary_Email__c = insertedContact.Email, NMD_Next_Contact_Date__c = Date.today()));
        TestingUtility.insertListWithAssert(journeysToInsert);
        
        campaignsToInsert.add(new Campaign(Name = 'Test Campaign 1', City__c = 'Chicago', State__c = 'IL',
                                           Email_Address__c='campaign1@example.com', Type = 'Splash Event'));
        campaignsToInsert.add(new Campaign(Name = 'Test Campaign 3', State__c = 'DC', City__c = 'Washington DC',
                                           Type = 'Splash Event', Email_Address__c='campaign2@example.com'));
        TestingUtility.insertListWithAssert(campaignsToInsert);
        
        campaignMembersToInsert.add(new CampaignMember(LeadId = leadsToInsert[0].Id, CampaignId = campaignsToInsert[0].Id));
        campaignMembersToInsert.add(new CampaignMember(ContactId = insertedContact.Id, CampaignId = campaignsToInsert[1].Id));
        TestingUtility.insertListWithAssert(campaignMembersToInsert);
    }
    
    @isTest
    private static void verifyPopulateCampaignOnJourney() {
        Test.startTest();
        Map<String, Journey__c> journeys = new Map<String, Journey__c>();
        TestingUtility.createMapOfValues([SELECT CampaignId__c, Primary_Email__c FROM Journey__c],
                                         journeys, 'Primary_Email__c');
        List<Campaign> campaigns = [SELECT Id FROM Campaign];
        Test.stopTest();
        Journey__c journey = journeys.get('testlead12@example.com');
        System.assertEquals(campaigns[0].Id, journey.CampaignId__c, 'Journeys not updated correctly.');
        journey = journeys.get('test@example.com');
        System.assertEquals(campaigns[1].Id, journey.CampaignId__c, 'Journeys not updated correctly.');
    }
}