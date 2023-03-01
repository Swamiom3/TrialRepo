/*************************************************************************************************************************************
    Author      :    Pawel Biszczak
    Description :    This class provides sufficient test coverage for CampaignSelector class
    --------------------------------------------------------------------------------------------------------------------------------------
    VERSION    DATE           AUTHOR            DETAIL
    1          4 Feb, 2022    Pawel Biszczak    Initial Deployment
**************************************************************************************************************************************/
@isTest
public with sharing class CampaignSelectorTest {
    private static CampaignSelector campaignSelector = new CampaignSelector();

    @testSetup
    static void makeData(){
        Map<String, Object> recordsData = new Map<String, Object>();
        recordsData = new Map<String, Object>();
        recordsData.put('objName', 'Campaign');
        recordsData.put('numberOfRecords', 2);
        recordsData.put('doInsert', true);
        TestingUtility.getRecords(recordsData);
    }

    @isTest
    static void shouldGetDefaultFields(){
        Set<String> fields;

        Test.startTest();
        fields = campaignSelector.getDefaultFields();
        Test.stopTest();

        System.assert(!fields.isEmpty(), 'Default fields should be presented');
    }

    @isTest
    static void shouldGetCampaignsByIds(){
        List<Campaign> campaigns;
        Set<Id> campaignIds = new Map <Id, Campaign> ([ SELECT Id
                                                        FROM Campaign ]).keySet();

        Test.startTest();
        campaigns = campaignSelector.getCampaignsById(new List<Id>(campaignIds));
        Test.stopTest();

        System.assertEquals(2, campaigns.size(), 'Should get 2 campaigns');
        System.assertNotEquals(campaigns[0].Region__c, null, 'Region__c field\'s value should be retrieved properly');
    }

}