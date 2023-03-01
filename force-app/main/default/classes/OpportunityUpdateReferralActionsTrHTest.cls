@isTest
public with sharing class OpportunityUpdateReferralActionsTrHTest {

    @isTest
    static void testGetReferralsToUpsert() {
        System.debug('testGetReferralsToUpsert method');
        List<Opportunity> oldOpportunities = getFakeOppsFromJson(getJsonStringForOppsWithReffs(getFakeOpportunities(10), 2));
        List<Opportunity> newOpportunities = oldOpportunities.deepClone(true);
        newOpportunities[0].Referrer__c = TestUtility.getFakeId(Contact.SObjectType);
        newOpportunities[1].Referrer__c = TestUtility.getFakeId(Contact.SObjectType);
        newOpportunities[2].StageName = 'Closed Lost';
        newOpportunities[3].StageName = 'Closed Won';
        newOpportunities[4].Building__c = TestUtility.getFakeId(Building__c.SObjectType);
        newOpportunities[5].Referrer__c = TestUtility.getFakeId(Contact.SObjectType);
        newOpportunities[6].Contract_Stage__c = 'Contract Voided';
        newOpportunities[7].Building__c = TestUtility.getFakeId(Building__c.SObjectType);
        newOpportunities[8].Building__c = TestUtility.getFakeId(Building__c.SObjectType);
        newOpportunities[9].Contract_Stage__c = 'Contract Sent';
        OpportunityUpdateReferralActionsTrH oppUpdRefActTrH = new OpportunityUpdateReferralActionsTrH(newOpportunities, new Map<Id, Opportunity>(oldOpportunities));
        oppUpdRefActTrH.oppSelector = (OpportunitySelector) MockService.createMock(
                                                            OpportunitySelector.class,
                                                            new Map<String, Object>{
                                                                'getOppsWithRelatedReferrals' => oldOpportunities});
        Test.startTest();
        List<Referral__c> referralsToUpsert = oppUpdRefActTrH.getReferralsToUpsert();
        Test.stopTest();
        System.assertNotEquals(null, referralsToUpsert, 'Result referrals list must not be null');
        System.assertEquals(16, referralsToUpsert.size(), 'Result referrals list must have 16 Referrals');
    }

    @isTest
    private static void testCheckReferralCreationOnOppConRole() {
        System.debug('testCheckReferralCreationOnOppConRole method');
        List<Opportunity> oldOpportunities = getFakeOppsFromJson(getJsonStringForOppsWithContactRoles(getFakeOpportunities(4), 1));
        List<OpportunityContactRole> oppConRoles = new List<OpportunityContactRole>();
        for (Opportunity opp : oldOpportunities) {
            oppConRoles.addAll(opp.OpportunityContactRoles);
        }
        oldOpportunities[0].Referrer__c = null;
        oldOpportunities[1].Referrer__c = null;
        List<Opportunity> newOpportunities = oldOpportunities.deepClone(true);
        newOpportunities[0].Name = 'New Name1';
        newOpportunities[1].Name = 'New Name2';
        OpportunityUpdateReferralActionsTrH oppUpdRefActTrH = new OpportunityUpdateReferralActionsTrH(newOpportunities, new Map<Id, Opportunity>(oldOpportunities));
        oppUpdRefActTrH.oppSelector = (OpportunitySelector) MockService.createMock(
                                                            OpportunitySelector.class,
                                                            new Map<String, Object>{
                                                                'getOppsWithRelatedReferrals' => oldOpportunities});
        oppUpdRefActTrH.oppContactRoleSelector = (OpportunityContactRoleSelector) MockService.createMock(
                                                            OpportunityContactRoleSelector.class,
                                                            new Map<String, Object>{
                                                                'getOpportunityContactRolesByOppIdsAndRole' => oppConRoles
                                                            });                                                   
        Test.startTest();
        List<Referral__c> referralsToUpsert = oppUpdRefActTrH.getReferralsToUpsert();
        Test.stopTest();
        System.assertNotEquals(null, referralsToUpsert, 'Result referrals list must not be null');
        System.assertEquals(2, referralsToUpsert.size(), 'Result referrals list size is incorrect');
    }

    @isTest
    static void testHandleReferrerUpdatedWithoutReffs() {
        System.debug('testHandleReferrerUpdatedWithoutReffs method');
        List<Opportunity> oldOpportunities = getFakeOpportunities(4);
        List<Opportunity> newOpportunities = oldOpportunities.deepClone(true);
        oldOpportunities[0].Referrer__c = null;
        oldOpportunities[1].Referrer__c = null;
        OpportunityUpdateReferralActionsTrH oppUpdRefActTrH = new OpportunityUpdateReferralActionsTrH(newOpportunities, new Map<Id, Opportunity>(oldOpportunities));
        oppUpdRefActTrH.oppSelector = (OpportunitySelector) MockService.createMock(
                                                            OpportunitySelector.class,
                                                            new Map<String, Object>{
                                                                'getOppsWithRelatedReferrals' => oldOpportunities});
        Test.startTest();
        List<Referral__c> referralsToUpsert = oppUpdRefActTrH.getReferralsToUpsert();
        Test.stopTest();
        System.assertEquals(2, referralsToUpsert.size(), 'Result referrals list must have 2 Referrals');
    }

    static String getJsonStringForOppsWithReffs(List<Opportunity> opps, Integer refsNumber) {
        String toDeserialize = '[';
        for (Opportunity opp : opps) {
            List<Referral__c> referrals = getFakeRelatedReferrals(refsNumber, opp.Id, opp.Referrer__c);
            toDeserialize += JSON.serialize(opp).removeEnd('}') + ',' + '"Referrals__r": {"totalSize": ' +
                                refsNumber +', "done": true, "records": ' + JSON.serialize(referrals) +'}},';
        }
        return toDeserialize.removeEnd(',') + ']';
    }

    static String getJsonStringForOppsWithContactRoles(List<Opportunity> opps, Integer rolesNumber) {
        String toDeserialize = '[';
        for (Opportunity opp : opps) {
            List<OpportunityContactRole> oppContactRoles = getFakeRelatedOppContactRoles(rolesNumber, opp.Id, opp.Primary_Member__c);
            toDeserialize += JSON.serialize(opp).removeEnd('}') + ',' + '"OpportunityContactRoles": {"totalSize": ' +
                                rolesNumber +', "done": true, "records": ' + JSON.serialize(oppContactRoles) +'}},';
        }
        return toDeserialize.removeEnd(',') + ']';
    }

    static String getJsonStringForOpps(List<Opportunity> opps) {
        String toDeserialize = '[';
        for (Opportunity opp : opps) {
            toDeserialize += JSON.serialize(opp) + ',';
        }
        return toDeserialize.removeEnd(',') + ']';
    }

    static List<Opportunity> getFakeOppsFromJson(String fakeJsonOpps) {
        return (List<Opportunity>) JSON.deserialize(fakeJsonOpps, List<Opportunity>.class);
    }

    static List<Opportunity> getFakeOpportunities(Integer numberOfRecords) {
        Account testAcc = TestingUtility.createAccount(new Map<String,Object>{'Id' => TestUtility.getFakeId(Account.SObjectType),
                                                                              'Name' => 'Test Account'}, false);
        Contact testCont = TestingUtility.createContact(new Map<String,Object>{'Id' => TestUtility.getFakeId(Contact.SObjectType),
                                                                               'LastName' => 'TestAccount',
                                                                               'AccountId' => testAcc.Id}, false);
        List<Opportunity> newOpps = new List<Opportunity>();
        for (Integer i = 0; i < numberOfRecords; i++) {
            newOpps.add(new Opportunity(Id = TestUtility.getFakeId(Opportunity.SObjectType),
                                        AccountId = testAcc.id,
                                        StageName = 'New',
                                        Name = 'Test Opp ' + i,
                                        Contract_Stage__c = 'Contract Signed',
                                        CloseDate = System.today().addDays(5),
                                        Referrer__c = TestUtility.getFakeId(Contact.SObjectType),
                                        Building__c = TestUtility.getFakeId(Building__c.SObjectType),
                                        Primary_Member__c = testCont.Id));
        }
        return newOpps;
    }

    static List<Referral__c> getFakeRelatedReferrals(Integer numberOfRelatedRefs, Id oppId, Id referrerId) {
        List<Referral__c> refs = new List<Referral__c>();
        for (Integer i = 0; i < numberOfRelatedRefs; i++) {
            refs.add(UtilReferral.constructReferral(new Map<String, Object>{ 'Id' => TestUtility.getFakeId(Referral__c.SObjectType),
                                                                             'Opportunity__c' => oppId,
                                                                             'Referrer__c' => referrerId,
                                                                             'Referral_Portal_Event__c' => 'Opportunity Creation' }));
        }
        return refs;
    }

    static List<OpportunityContactRole> getFakeRelatedOppContactRoles(Integer numberOfRelatedRoles, Id oppId, Id oppPrimaryMember) {
        List<OpportunityContactRole> roles = new List<OpportunityContactRole>();
        for (Integer i = 0; i < numberOfRelatedRoles; i++) {
            roles.add(new OpportunityContactRole(Id = TestUtility.getFakeId(OpportunityContactRole.SObjectType),
                                                 OpportunityId = oppId,
                                                 ContactId = oppPrimaryMember,
                                                 Role = 'Agency Broker'));
        }
        return roles;
    }
}