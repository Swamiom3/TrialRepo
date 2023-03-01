/************************************************************************************************************************************
    Author        : Dipak Pawar
    Description   : This class is used to test OpportunityHelper
    History       :
----------------------------------------------------------------------------------------------------------------------------------
  VERSION        DATE                 AUTHOR            DETAIL                               ISSUE
  1              5th June 2018        Dipak Pawar       Initial Developement
  2              25th July 2019       Rupesh Patil      Modifications and Optimization       ST-4399
  3              7th August 2019      Rupesh Patil      Restructure of Test methods          ST-4393
  4              2nd February 2022    Pawel Biszczak    Refactor and coverage improvement    ST-10359
**************************************************************************************************************************************/
@isTest
private class OpportunityHelperTest {

  	@testSetup 
	public static void setup(){
        Profile weworkSystemAdmin = [ SELECT Id
                                      FROM Profile
                                      WHERE Name = 'System Administrator'];
        Map<String, Object> userDataMap = new Map<String, Object>();
        userDataMap.put('LastName', 'TestCommunitySalesLead');
        userDataMap.put('Email', 'adminuser1@wework.com');
        User adminUser = TestingUtility.insertUserWithAssert(weworkSystemAdmin.Id, userDataMap, true);
       
        List<Building__c> buildings = new List<Building__c>();
        buildings.add(new Building__c(City__c = 'Amsterdam',
                                      Country__c = 'Netherlands',
                                      Name = 'AMS-Metropool',
                                      CurrencyIsoCode = 'USD',
                                      Time_Zone__c = 'Europe/Amsterdam',
                                      UUID__c = 'testBuilding1'));
        buildings.add(new Building__c(City__c = 'Brooklyn',
                                      Country__c = 'USA',
                                      State__c = 'TS',
                                      Name = 'BKN-Brooklyn Heights',
                                      CurrencyIsoCode = 'USD',
                                      Time_Zone__c = 'America/New_York',
                                      Region_Name__c = 'Mumbai',
                                      UUID__c = 'testBuilding2'));
        buildings.add(new Building__c(City__c = 'Clinton',
                                      Country__c = 'USA', State__c = 'TS',
                                      Name = 'testBuilding',
                                      CurrencyIsoCode = 'USD',
                                      Time_Zone__c = 'America/New_York',
                                      Portfolio_Name__c = 'PortfolioNmae',
                                      UUID__c = 'testBuilding3'));
        buildings.add(new Building__c(City__c = 'Mumbai',
                                      Country__c = 'India',
                                      State__c = 'MH',
                                      Name = 'TestMumbaiBuilding',
                                      CurrencyIsoCode = 'INR',
                                      Time_Zone__c = 'Asia/Kolkata',
                                      Cluster_Name__c = 'ClusterName',
                                      Community_Sales_Lead__c = adminUser.Id,
                                      UUID__c = 'testBuilding4'));
        TestingUtility.insertListWithAssert(buildings);
		
        Test.startTest();
        List<Contact> contacts = new List<Contact>();
        contacts.add(new Contact(FirstName = 'TestFirstName1', LastName = 'TestContact1', Email = 'testContact1@test.com'));
        contacts.add(new Contact(FirstName = 'TestFirstName2', LastName = 'TestContact2', Email = 'testContact2@test.com'));
        contacts.add(new Contact(FirstName = 'TestFirstName3', LastName = 'TestContact3', Email = 'adminuser1@wework.com'));
        TestingUtility.insertListWithAssert(contacts);

        String recTypeBillingAccountId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Business Account').getRecordTypeId();

        List<Account> accounts = new List<Account>();
       	accounts.add(new Account(Name = 'Test-Account1',
                                 Primary_Member__c = contacts[0].Id,
                                 RecordTypeId = recTypeBillingAccountId,
                                 UUID__c = 'TestBilligAcc1'));
        accounts.add(new Account(Name = 'Test-Account2',
                                 Primary_Member__c = contacts[1].Id,
                                 RecordTypeId = recTypeBillingAccountId,
                                 UUID__c = 'TestBilligAcc2'));
        accounts.add(new Account(Name = 'Test-Account3',
                                 RecordTypeId = recTypeBillingAccountId,
                                 UUID__c = 'TestBilligAcc3'));
        TestingUtility.insertListWithAssert(accounts);
        
        Map<String, Object> recordsDataMap = new Map<String, Object>();
        Map<String, List<Object>> opportunitiesFieldsMap = new Map<String, List<Object>>();
        opportunitiesFieldsMap.put('Name', new List<Object>{'test oppty1', 'test oppty2'});
        opportunitiesFieldsMap.put('StageName', new List<Object>{GlobalConstants.OPPORTUNITY_STAGE_QUALIFYING,
                                                                 GlobalConstants.OPPORTUNITY_STAGE_QUALIFYING });
        opportunitiesFieldsMap.put('AccountId', new List<Object>{accounts[0].Id, accounts[1].Id});
        opportunitiesFieldsMap.put('Primary_Member__c', new List<Object>{contacts[0].Id, contacts[1].Id});
        opportunitiesFieldsMap.put('Referrer__c', new List<Object>{contacts[0].Id, contacts[0].Id});
        opportunitiesFieldsMap.put('Building__c', new List<Object>{buildings[0].Id, buildings[1].Id});
        opportunitiesFieldsMap.put('Locations_Interested__c', new List<Object>{buildings[0].Name, buildings[1].Name});
        opportunitiesFieldsMap.put('Contract_UUID__c', new List<Object>{'testOpp1', 'testOpp2'});
        recordsDataMap.put('objName', 'Opportunity');
        recordsDataMap.put('numberOfRecords', 2);
        recordsDataMap.put('doInsert', true);
        recordsDataMap.put('mapFieldValues', opportunitiesFieldsMap);
        TestingUtility.getRecords(recordsDataMap);

        List<Journey__c> journeys = new List<Journey__c>();
        journeys.add(new Journey__c(Name = 'TestJourney',
                                    Primary_Contact__c = contacts[0].Id,
                                    Status__c = 'Accepted',
                                    NMD_Next_Contact_Date__c = Date.today(),
                                    Building_Interested_In__c = buildings[1].Id));
        TestingUtility.insertListWithAssert(journeys);

     	Test.stopTest();
    }

    @isTest
    public static void verifyOpportunityHelperMethods(){
        List<Contact> contacts = [ SELECT Id, Email, FirstName, LastName
                                   FROM Contact
                                   WHERE Email IN ('testContact1@test.com', 'testContact2@test.com',
                                                   'adminuser1@wework.com') ];
        List<Opportunity> opportunities = [ SELECT Id, AccountId, Account.Name,Building__c,
                                                   Primary_Member__c, Primary_Member__r.Name, Contract_UUID__c
                                           FROM Opportunity
                                           WHERE Contract_UUID__c IN ('testOpp1', 'testOpp2')];
        List<User> users = [ SELECT Id, Email, ProfileId, Profile.Name
                             FROM User
                             WHERE Email = 'adminuser1@wework.com' ];
        List<Account> accounts = [ SELECT Id, Name, UUID__c
                                   FROM Account
                                   WHERE Name IN ('Test-Account1', 'Test-Account2') ];
        List<Building__c> buildings = [ SELECT Id, Name, Portfolio_Name__c, Cluster_Name__c, UUID__c
                                        FROM Building__c
                                        WHERE UUID__c IN ('testBuilding1', 'testBuilding2',
                                                          'testBuilding3', 'testBuilding4')];
        List<Journey__c > journeys = [ SELECT Id, Name
                                       FROM Journey__c
                                       LIMIT 2 ];
        Map<String, List<sObject>> mapRecords =
                new Map<String, List<sObject>>{
                        'Contact' => contacts,
                        'Opportunity' => opportunities,
                        'User' => users,
                        'Account' => accounts,
                        'Building__c' => buildings,
                        'Journey__c' => journeys
                };
        
        Test.startTest();
        verifyGetLatestOpportunity(mapRecords);
        verifyGetLowerSize();
        verifyGetUniquePickListValues();
        verifyGetJourneyForMapping(mapRecords);       
        Test.stopTest();
        verifyGetValidTeamMemberForDifferentBuilding(mapRecords);       
    }

    private static void verifyGetLatestOpportunity(Map<String, List<sObject>> mapRecords) {
        Account firstAccount, secondAccount;
        Contact firstContact, secondContact;
        Building__c firstBuilding, secondBuilding, thirdBuilding;
        for(Account accountRecord : (List<Account>) mapRecords.get('Account')) {
            if(accountRecord.UUID__c == 'TestBilligAcc1') {
                firstAccount = accountRecord;
            }
            if(accountRecord.UUID__c == 'TestBilligAcc2') {
                secondAccount = accountRecord;
            }
        }
        for(Contact contactRecord : (List<Contact>) mapRecords.get('Contact')) {
            if(contactRecord.Email == 'testContact1@test.com') {
                firstContact = contactRecord;
            }
            if(contactRecord.Email == 'testContact2@test.com') {
                secondContact = contactRecord;
            }
        }
        for(Building__c buildingRecord : (List<Building__c>) mapRecords.get('Building__c')) {
            if(buildingRecord.UUID__c == 'testBuilding1') {
                firstBuilding = buildingRecord;
            }
            if(buildingRecord.UUID__c == 'testBuilding2') {
                secondBuilding = buildingRecord;
            }
            if(buildingRecord.UUID__c == 'testBuilding4') {
                thirdBuilding = buildingRecord;
            }
        }
        Opportunity opportunityRecord = OpportunityHelper.getLatestOpenOpportunity(firstAccount.Id, firstContact.Id, firstBuilding);
        System.assertEquals(opportunityRecord.Locations_Interested__c, firstBuilding.Name,
                            'Building Name should be equal to Locations Interested');
        System.assertEquals(opportunityRecord.Primary_Member__c, firstContact.Id,
                            'Primary Member should be set to provided contact Id');
        System.assertEquals(opportunityRecord.Building__r.Portfolio_Name__c, firstBuilding.Portfolio_Name__c,
                            'Portfolios Names should be equal');
        System.assertEquals(opportunityRecord.Building__r.Cluster_Name__c, firstBuilding.Cluster_Name__c,
                            'Clusters Names should be equal');

        opportunityRecord = OpportunityHelper.getLatestOpenOpportunity(secondAccount.Id, secondContact.Id, secondBuilding);
        System.assertEquals(opportunityRecord.Locations_Interested__c, secondBuilding.Name,
                            'Building Name should be equal to Locations Interested');
        System.assertEquals(opportunityRecord.Primary_Member__c, secondContact.Id,
                            'Primary Member should be set to provided contact Id');
        System.assertEquals(opportunityRecord.Building__r.Portfolio_Name__c, secondBuilding.Portfolio_Name__c,
                            'Portfolios Names should be equal');
        System.assertEquals(opportunityRecord.Building__r.Cluster_Name__c, secondBuilding.Cluster_Name__c,
                            'Clusters Names should be equal');

        opportunityRecord = OpportunityHelper.getLatestOpenOpportunity(firstAccount.Id, firstContact.Id, thirdBuilding);
        System.assert(opportunityRecord == null);
    }

    @IsTest
    private static void shouldCreateOpportunityForContactAndJourney() {
        RESTAPITourModelsV2.Input tourPayload = getTourPayloadWithContactInfo();
        Opportunity opportunityToTest;

        Test.startTest();
        opportunityToTest = OpportunityHelper.createOpportunity(tourPayload.journey_sfid, tourPayload.booked_by_contact_id,
                                                                GlobalConstants.OPPORTUNITY_STAGE_QUALIFYING);
        Test.stopTest();
        
        System.assertEquals(opportunityToTest.StageName, GlobalConstants.OPPORTUNITY_STAGE_QUALIFYING,
                            'Opportunity Stage Name should be set properly');
        System.assertEquals(opportunityToTest.Name, 'New Opportunity',
                            'Opportunity Name should be set properly');
    }

    @IsTest
    private static void shouldCreateOpportunityForGivenContact(){
        RESTAPITourModelsV2.Input tourPayload = getTourPayloadWithContactInfo();
        Opportunity firstOpportunityToTest;
        Opportunity secondOpportunityToTest;

        Test.startTest();
        firstOpportunityToTest = OpportunityHelper.createOpportunity(tourPayload.booked_by_contact_id, GlobalConstants.OPPORTUNITY_STAGE_QUALIFYING);
        secondOpportunityToTest = OpportunityHelper.createOpportunity(tourPayload.booked_by_contact_id, GlobalConstants.OPPORTUNITY_STAGE_SELLING);
        Test.stopTest();

        System.assertEquals(firstOpportunityToTest.StageName, GlobalConstants.OPPORTUNITY_STAGE_QUALIFYING,
                            'Opportunity Stage Name should be set properly');
        System.assertEquals(secondOpportunityToTest.StageName, GlobalConstants.OPPORTUNITY_STAGE_SELLING,
                            'Opportunity Stage Name should be set properly');
    }

    @IsTest
    private static void shouldCreateOpportunityForCommunityViewPage(){
        Building__c building = [ SELECT Id, Name, Portfolio_Name__c, Cluster_Name__c, UUID__c
                                 FROM Building__c
                                 WHERE UUID__c = 'testBuilding1'
                                 LIMIT 1 ];
        RESTAPITourModelsV2.Input tourPayload = getTourPayloadWithContactInfo();
        Opportunity opportunityToTest;

        Test.startTest();
        opportunityToTest = OpportunityHelper.createOpportunity(tourPayload.booked_by_contact_id, 1, building.Id);
        Test.stopTest();


        System.assertEquals(String.valueOf(opportunityToTest.Name).toLowerCase(), 'community view opportunity',
                            'Opportunity Name should be set to Community View\'s one');
        System.assertEquals(opportunityToTest.StageName, GlobalConstants.OPPORTUNITY_STAGE_QUALIFYING,
                            'Opportunity Stage Name should be set properly');
    }

    @IsTest
    private static void shouldCreateEnterpriseOpportunity(){
        RESTAPITourModelsV2.Input tourPayload = getTourPayloadWithContactInfo();
        Building__c building = [ SELECT Id, Name, Portfolio_Name__c, Cluster_Name__c, UUID__c
                                  FROM Building__c
                                  WHERE UUID__c = 'testBuilding1'
                                  LIMIT 1 ];
        Opportunity opportunityFromBuilding;
        Opportunity enterpriseOpportunity;

        Test.startTest();
        opportunityFromBuilding = OpportunityHelper.createOpportunity(tourPayload.booked_by_contact_id, 1, building.Id);
        enterpriseOpportunity = OpportunityHelper.createOpportunity(opportunityFromBuilding);
        Test.stopTest();

        System.assertEquals(enterpriseOpportunity.Primary_Member__c, tourPayload.booked_by_contact_id, 'Primary Member should be set to provided Contact Id');
        System.assert(String.isNotBlank(enterpriseOpportunity.OwnerId), 'Owner should not be blank after create opportunity action');
    }

    private static void verifyGetLowerSize(){
        Integer companySize = OpportunityHelper.getLowerSize('1,000-2,000');
        System.assertEquals(1000, companySize, 'Company Size is not match for "-" Separator');
        
        companySize = OpportunityHelper.getLowerSize('1,000+2,000');
        System.assertEquals(1000, companySize, 'Company Size is not match for "+" Separator');
        
        companySize = OpportunityHelper.getLowerSize('1,000');
        System.assertEquals(1000, companySize, 'Company Size is not match, remove comma');
        
        companySize = OpportunityHelper.getLowerSize('');
        System.assertEquals(0, 0, 'Company Size is not match for "-" Separator'); 
    }

    private static void verifyGetUniquePickListValues(){
        String pickList = 'test1;test2;test3';
        Set<String> newValues = new Set<String>{'Picklist Value1', 'Picklist Value2', 'test1'};
        Set<String> picklistSet = OpportunityHelper.getUniquePickListValues(pickList, newValues);
        System.assertEquals(5, picklistSet.size() , 'Size of picklist is not match with expected size');
    }

    private static void verifyGetJourneyForMapping(Map<String, List<sObject>> mapRecords){
        Contact firstContact;
        Building__c building;    
        for(Contact contactRecord : (List<Contact>)mapRecords.get('Contact')){
            if(contactRecord.Email == 'testContact1@test.com'){
                firstContact = contactRecord;
                break;
            }           
        }
        for(Building__c buildingRecord : (List<Building__c>)mapRecords.get('Building__c')){
            if(buildingRecord.UUID__c == 'testBuilding2'){
                building = buildingRecord;
                break;
            }
        }

        Journey__c journey = OpportunityHelper.getJourneyForMapping(building, firstContact.Id, TRUE);
        System.assert(journey != null);
        System.assertEquals(building.Id, journey.Building_Interested_In__c,
                            'Building Id should be equal to Locations Interested');
        System.assertEquals('Accepted', journey.Status__c,
                            'Journey status should be changed to Accepted');
    }

    private static void verifyGetValidTeamMemberForDifferentBuilding(Map<String, List<sObject>> mapRecords){
        List<Building__c> buildings = [SELECT Id, Name, Community_Sales_Lead__c, Cluster__r.Sales_Lead__c FROM Building__c WHERE Name LIKE '%TestMumbaiBuilding%' LIMIT 1];
        System.assertEquals(buildings.size(), 1);
        Contact thirdContact;
        for(Contact contactRecord : (List<Contact>)mapRecords.get('Contact')){
            if(contactRecord.Email == 'adminuser1@wework.com'){
                thirdContact = contactRecord;
                break;
            }           
        }
        Opportunity objSecondOpportunity;  
        for(Opportunity opportunityRecord : (List<Opportunity>)mapRecords.get('Opportunity')){
            if(opportunityRecord.Contract_UUID__c == 'testOpp2'){
                objSecondOpportunity = opportunityRecord;
                break;
            }           
        }
    }

    private static RESTAPITourModelsV2.Input getTourPayloadWithContactInfo() {
        Contact contactRecord = [ SELECT Id, Email, FirstName, LastName
                                  FROM Contact
                                  WHERE Email = 'testContact1@test.com'
                                  LIMIT 1 ];
        Journey__c journey = [ SELECT Id, Name
                               FROM Journey__c
                               LIMIT 1 ];
        RESTAPITourModelsV2.Input tourPayload = getTourPayload();
        tourPayload.booked_by_contact_id = contactRecord.Id;
        tourPayload.booked_by_sales_lead = true;
        tourPayload.email = contactRecord.Email;
        tourPayload.first_name = contactRecord.FirstName;
        tourPayload.last_name = contactRecord.LastName;
        tourPayload.journey_sfid = journey.Id;

        return tourPayload;
    }

    public static RESTAPITourModelsV2.Input getTourPayload(){
        String jsonTourPayload = '{\n' +
                '   "first_name":"John",\n' +
                '   "last_name":"Smith",\n' +
                '   "email":"john.smith1@example.com",\n' +
                '   "phone":"1234567890",\n' +
                '   "lead_source":"Event",\n' +
                '   "lead_source_detail":"Book A Tour Form",\n' +
                '   "utm_campaign_id":"",\n' +
                '   "utm_campaign":"San Francisco - Modifier",\n' +
                '   "utm_content":"utm contents",\n' +
                '   "utm_medium":"cpc",\n' +
                '   "utm_source":"ads-google",\n' +
                '   "utm_term":"virtual +office +san +francisco",\n' +
                '   "company_name":"John Smith",\n' +
                '   "company_size":"2-5 desks",\n' +
                '   "company_industry":"Education",\n' +
                '   "quick_quote_location":"New York City",\n' +
                '   "notes":"Our Notes for",\n' +
                '   "referral_code":"JetBlue",\n' +
                '   "promo_code":"JetBlue",\n' +
                '   "buildings_interested_uuids":[\n' +
                '      "bdf78b97-f8c9-4062-923d-ed32e251d2ad"\n' +
                '   ],\n' +
                '   "product_interests":[\n' +
                '      "Office Space"\n' +
                '   ],\n' +
                '   "product_line":"WeWork",\n' +
                '   "locale":"US",\n' +
                '   "country_code":"US",\n' +
                '   "tour_date":"2018-06-07",\n' +
                '   "tour_time":"08:00AM",\n' +
                '   "tour_uuid":"fdb15bdf-19e2-4abe-bd40-7b7fa9816fb5",\n' +
                '   "tour_building_uuid":"bdf78b97-f8c9-4062-923d-ed32e251d2ad",\n' +
                '   "tour_notes":"Currently at Manhattan, Relocate",\n' +
                '   "contact_uuid":"dsp18593-3239-45cc-b690-5bccc15a27c3",\n' +
                '   "original_tour":"",\n' +
                '   "original_tour_uuid":"",\n' +
                '   "sf_journey_uuid":"",\n' +
                '   "booked_by_contact_id":"0033D00000Ou6FA",\n' +
                '   "tour_completed_by":"",\n' +
                '   "t_and_cs_consent":"False",\n' +
                '   "marketing_consent":"False",\n' +
                '   "affiliates_consent":"False",\n' +
                '   "referral_fail_reason":"No Show",\n' +
                '   "booked_by_sales_lead":true\n' +
                '}';
        RESTAPITourModelsV2.Input tourPayload = (RESTAPITourModelsV2.Input)JSON.deserialize(jsonTourPayload, RESTAPITourModelsV2.Input.class);
        return tourPayload;
    }

    @isTest
    private static void shouldChangeOpportunityFieldFromSource(){
        List<Opportunity> opportunities = getFakeOpportunities();
        List<Building__c> buildings = getFakeBuildings();
        opportunities[0].Building_Name__c = 'Old Building Name';
        buildings[0].Name = 'Test Building Name';

        Test.startTest();
        OpportunityHelper.updateDataFromRelatedObject(buildings[0], opportunities[0]);
        Test.stopTest();

        System.assertEquals(opportunities[0].Building_Name__c, buildings[0].Name,
                            'Building Name value should be changed after field update');
    }

    @isTest
    private static void shouldBeChangedToNullOnEmptyValue(){
        List<Opportunity> opportunities = getFakeOpportunities();
        List<Building__c> buildings = getFakeBuildings();
        opportunities[0].Building_Name__c = 'Old Building Name';
        buildings[0] = null;

        Test.startTest();
        OpportunityHelper.updateDataFromRelatedObject(buildings[0], opportunities[0]);
        Test.stopTest();

        System.assertEquals(opportunities[0].Building_Name__c, null,
                            'Building Name should be changed to null on empty field value');
    }

    static List<Opportunity> getFakeOpportunities() {
        Map<String, Object> recordsData = new Map<String, Object>();
        recordsData = new Map<String, Object>();
        recordsData.put('objectName', 'Opportunity');
        recordsData.put('numberOfRecords', 1);
        return MockTestingUtility.getRecords(recordsData, true);
    }

    static List<Building__c> getFakeBuildings() {
        Map<String, Object> recordsData = new Map<String, Object>();
        recordsData = new Map<String, Object>();
        recordsData.put('objectName', 'Building__c');
        recordsData.put('numberOfRecords', 1);
        return MockTestingUtility.getRecords(recordsData, true);
    }
}