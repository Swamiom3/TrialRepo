/*************************************************************************************************************************************
Author      :   Pawel Biszczak
Description :   This class provides sufficient test coverage for MetadataUtils class
--------------------------------------------------------------------------------------------------------------------------------------
VERSION         DATE            AUTHOR              DETAIL
1               26 Apr, 2021    Pawel Biszczak      Initial Deployment
**************************************************************************************************************************************/
@isTest
public with sharing class MetadataUtilsTest {

    @isTest
    public static void shouldReturnMetadataRecordsByDeveloperNameForOpportunityStage() {
        List<OpportunityStagesSetting__mdt> opportunityStagesSettings;

        Test.startTest();
        opportunityStagesSettings = MetadataUtils.getRecordsByDeveloperName('OpportunityStagesSetting__mdt', 'AllowedStagesForOppProduct');
        Test.stopTest();

        System.assertEquals('AllowedStagesForOppProduct', opportunityStagesSettings.get(0).Label, 'Label name should be equal');
        System.assert(String.isNotBlank(opportunityStagesSettings.get(0).Stages__c), 'Should get stages for opportunities');
    }

    @isTest
    public static void shouldReturnMetadataRecordsByDeveloperNameForOpportunityProduct() {
        List<OpportunityProductCode__mdt> opportunityStagesSettings;

        Test.startTest();
        opportunityStagesSettings = MetadataUtils.getRecordsByDeveloperName('OpportunityProductCode__mdt', 'WeWork');
        Test.stopTest();

        System.assertEquals('WeWork', opportunityStagesSettings.get(0).Label, 'Label name should be equal');
    }

    @isTest
    public static void shouldReturnAllMetadataRecordsForOpportunityStagesSetting() {
        List<OpportunityStagesSetting__mdt> opportunityStagesSettings;

        Test.startTest();
        opportunityStagesSettings = MetadataUtils.getAllRecords('OpportunityStagesSetting__mdt');
        Test.stopTest();

        System.assert(!opportunityStagesSettings.isEmpty(), 'Should get stages records');
    }

    @isTest
    public static void shouldReturnAllMetadataRecordsForOpportunityProduct() {
        List<OpportunityProductCode__mdt> opportunityStagesSettings;

        Test.startTest();
        opportunityStagesSettings = MetadataUtils.getAllRecords('OpportunityProductCode__mdt');
        Test.stopTest();

        System.assert(!opportunityStagesSettings.isEmpty(), 'Should get stages records');
    }

    @isTest
    public static void shouldReturnEmptyListForFakeDeveloperName() {
        List<OpportunityStagesSetting__mdt> opportunityStagesSettings;

        Test.startTest();
        opportunityStagesSettings = MetadataUtils.getRecordsByDeveloperName('FakeObjectToTestName__mdt', 'FakeDeveloperName');
        Test.stopTest();

        System.assert(opportunityStagesSettings.isEmpty(), 'Records list should be empty');
    }

}