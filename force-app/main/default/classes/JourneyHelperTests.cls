/*****************************************************************************************************************************
  Yet to do
  1. Modularize the code into multiple method calls.
  2. Put comments for each method call to establish references.
  3. Get it reviewed from the peer team.
******************************************************************************************************************************
    Author      :  Krishana Tupe  
    Description :  This class contains the test methods of JourneyHelper class.
					To cover JourneyHelperUtility and JourneyHelper class,Please run LeadRoutingHelperTest.

    History     :  --
    
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION                 DATE            ISSUE       AUTHOR                          DETAIL
    1                       30 Nov 2018      -     		Krishana Tupe                   Initial Developement    
******************************************************************************************************************************/
@isTest
public class JourneyHelperTests {

    /************************************************************************************************************************************
          Author              :   Krishana Tupe
          Description         :   This setup method is used to create test data for JourneyHelperTests class
            Created Date  		:   27 Nov 2018
   *************************************************************************************************************************************/
    @TestSetup
    public static void testSetup(){
        Lead leadRecord = new Lead(
                OwnerId = Settings.getValidationRuleRestrictionSalesforceId('Susie_Romero_API_User'),
                FirstName ='John',
                LastName='Smith',
                Email='john.smith1116@example.com',
                Company='Example',
                LeadSource='WeWork.com',
                Lead_Source_Detail__c='Book a Tour Form',
                Locations_Interested__c='Test Building Tour',
                Generate_Journey__c=true,
                Personal_Mailing_Street__c='Pimpri',
                Personal_Mailing_City__c='Pune',
                Personal_Mailing_PostalCode__c='411017',
                Personal_Mailing_Country__c='India',
                Personal_Mailing_State__c='Maharashtra',
                Promo_Code__c='Jet Blue'
        );

        TestingUtility.insertWithAssert(leadRecord);
    }

    @isTest
    static void getDateTimeValueTest() {
        Test.startTest();
        DateTime actual  = JourneyHelper.getDateTimeValue(Datetime.newInstanceGMT(2020,2,10));
        Test.stopTest();

        System.assertEquals(Datetime.newInstanceGMT(2020,1,1), actual, 'time should be the same');
    }

    @isTest
    static void getDecimalValueTest() {
        Decimal expected = 10.0;

        Test.startTest();
        Decimal actual  = JourneyHelper.getDecimalValue(expected);
        Test.stopTest();

        System.assertEquals(expected, actual, 'decimal value should be the same');
    }

    @isTest
    static void getStringValueTest() {
        String expected = 'Test';

        Test.startTest();
        String actual  = JourneyHelper.getStringValue(expected);
        Test.stopTest();

        System.assertEquals(expected, actual, 'String value should be the same');
    }

    @isTest
    static void closeOppRelatedJourneyTest() {
        Lead leadRecord = [SELECT Id, Ownerid FROM Lead WHERE Email='john.smith1116@example.com' LIMIT 1];

        List<Journey__c> journeys = [SELECT Id, Primary_Lead__c, Status__c FROM Journey__c WHERE Primary_Lead__c = :leadRecord.Id];

        Test.startTest();
        JourneyHelper.closeOppRelatedJourney(journeys);
        Test.stopTest();

        System.assertEquals('Converted', journeys[0].Status__c, 'journey status should be "Converted"');
    }

    @isTest
    static void closeOppRelatedJourneyIdTest() {
        Lead leadRecord = [SELECT Id, Ownerid FROM Lead WHERE Email='john.smith1116@example.com' LIMIT 1];

        List<Journey__c> journeys = [SELECT Id, Primary_Lead__c, Status__c FROM Journey__c WHERE Primary_Lead__c = :leadRecord.Id];

        Test.startTest();
        JourneyHelper.closeOppRelatedJourney(journeys[0].Id);
        Test.stopTest();

        List<Journey__c> updatedJourneys = [SELECT Id, Primary_Lead__c, Status__c FROM Journey__c WHERE Primary_Lead__c = :leadRecord.Id];

        System.assertEquals('Converted', updatedJourneys[0].Status__c, 'journey status should be "Converted"');
    }

    @isTest
    static void getJourneyCloseStagesTest() {
        Test.startTest();
        Set<String> journeyCloseStages = JourneyHelper.getJourneyCloseStages();
        Test.stopTest();

        System.assertNotEquals(null, journeyCloseStages, 'JourneyCloseStages sales console setting should not be null');
    }

    @isTest
    static void coverWrapperClassesTest() {
        // This test method is created to cover wrapper classes
        Test.startTest();
        JourneyHelper.LeadSource leadSource = new JourneyHelper.LeadSource();
        leadSource.name = 'test';
        leadSource.OverrideLeadSoruce = true;

        JourneyHelper.LeadSourceDetails leadSourceDetails = new JourneyHelper.LeadSourceDetails();
        leadSourceDetails.LeadSourceDetails = new Set<String>();

        JourneyHelper.JourneyCreationSetting journeyCreationSetting = new JourneyHelper.JourneyCreationSetting();
        journeyCreationSetting.NextCallInDaysFromLeadCreation = 1;
        journeyCreationSetting.NoCompanyAccountId = TestUtility.getFakeId(Account.getSObjectType());
        journeyCreationSetting.NextCallInDaysFromJourneyUpdation = 1;
        journeyCreationSetting.NewLeadActivityFields = new Map<String,String>();
        journeyCreationSetting.NewJourneyFields = new Map<String,String>();
        journeyCreationSetting.ExistingJourneyStage = 'test';
        journeyCreationSetting.AssignExistingJourneyOwner = 1;
        journeyCreationSetting.ExistingJourneyCreatedDateDifference = 1;
        journeyCreationSetting.JourneyAssignmentCutOffDays = 1;
        journeyCreationSetting.CloseInDaysFromJourneyCreation = 1;
        journeyCreationSetting.ClosedJourneyStages = new Set<String>();

        Test.stopTest();


        System.assertNotEquals(null, leadSourceDetails, 'leadSourceDetails instance should not be null');
        System.assertNotEquals(null, leadSource, 'leadSource instance should not be null');
        System.assertNotEquals(null, journeyCreationSetting, 'journeyCreationSetting instance should not be null');
    }
}