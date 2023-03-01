/******************************************************************************************************************** 
    Author      :  Maciej Miłosz
    Description :  Test class for UtilReferral class
    History     :  
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION                 DATE                    AUTHOR                          ISSUE
    1                   1 Feb 2022                  Maciej Miłosz                   ----
*********************************************************************************************************************/
@isTest
public class UtilReferralTest {

    @isTest
    public static void referralForConversionTest(){
        String dummyAccId = TestUtility.getFakeId(Account.getSObjectType());
        Opportunity opp = TestingUtility.createOpportunity(dummyAccId, false);
        opp.Id = TestUtility.getFakeId(Opportunity.getSObjectType());
        opp.Building__c = TestUtility.getFakeId(Building__c.getSObjectType());
        String contactId = TestUtility.getFakeId(Contact.getSObjectType());
        opp.Primary_Member__c = contactId;
        opp.Building__c = TestUtility.getFakeId(Building__c.getSObjectType());

        Referral__c testRef = TestingUtility.createReferral(new Map<String, Object>{
            'Lead__c' => TestUtility.getFakeId(Lead.getSObjectType())
        }, false);

        Test.startTest();
        Referral__c referralForConversion = UtilReferral.getReferralForConversionOpp(opp, testRef, contactId);
        Test.stopTest();
        System.assertEquals(opp.Id, referralForConversion.Opportunity__c,'Opportunity does not match');
        System.assertEquals(opp.Building__c, referralForConversion.Building_Interested_In__c, 'Building does not match');
        System.assertEquals(contactId, referralForConversion.Referral_Contact__c, 'Contact does not match');
    }

    @isTest
    public static void referralForConversionExistingReferralTest(){
        String dummyAccId = TestUtility.getFakeId(Account.getSObjectType());
        Opportunity opp = TestingUtility.createOpportunity(dummyAccId, false);
        opp.Id = TestUtility.getFakeId(Opportunity.getSObjectType());
        opp.Building__c = TestUtility.getFakeId(Building__c.getSObjectType());
        String contactId = TestUtility.getFakeId(Contact.getSObjectType());
        opp.Primary_Member__c = contactId;
        opp.Building__c = TestUtility.getFakeId(Building__c.getSObjectType());

        Referral__c testRef = TestingUtility.createReferral(new Map<String, Object>{
            'Lead__c' => TestUtility.getFakeId(Lead.getSObjectType()),
            'Opportunity__c' => opp.Id,
            'Referrer__c' => contactId
        }, false);

        Test.startTest();
        Referral__c referralForConversion = UtilReferral.getReferralForConversionOpp(opp, testRef, contactId);
        Test.stopTest();
        System.assertEquals(opp.Id, referralForConversion.Opportunity__c,'Opportunity does not match');
        System.assertEquals(opp.Building__c, referralForConversion.Building_Interested_In__c, 'Building does not match');
        System.assertEquals(contactId, referralForConversion.Referrer__c, 'Referrer does not match');
    }

    @isTest
    public static void getOppIdToReferralMapTest(){
        String dummyAccId = TestUtility.getFakeId(Account.getSObjectType());
        Opportunity opp = TestingUtility.createOpportunity(dummyAccId, false);
        opp.Id = TestUtility.getFakeId(Opportunity.getSObjectType());
        opp.Building__c = TestUtility.getFakeId(Building__c.getSObjectType());
        String contactId = TestUtility.getFakeId(Contact.getSObjectType());
        opp.Primary_Member__c = contactId;
        opp.Building__c = TestUtility.getFakeId(Building__c.getSObjectType());

        Referral__c testRef = TestingUtility.createReferral(new Map<String, Object>{
            'Lead__c' => TestUtility.getFakeId(Lead.getSObjectType()),
            'Opportunity__c' => opp.Id,
            'Referrer__c' => contactId,
            'Id' => TestUtility.getFakeId(Referral__c.getSObjectType())
        }, false);

        Map<Id, Id> mapPrimaryContactIdToOppId = new Map<Id, Id>{contactId => opp.Id};
        Map<Id, Id> mapConvertedLeadIdToContactId = new Map<Id, Id>{testRef.Lead__c => contactId};
        Map<Id, Referral__c> mapConvertedLeadIdToReferral = new Map<Id, Referral__c>{testRef.Lead__c => testRef};

        Map<Id, Referral__c> oppToReferral = UtilReferral.getOppIdToReferralMap(mapPrimaryContactIdToOppId, mapConvertedLeadIdToContactId, mapConvertedLeadIdToReferral);

        System.assert(oppToReferral.containsKey(opp.Id), 'Opportunity Id should be in map key');
        System.assert(testRef.Id == oppToReferral.get(opp.Id).Id, 'Referral should be set as value for given opportunity');
    }
}