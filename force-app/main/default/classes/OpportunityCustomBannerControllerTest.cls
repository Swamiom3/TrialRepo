/************************************************************************************************************************************
    Author      :   Salesforce
    Description :   This is a test class for OpportunityCustomBannerController
   ----------------------------------------------------------------------------------------------------------------------------------
    VERSION     DATE                AUTHOR                  DETAIL
       1        10 May 2022         Salesforce          Initial Developement
 **************************************************************************************************************************************/
@isTest
private with sharing class OpportunityCustomBannerControllerTest {

    @testSetup
    static void createTestData() {
        Profile weworkSystemAdmin = [SELECT Id FROM Profile WHERE Name = 'WeWork Inside Sales'];
        Map<String,Object> userRecordMap = new Map<String,Object>{'LastName' => 'Last Name','Username' => TestingUtility.createStringValue()+'test@test.com','Email' => 'test@test.com'};
        User testUser = TestingUtility.insertUserWithAssert(weworkSystemAdmin.Id, userRecordMap, true);
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
    static void test1PositiveEnableOpportunityCustomBanner(){
        Opportunity testOpportunity = [SELECT Id, CloseDate, Building__c FROM Opportunity WHERE Building__r.Building_ID__c = 'test222' LIMIT 1];
        User testUser = [SELECT Id From User WHERE Email = 'test@test.com' LIMIT 1];
        Boolean resultEnableOpportunityCustomBanner = false;
        Test.startTest();
        System.runAs(testUser){
            resultEnableOpportunityCustomBanner = OpportunityCustomBannerController.enableOpportunityCustomBanner(testOpportunity.Id);
        }
        Test.stopTest();
        Boolean regionEnabled = Regional_Migration__mdt.getInstance('USA').Region_Enabled__c;
        System.assertEquals(!regionEnabled, resultEnableOpportunityCustomBanner, 'Custom Banner is displayed on the Opportunity');
    }
    
    @isTest
    static void test2PositiveEnableOpportunityCustomBanner(){
        Opportunity testOpportunity = [SELECT Id, CloseDate, Building__c FROM Opportunity WHERE Building__r.Building_ID__c = 'test222' LIMIT 1];
        Boolean resultEnableOpportunityCustomBanner = false;
        Test.startTest();
        System.runAs(new User(Id = UserInfo.getUserId())){
            resultEnableOpportunityCustomBanner = OpportunityCustomBannerController.enableOpportunityCustomBanner(testOpportunity.Id);
        }
        Test.stopTest();
        Boolean regionEnabled = Regional_Migration__mdt.getInstance('USA').Region_Enabled__c;
        System.assertEquals(!regionEnabled, resultEnableOpportunityCustomBanner, 'Custom Banner is displayed on the Opportunity');
    }
    
    @isTest
    static void test3NegativeEnableOpportunityCustomBanner(){
        Opportunity testOpportunity = [SELECT Id, CloseDate, Building__c FROM Opportunity WHERE Building__r.Building_ID__c = 'test111' LIMIT 1];
        User testUser = [SELECT Id From User WHERE Email = 'test@test.com' LIMIT 1];
        Boolean resultEnableOpportunityCustomBanner = false;
        Test.startTest();
        System.runAs(testUser){
            resultEnableOpportunityCustomBanner = OpportunityCustomBannerController.enableOpportunityCustomBanner(testOpportunity.Id);
        }
        Test.stopTest();
        Boolean regionEnabled = Regional_Migration__mdt.getInstance('CAN').Region_Enabled__c;
        System.assertEquals(!regionEnabled, resultEnableOpportunityCustomBanner, 'Custom Banner will NOT be displayed on the Opportunity');
    }
    
    @isTest
    static void test4NegativeEnableOpportunityCustomBanner(){
        Opportunity testOpportunity = [SELECT Id, CloseDate, Building__c FROM Opportunity WHERE Building__r.Building_ID__c = 'test111' LIMIT 1];
        Boolean resultEnableOpportunityCustomBanner = false;
        Test.startTest();
        System.runAs(new User(Id = UserInfo.getUserId())){
            resultEnableOpportunityCustomBanner = OpportunityCustomBannerController.enableOpportunityCustomBanner(testOpportunity.Id);
        }
        Test.stopTest();
        Boolean regionEnabled = Regional_Migration__mdt.getInstance('CAN').Region_Enabled__c;
        System.assertEquals(!regionEnabled, resultEnableOpportunityCustomBanner, 'Custom Banner will NOT be displayed on the Opportunity');
    }
}