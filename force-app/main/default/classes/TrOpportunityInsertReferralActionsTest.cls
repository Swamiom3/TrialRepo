/*****************************************************************************************************************************
    Author      :  Jitesh Adwani
    Description :  This class contains the Test Class of TrLeadConversionReferralActions
    History     :
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION    DATE               AUTHOR            ISSUE
    1          17, May 2019       Jitesh Adwani     ST-3976
    2          25, August 2020    Oleg Krasko       ST-6866
    3          30, Dec 2021       Vamsi             To Increase code coverage
    4          18, Feb 2022       Pawel Biszczak    ST-6869
******************************************************************************************************************************/
@isTest
private class TrOpportunityInsertReferralActionsTest {

    @isTest
    public static void testTrOpportunityInsertReferralActionsOnInsert() {
        Lead lead = TestingUtility.createLead(
                new Map<String, Object>{
                        'Referral_Expiration_Date__c' => Date.today()
                }, true);
        TestingUtility.createReferral(
                new Map<String, Object>{
                        'Lead__c' => lead.Id
                }, true);
        Database.LeadConvert leadToConvert = new Database.LeadConvert();
        leadToConvert.setLeadId(lead.Id);
        leadToConvert.setConvertedStatus('Converted');
        SObjectTriggerHandler.bypass('OpportunityContactRoleTrH');
        Database.LeadConvertResult convertedLeadResult = Database.convertLead(leadToConvert);
        System.assert(convertedLeadResult.isSuccess(), 'Lead should be properly converted');
        lead = [ SELECT ConvertedContactId
                 FROM Lead
                 WHERE Id = :lead.Id ];
        Account testAccount = TestingUtility.createAccount('test', true);
        Contact firstContact = TestingUtility.createContact(testAccount.Id, 'testAcc', true);
        Building__c building = TestingUtility.createBuilding(
                new Map<String, Object>{
                        'Name' => 'Test Building 1',
                        'UUID__c' => 'building-0001-0001',
                        'Agency_broker__c' => firstContact.Id
                }, true);
        Contact secondContact = new Contact(
                AccountId = testAccount.Id,
                FirstName = 'First Name Test2',
                LastName = 'testAcc2', 
                Email = 'Test2@test.com'
        );
        insert secondContact;
        List<Referral__c> manualOppCreationReferrals = [ SELECT Id
                                                         FROM Referral__c
                                                         WHERE Referral_Portal_Event__c = :GlobalConstants.OPP_REFERRAL_PORTAL_EVENT_MANUAL_CREATION
                                                         ORDER BY CreatedDate ];
        System.assert(manualOppCreationReferrals.isEmpty(),
                      'No referral should be created');


        Test.startTest();
        Opportunity firstOpportunity = TestingUtility.createOpportunity(testAccount.Id, false);
        firstOpportunity.Primary_Member__c = firstContact.Id;
        firstOpportunity.Referrer__c = lead.ConvertedContactId;
        firstOpportunity.Building__c = building.Id;
        Opportunity secondOpportunity = TestingUtility.createOpportunity(testAccount.Id,false);
        secondOpportunity.Referrer__c = lead.ConvertedContactId;
        Opportunity thirdOpportunity = TestingUtility.createOpportunity(testAccount.Id,false);
        thirdOpportunity.Primary_Member__c = lead.ConvertedContactId;
        thirdOpportunity.Referrer__c = lead.ConvertedContactId;
        List<Opportunity> opportunitiesToInsert = new List<Opportunity>();
        opportunitiesToInsert.add(firstOpportunity);
        opportunitiesToInsert.add(secondOpportunity);
        opportunitiesToInsert.add(thirdOpportunity);
        insert opportunitiesToInsert;
        OpportunityContactRole oppConRole = new OpportunityContactRole();
        oppConRole.OpportunityId = firstOpportunity.Id;
        oppConRole.ContactId = firstContact.Id;
        oppConRole.Role = GlobalConstants.OPP_CONTACT_ROLE_AGENCY_BROKER;
        oppConRole.IsPrimary = true;
        insert oppConRole;
        UtilReferral.getReferralForConversionOpp(firstOpportunity, new Referral__c(Opportunity__c = firstOpportunity.Id),
                                                 firstContact.Id);

        manualOppCreationReferrals = [ SELECT Id, Referral_Contact__c
                                       FROM Referral__c
                                       WHERE Referral_Portal_Event__c =: GlobalConstants.OPP_REFERRAL_PORTAL_EVENT_MANUAL_CREATION
                                       ORDER BY CreatedDate ];
        Test.stopTest();
        SObjectTriggerHandler.clearAllBypasses();

        System.assert(!manualOppCreationReferrals.isEmpty(), 'Referrals should be created');
        System.assertEquals(2, manualOppCreationReferrals.size(), '2 referrals should be presented');
    }

    @isTest
    public static void shouldProcessWithReferrals() {
        List<Journey__c> journeys = getFakeJourneys(true);
        List<Referral__c> referrals = getFakeReferrals(true);
        List<Opportunity> opportunities = getFakeOpportunities(true);
        List<Lead> leads = getFakeLeads(true);
        opportunities[0].Journey__c = journeys[0].Id;
        opportunities[1].Journey__c = journeys[1].Id;
        journeys[0].Lead_Id__c = leads[0].Id;
        journeys[1].Lead_Id__c = leads[1].Id;
        referrals[0].Lead__c = leads[0].Id;
        referrals[1].Lead__c = leads[1].Id;

        Test.startTest();
        TrOpportunityInsertReferralActions triggerInstance = new TrOpportunityInsertReferralActions();
        triggerInstance.journeySelector = (JourneySelector) MockService.createMock(
                JourneySelector.class,
                new Map<String, Object>{
                        'getJourneysWithAdditionalFieldsByIds' => journeys
                });
        triggerInstance.referralSelector = (ReferralSelector) MockService.createMock(
                ReferralSelector.class,
                new Map<String, Object>{
                        'getReferralsByLeadsIds' => referrals
                });
        triggerInstance.newOpportunities = opportunities;
        Map<Id, Id> journeyIdsByOpportunitiesIds = triggerInstance.prepareJourneysToOpportunitiesIds();
        Map<Id, Referral__c> referralsIdsByOpportunitiesIds =
                triggerInstance.prepareReferralsFromJourneyByOpportunitiesIds(journeyIdsByOpportunitiesIds);
        Test.stopTest();

        System.assert(referralsIdsByOpportunitiesIds.containsKey(opportunities[0].Id),
                      'Should contain first opportunity Id');
        System.assert(referralsIdsByOpportunitiesIds.containsKey(opportunities[1].Id),
                      'Should contain second opportunity Id');
    }

    static List<Referral__c> getFakeReferrals(Boolean isFakeIds) {
        Map<String, Object> recordsData = new Map<String, Object>();
        recordsData = new Map<String, Object>();
        recordsData.put('objectName', 'Referral__c');
        recordsData.put('numberOfRecords', 2);
        return MockTestingUtility.getRecords(recordsData, isFakeIds);
    }

    static List<Journey__c> getFakeJourneys(Boolean isFakeIds) {
        Map<String, Object> recordsData = new Map<String, Object>();
        recordsData = new Map<String, Object>();
        recordsData.put('objectName', 'Journey__c');
        recordsData.put('numberOfRecords', 2);
        return MockTestingUtility.getRecords(recordsData, isFakeIds);
    }

    static List<Lead> getFakeLeads(Boolean isFakeIds) {
        Map<String, Object> recordsData = new Map<String, Object>();
        recordsData = new Map<String, Object>();
        recordsData.put('objectName', 'Lead');
        recordsData.put('numberOfRecords', 2);
        return MockTestingUtility.getRecords(recordsData, isFakeIds);
    }

    static List<Opportunity> getFakeOpportunities(Boolean isFakeIds) {
        Map<String, Object> recordsData = new Map<String, Object>();
        recordsData = new Map<String, Object>();
        recordsData.put('objectName', 'Opportunity');
        recordsData.put('numberOfRecords', 2);
        return MockTestingUtility.getRecords(recordsData, isFakeIds);
    }
}