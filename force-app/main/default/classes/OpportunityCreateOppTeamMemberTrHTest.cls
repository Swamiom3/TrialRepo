/************************************************************************************************************************************
    Author      :   Pragalbha Mahajan
    Description :   This class contains all test methods related to OpportunityCreateOppTeamMemberTrH class.
    History		:
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION     DATE                AUTHOR                  DETAIL
    1           09 Jan 2019         Pragalbha Mahajan       Initial Development
    2			30 Oct 2019         Roshan Kankrayane       Modified
    3			05 Jun 2019         Ashish Sharma           ST-6394
    4           09 Nov 2020         Liubomyr Mishchykha     refactored due to new framework
    6           05 Nov 2021         Oleksandr Liesnik       refactored to use MockServise framework
************************************************************************************************************************************/
@isTest
public class OpportunityCreateOppTeamMemberTrHTest {

    private static final String testUserUsername = 'testuserjohn123@example.com';

    @testSetup
    static void makeData() {
        User testUser = UtilUser.createUser([SELECT Id FROM Profile WHERE Name = 'WeWork Inside Sales'].Id, false);
        testUser.Username = testUserUsername;
        insert testUser;
    }

    @isTest
    private static void testCreateOpportunityTeamMember() {
        Id testUserId = [SELECT Id FROM User WHERE Username = :testUserUsername].Id;
        Map<Id, Opportunity> oldOpportunities = new Map<Id, Opportunity>();
        List<OpportunityTeamMember> teamMembers = new List<OpportunityTeamMember>();
        Account acc = createFakeAccount(testUserId);
        List<Contact> contacts = createFakeContacts(3);
        List<Opportunity> opps = createFakeOpportunities(10, acc.Id);
        String formula = '"_ahre_f=_' + testUserId + '_"';
        List<Opportunity> newOpportunities = getFakeOppsWithTeamMembersFromJson(getJsonStringForOppsWithTeamMembers(opps, 2, testUserId, formula));
        Boolean isEven = true;
        for (Opportunity opp : newOpportunities) {
            opp.OwnerId = UserInfo.getUserId();
            Opportunity oldOpp = opp.clone(true, true);
            if (isEven = !isEven) {
                opp.OwnerId = testUserId;
            }
            teamMembers.addAll(opp.OpportunityTeamMembers);
            oldOpportunities.put(oldOpp.Id, oldOpp);
        }
        newOpportunities[7].StageName = 'Closed Won';
        OpportunityHelper.lstOpportunityTeamMembers = teamMembers;
        OpportunityCreateOppTeamMemberTrH opportunityCreateOppTeamMember = new OpportunityCreateOppTeamMemberTrH(newOpportunities, oldOpportunities);
        opportunityCreateOppTeamMember.contactSelector = (ContactSelector) MockService.createMock(
                                                          ContactSelector.class,
                                                          new Map<String, Object>{
                                                          'getContactsByIds' => contacts });
        opportunityCreateOppTeamMember.opportunitySelector = (OpportunitySelector) MockService.createMock(
                                                              OpportunitySelector.class,
                                                              new Map<String, Object>{
                                                              'getOpportunitiesWithTeamMembers' => newOpportunities});
        opportunityCreateOppTeamMember.oppTeamMemberSelector = (OpportunityTeamMemberSelector) MockService.createMock(
                                                                OpportunityTeamMemberSelector.class,
                                                                new Map<String, Object>{
                                                                'getExistingOpportunityTeamMemberIds' => teamMembers});
        Test.startTest();
        opportunityCreateOppTeamMember.addCoOwnersOnNamedAccountSegmentOpportunity();
        opportunityCreateOppTeamMember.setTriggerContext('after update', true);
        opportunityCreateOppTeamMember.getChildOpportunityTeamMembers();
        opportunityCreateOppTeamMember.opportunityTeamMembersToInsert = new List<OpportunityTeamMember>();
        opportunityCreateOppTeamMember.opportunityTeamMembersToUpdate = new List<OpportunityTeamMember>();
        opportunityCreateOppTeamMember.mapContactIdsToUsers();
        opportunityCreateOppTeamMember.createOpportunityTeamMember();
        Test.stopTest();
        System.debug('opp team members to insert' + opportunityCreateOppTeamMember.opportunityTeamMembersToInsert);
        System.assertEquals(30, opportunityCreateOppTeamMember.opportunityTeamMembersToInsert.size());
    }

    @isTest
    private static void testCreateGlobalAccountsOpportunityTeamMembers() {
        User testUser = [SELECT Id, Sales_Role__c FROM User WHERE Username = :testUserUsername];
        Account testAccount = createFakeAccount(testUser.Id);
        List<Opportunity> opps = createFakeOpportunities(10, testAccount.Id);
        String formula = '"_ahre_f=_' + testUser.id + '_"';
        List<Opportunity> newOpportunities = getFakeOppsWithTeamMembersFromJson(getJsonStringForOppsWithTeamMembers(opps, 1, testUser.Id, formula));
        AccountTeamMember accountTeamMember = TestingUtility.getAccountTeamMember(testAccount.Id, testUser, 'Inside Sales', null, null);
        OpportunityCreateOppTeamMemberTrH opportunityCreateOppTeamMember = new OpportunityCreateOppTeamMemberTrH(newOpportunities, null);
        opportunityCreateOppTeamMember.opportunityTeamMembersToInsert = new List<OpportunityTeamMember>();
        opportunityCreateOppTeamMember.accTeamMemberSelector = (AccountTeamMemberSelector) MockService.createMock(
                                                                AccountTeamMemberSelector.class,
                                                                new Map<String, Object>{
                                                                'getAccountTeamMembersWithGlobalAccount' => new List<AccountTeamMember>{ accountTeamMember}});
        Test.startTest();
        opportunityCreateOppTeamMember.createGlobalAccountsOpportunityTeamMembers(newOpportunities, new Set<Id>{ testAccount.Id });
        Test.stopTest();
        System.assertEquals(10, opportunityCreateOppTeamMember.opportunityTeamMembersToInsert.size());
        System.assertEquals('co-owner', opportunityCreateOppTeamMember.opportunityTeamMembersToInsert[5].TeamMemberRole);
    }

    @isTest
    private static void testCreateNonGlobalAccountsOpportunityTeamMembers() {
        User testUser = [SELECT Id FROM User WHERE Username = :testUserUsername];
        List<FormulaRecalcResult> results2 = Formula.recalculateFormulas(new List<user>{testUser});
        Account testAccount = createFakeAccount(testUser.Id);
        List<Opportunity> opps = createFakeOpportunities(10, testAccount.Id);
        String formula = '"_ahre_f=_' + testUser.id + '_"';
        String fakeOpps = getJsonStringForOppsWithFormulaField(opps, formula);
        List<Opportunity> newOpportunities = getFakeOppsWithTeamMembersFromJson(fakeOpps);
        OpportunityCreateOppTeamMemberTrH opportunityCreateOppTeamMember = new OpportunityCreateOppTeamMemberTrH(newOpportunities, null);
        opportunityCreateOppTeamMember.opportunityTeamMembersToInsert = new List<OpportunityTeamMember>();
        Test.startTest();
        opportunityCreateOppTeamMember.createNonGlobalAccountsOpportunityTeamMembers(newOpportunities);
        Test.stopTest();
        System.assertEquals(10, opportunityCreateOppTeamMember.opportunityTeamMembersToInsert.size());
        System.assertEquals('co-owner', opportunityCreateOppTeamMember.opportunityTeamMembersToInsert[5].TeamMemberRole);
        System.assertEquals(testUser.Id, opportunityCreateOppTeamMember.opportunityTeamMembersToInsert[9].UserId);
    }

    static List<Opportunity> getFakeOppsWithTeamMembersFromJson(String fakeJsonOpps) {
        return (List<Opportunity>) JSON.deserialize(fakeJsonOpps, List<Opportunity>.class);
    }

    static String getJsonStringForOppsWithTeamMembers(List<Opportunity> opps, Integer teamMembersNumber, Id userId, String formulaField) {
        String toDeserialize = '[';
        Boolean isEven = true;
        for (Opportunity opp : opps) {
            String accSegment = 'Global Account';
            isEven = !isEven;
            if (isEven) {
                accSegment = 'Community Account';
            }
            List<OpportunityTeamMember> oppTeamMembers = createFakeOppTeamMembers(teamMembersNumber, opp.Id, userId);
            toDeserialize += JSON.serialize(opp).removeEnd('}') + ',' + 
                             '"CreatedById": "' + ApiUsersUtils.apiUserId + '",' +
                             '"Named_Account_Segment__c": "'+ accSegment + '",' +
                             '"Account_Owner__c": ' + formulaField + ',' +
                             '"OpportunityTeamMembers": {"totalSize": ' + teamMembersNumber +', "done": true, "records": ' + JSON.serialize(oppTeamMembers) + '}},';
        }
        return toDeserialize.removeEnd(',') + ']';
    }

    static String getJsonStringForOppsWithFormulaField(List<Opportunity> opps, String field) {
        String toDeserialize = '[';
        for (Opportunity opp : opps) {
            toDeserialize += JSON.serialize(opp).removeEnd('}') + ',' + 
                            '"Account_Owner__c": ' + field + '},';
        }
        return toDeserialize.removeEnd(',') + ']';
    }

    static User createFakeUser(Id profileId) {
        return new User(Id = TestUtility.getFakeId(User.SObjectType),
                        FirstName = 'TestUser',
                        LastName = 'Tony',
                        ProfileId = profileId );
    }

    static Account createFakeAccount(Id ownerId) {
            return new Account( Id = TestUtility.getFakeId(Account.SObjectType),
                                Name = 'Test Account',
                                Named_Account_Segment__c = 'Global Account',
                                OwnerId = ownerId);
    }

    static List<Contact> createFakeContacts(Integer numberOfRecords) {
        List<Contact> contacts = new List<Contact>();
        for (Integer i = 0; i < numberOfRecords; i++) {
            contacts.add(new Contact(Id = TestUtility.getFakeId(Contact.SObjectType),
                                     Email = 'testmail' + i + '@example.com'));
        }
        return contacts;
    }

    static List<Opportunity> createFakeOpportunities(Integer numberOfRecords, Id accountId) {
        List<Opportunity> newOpps = new List<Opportunity>();
        for (Integer i = 0; i < numberOfRecords; i++) {
            String recTypeId;
            if (Math.mod(i, 2) == 0) {
                recTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('New Business').getRecordTypeId();
            } else {
                recTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Renewal').getRecordTypeId();
            }
            newOpps.add(new Opportunity(Id = TestUtility.getFakeId(Opportunity.SObjectType),
                                        AccountId = accountId,
                                        StageName = 'New',
                                        Name = 'Test Opp ' + i,
                                        Contract_Stage__c = 'Contract Signed',
                                        CloseDate = System.today().addDays(5),
                                        //IsRenewalOpportunity__c = false,
                                        Interested_in_Number_of_Desks__c = 12,
                                        RecordTypeId = recTypeId,
                                        Referrer__c = TestUtility.getFakeId(Contact.SObjectType),
                                        Building__c = TestUtility.getFakeId(Building__c.SObjectType),
                                        Primary_Member__c = TestUtility.getFakeId(Contact.SObjectType),
                                        Tour_Booked_By__c = TestUtility.getFakeId(Contact.SObjectType)));
        }
        return newOpps;
    }

    static List<OpportunityTeamMember> createFakeOppTeamMembers(Integer numberOfRecords, Id opportunityId, Id userId) {
        List<OpportunityTeamMember> oppTeamMembers = new List<OpportunityTeamMember>();
        for (Integer i = 0; i < numberOfRecords; i++) {
            oppTeamMembers.add(new OpportunityTeamMember(Id = TestUtility.getFakeId(OpportunityTeamMember.getSObjectType()),
                                                         OpportunityId = opportunityId, 
                                                         UserId = userId));
        }
        return oppTeamMembers;
    }
    
}