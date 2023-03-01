/************************************************************************************************************************************
    Author      :   Salesforce
    Description :   This is a test class for OpportunityRestrictUpdateTrH
   --------------------------------------------------------------------------------------------------------------------------------------
    VERSION     DATE                AUTHOR                  DETAIL
       1        10 May 2022         Salesforce          Initial Developement
 **************************************************************************************************************************************/
@isTest
private with sharing class OpportunityRestrictUpdateTrHTest {

    @testSetup
    static void createTestData() {
        Profile weworkInsideSales = [SELECT Id FROM Profile WHERE Name = 'WeWork Inside Sales'];
        Map<String,Object> userRecordMap = new Map<String,Object>{'LastName' => 'Last Name','Username' => TestingUtility.createStringValue()+'test@test.com','Email' => 'test@test.com'};
        User testUser = TestingUtility.insertUserWithAssert(weworkInsideSales.Id, userRecordMap, true);
        Account createAccount = TestingUtility.createAccount('testAcc1', false);
        insert createAccount;
        Building__c building1 = new Building__c(Name='testbuild-001',Building_ID__c='test111',Time_Zone__c='America/Denver',CurrencyIsoCode='CAD',Country__c='Canada');
        Building__c building2 = new Building__c(Name='testbuild-002',Building_ID__c='test222',Time_Zone__c='America/Denver',CurrencyIsoCode='USD',Country__c='USA');
        insert new List<Building__c>{building1, building2};
        Map<String, Object> opportunityRecordsFieldMappings = new Map<String, Object>{'Interested_in_Number_of_Desks__c' => 2,'Type__c' => 'Wework','CloseDate' => system.today()+10};
        List<Opportunity> opportunityRecords = UtilOpportunity.getNewOpportunityWithFieldMapping(2, createAccount, opportunityRecordsFieldMappings, false);
        Opportunity createOpportunity1 = opportunityRecords.get(0);
        createOpportunity1.Building__c = building1.Id;
        createOpportunity1.OwnerId = testUser.Id;
        Opportunity createOpportunity2 = opportunityRecords.get(1);
        createOpportunity2.Building__c = building2.Id;
        createOpportunity2.OwnerId = testUser.Id;
        insert opportunityRecords;
    }

    @isTest
    static void testPreventOpportunityUpdateAllRegionsEnabled() {
        List<Opportunity> testOldOpportunities = [SELECT Id, CloseDate, Building__c, Regional_Migration_Exemption__c, Number_of_Completed_Tours__c, 
                                                         Number_of_Open_Tours__c, Total_Number_of_Tour__c
                                                  FROM Opportunity 
                                                  WHERE Building__r.Building_ID__c = 'test222' 
                                                  LIMIT 1];
        User testUser = [SELECT Id FROM User WHERE Email = 'test@test.com' ORDER BY CreatedDate DESC LIMIT 1];
        List<Opportunity> testNewOpportunities = new List<Opportunity>{ testOldOpportunities[0].clone(true) };
        testNewOpportunities[0].CloseDate = System.today() + 15;
        OpportunityRestrictUpdateTrH oppRestrictionTrH = new OpportunityRestrictUpdateTrH(testNewOpportunities, new Map<Id, Opportunity>(testOldOpportunities));
        oppRestrictionTrH.setTriggerContext('before update', false);
        oppRestrictionTrH.mtdtUtils = (MetadataUtils) MockService.createMock(
            MetadataUtils.class,
            new Map<String, Object>{
                'getAllRegions' => getMockedActiveRegions()
            }
        );
        Test.startTest();
        System.runAs(testUser){
            oppRestrictionTrH.preventOpportunityUpdate();
            System.assertEquals(System.today() + 15, oppRestrictionTrH.newOpportunities[0].CloseDate, 'Opportunity record not updated successfully');
        }
        Test.stopTest();
    }

    @isTest
    static void testPreventOpportunityUpdateAllRegionsDisabled() {
        List<Opportunity> testOldOpportunities = [SELECT Id, CloseDate, Building__c, Regional_Migration_Exemption__c, Number_of_Completed_Tours__c, 
                                                         Number_of_Open_Tours__c, Total_Number_of_Tour__c
                                                  FROM Opportunity 
                                                  WHERE Building__r.Building_ID__c = 'test222' 
                                                  LIMIT 1];
        User testUser = [SELECT Id FROM User WHERE Email = 'test@test.com' ORDER BY CreatedDate DESC LIMIT 1];
        List<Opportunity> testNewOpportunities = new List<Opportunity>{ testOldOpportunities[0].clone(true) };
        testNewOpportunities[0].CloseDate = System.today() + 15;
        OpportunityRestrictUpdateTrH oppRestrictionTrH = new OpportunityRestrictUpdateTrH(testNewOpportunities, new Map<Id, Opportunity>(testOldOpportunities));
        oppRestrictionTrH.setTriggerContext('before update', false);
        oppRestrictionTrH.mtdtUtils = (MetadataUtils) MockService.createMock(
            MetadataUtils.class,
            new Map<String, Object>{
                'getAllRegions' => getMockedInactiveRegions()
            }
        );
        Test.startTest();
        System.runAs(testUser){
            oppRestrictionTrH.preventOpportunityUpdate();
            System.assert(!oppRestrictionTrH.newOpportunities[0].getErrors().isEmpty(), 'Opportunity record updated successfully');
        }
        Test.stopTest();
    }

    static Map<String, Regional_Migration__mdt> getMockedActiveRegions() {
        return (Map<String, Regional_Migration__mdt>) JSON.deserialize(JSON.serialize(new Map<String, Map<String, Object>> {
                'USA' => new Map<String, Object>{
                    'MasterLabel' => 'USA',
                    'Region_Enabled__c' => true
                },
                'CAD' => new Map<String, Object>{
                    'MasterLabel' => 'Canada',
                    'Region_Enabled__c' => true
                }
        }), Map<String, Regional_Migration__mdt>.class);
    }

    static Map<String, Regional_Migration__mdt> getMockedInactiveRegions() {
        return (Map<String, Regional_Migration__mdt>) JSON.deserialize(JSON.serialize(new Map<String, Map<String, Object>> {
                'USA' => new Map<String, Object>{
                    'MasterLabel' => 'USA',
                    'Region_Enabled__c' => false
                },
                'CAD' => new Map<String, Object>{
                    'MasterLabel' => 'Canada',
                    'Region_Enabled__c' => false
                }
        }), Map<String, Regional_Migration__mdt>.class);
    }
}