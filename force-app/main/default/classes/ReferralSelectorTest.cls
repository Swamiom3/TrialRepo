/*************************************************************************************************************************************
    Author      :   Pawel Biszczak
    Description :   This class provides sufficient test coverage for ReferralSelector class
    --------------------------------------------------------------------------------------------------------------------------------------
    VERSION    DATE            AUTHOR             DETAIL
    1          23 Jun, 2021    Pawel Biszczak    Initial Deployment
**************************************************************************************************************************************/
@isTest
public with sharing class ReferralSelectorTest {
    private static ReferralSelector referralSelector = new ReferralSelector();

    @testSetup
    static void makeData(){

        Map<String, Object> recordsData = new Map<String, Object>();
        recordsData.put('objName', 'Lead');
        recordsData.put('numberOfRecords', 2);
        recordsData.put('doInsert', true);
        List<Lead> leads = TestingUtility.getRecords(recordsData);

        recordsData = new Map<String, Object>();
        recordsData.put('objName', 'referral');
        recordsData.put('numberOfRecords', 2);
        List<Referral__c> referrals = TestingUtility.getRecords(recordsData);
        referrals[0].Lead__c = leads[0].Id;
        referrals[0].Referral_Email__c = 'referral@gmail.com';
        referrals[1].Lead__c = leads[1].Id;
        TestingUtility.updateListWithAssert(referrals);
    }

    @isTest
    static void getDefaultFieldsTest(){
        Set<String> fields;

        Test.startTest();
        fields = referralSelector.getDefaultFields();
        Test.stopTest();

        System.assert(!referralSelector.defaultFields.isEmpty(), 'Fields list should contain values');
    }

    @isTest
    static void shouldGetAdditionalFieldsByMultipleIds(){
        List<Referral__c> referrals;
        Referral__c referralRecord;

        Test.startTest();
        referralRecord = [SELECT Id, Lead__c
                          FROM Referral__c
                          WHERE Lead__c != null
                          LIMIT 1 ];
        referrals = referralSelector.getReferralsByLeadsIds(new List<Id>{ referralRecord.Lead__c });
        Test.stopTest();

        System.assertNotEquals(null, referrals[0].Lead__c, 'Field should be retrieved');
        System.assertEquals(referralRecord.Lead__c, referrals[0].Lead__c, 'Field should be retrieved');
        System.assert(referrals[0].IsActive__c, 'Should be active referral');
    }

    @isTest
    static void shouldGetNullResult(){
        List<Referral__c> referrals;

        Test.startTest();
        referrals = referralSelector.getReferralsByLeadsIds(new List<Id>{});
        Test.stopTest();

        System.assertEquals(null, referrals, 'Should return null');
    }
    
    @isTest
    static void getReferralsByReferralEmailTest(){
        Referral__c referralRecord = [SELECT Id, Referral_Email__c FROM Referral__c LIMIT 1];
        List<Referral__c> referrals = referralSelector.getReferralsByReferralEmail(new Set<String>{referralRecord.Referral_Email__c});
        Set<String> fakeReferralEmail = new Set<String>{'referral45@gmail.com'};
        List<Referral__c> fakeReferrals = referralSelector.getReferralsByReferralEmail(fakeReferralEmail);
        referralSelector.getReferralsByReferralEmail(new Set<String>());
        System.assertEquals(referralRecord.Referral_Email__c, referrals[0].Referral_Email__c);
        System.assert(fakeReferrals.isEmpty());
    }
     
    @isTest
    static void getReferralByRecordIdTest(){
        List<Referral__c> referrals = [SELECT Id, Referral_Email__c FROM Referral__c LIMIT 2];
        Id recordId = referrals[0].Id;
        Test.startTest();
        Referral__c referral = referralSelector.getReferralByRecordId(recordId);
        Test.stopTest();
        System.assertEquals(referral.Id, referrals[0].Id);
        System.assertNotEquals(referral.Id, referrals[1].Id);
    }
    
    @isTest
    static void getReferralsByReferralEmailsTest(){  
        Referral__c referralRecord = [SELECT Id, Referral_Email__c FROM Referral__c LIMIT 1];
        Test.startTest();
        List<Referral__c> referral = referralSelector.getReferralsByReferralEmails(new Set<String>{referralRecord.Referral_Email__c});
        Test.stopTest();
        Set<String> fakeReferralEmail = new Set<String>{'referral123@gmail.com'};
        List<Referral__c> fakeReferrals = referralSelector.getReferralsByReferralEmail(fakeReferralEmail);
        referralSelector.getReferralsByReferralEmail(new Set<String>());
        System.assertEquals(referralRecord.Referral_Email__c, referral[0].Referral_Email__c);
        System.assertEquals(fakeReferrals.isEmpty(), true);
    }
    
    @isTest
    static void getReferralsByReferralEmailAsStringTest(){  
        Referral__c referralRecord = [SELECT Id, Referral_Email__c FROM Referral__c LIMIT 1];
        Test.startTest();
        List<Referral__c> referral = referralSelector.getReferralsByReferralEmail(referralRecord.Referral_Email__c);
        Test.stopTest();
        Set<String> fakeReferralEmail = new Set<String>{'referral123@gmail.com'};
        List<Referral__c> fakeReferrals = referralSelector.getReferralsByReferralEmail(fakeReferralEmail);
        referralSelector.getReferralsByReferralEmail(new Set<String>());
        System.assertEquals(referralRecord.Referral_Email__c, referral[0].Referral_Email__c);
        System.assertEquals(fakeReferrals.isEmpty(), true);
    }
    
    @isTest
    static void getReferralsByLeadIdTest(){
        List<Lead> leads = [SELECT Id, ConvertedContactId from Lead LIMIT 2];
        Map<Id, Id> convertedLeadIdToContactIdMaps = new Map<Id, Id>();
        List<Id> leadId = new List<Id>();
        leadId.add(leads[0].Id);
        leadId.add(leads[1].Id);
        List<Id> convertedconId = new List<Id>();
        convertedconId.add(leads[0].ConvertedContactId);
        convertedconId.add(leads[1].ConvertedContactId);
        convertedLeadIdToContactIdMaps.put(leadId[0], convertedconId[0]);
        convertedLeadIdToContactIdMaps.put(leadId[1], convertedconId[1]);
        Test.startTest();
        List<Referral__c> referralRecord = referralSelector.getReferralsByLeadId(convertedLeadIdToContactIdMaps);
        Test.stopTest();
        System.assertEquals(referralRecord[0].Lead__c, leadId[0]);
        System.assertNotEquals(referralRecord[1].Lead__c, leadId[0]);
    }

}