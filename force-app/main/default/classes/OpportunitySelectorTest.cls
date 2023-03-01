/*************************************************************************************************************************************
Author      :   Salesforce
Description :   This class provides sufficient test coverage for OpportunitySelector class
--------------------------------------------------------------------------------------------------------------------------------------
VERSION         DATE            AUTHOR              DETAIL
1               7/9/2021       Salesforce         Initial Deployment
**************************************************************************************************************************************/
@isTest
public class OpportunitySelectorTest {
	private static OpportunitySelector opportunitySelector = new OpportunitySelector();
    
    @testSetup
    static void makeData() {
        Account account = TestingUtility.createAccount('Acme', true);
        List<Building__c> buildings = new List<Building__c>();
        Building__c building = new Building__c(
            Name = 'testbuild-001',
            Building_ID__c = 'test234',
            UUID__c = 'test234',
            Time_Zone__c ='America/Denver'
        );
        buildings.add(building);
        Building__c building1 = new Building__c(
            Name = 'testbuild-002',
            Building_ID__c = 'test2345',
            UUID__c = 'test2345',
            Time_Zone__c ='America/Denver'
        );
        buildings.add(building1);
        insert buildings;
        Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        update standardPricebook;
        SBQQ__Quote__c quote = new SBQQ__Quote__c(
            Building_Id__c = building.Id,
            SBQQ__PricebookId__c = standardPricebook.Id,
            SBQQ__Account__c = account.Id
        );
        insert quote;
        ServiceContract serviceContract = new ServiceContract(
            Name = 'Test Service Contract',
            AccountId = account.Id,
            SBQQSC__Quote__c = quote.Id,
            StartDate = System.Now().date() - 1,
            EndDate = System.Now().date() + 10,
            Pricebook2Id = standardPricebook.Id,Building_Id__c =building.Id,
            SBQQSC__PreserveBundleStructureUponRenewals__c = true
        );
        insert serviceContract;

        List<Opportunity> opportunities = new List<Opportunity>();
        Opportunity replacementOpportunity = TestingUtility.createOpportunity(account.Id, false);
        replacementOpportunity.SBQQSC__AmendedServiceContract__c = serviceContract.Id;
        replacementOpportunity.Amendment_Opportunity_Type__c ='Replacement';
        replacementOpportunity.StageName = 'Closed Won';
        replacementOpportunity.Building__c = building.Id;
        opportunities.add(replacementOpportunity);
        
        Opportunity cancelationOpportunity = TestingUtility.createOpportunity(account.Id, false);
        cancelationOpportunity.SBQQSC__AmendedServiceContract__c = serviceContract.Id;
        cancelationOpportunity.Amendment_Opportunity_Type__c ='Cancellation';
        opportunities.add(cancelationOpportunity);

        Opportunity opportunityWithBuilding = TestingUtility.createOpportunity(account.Id, false);
        opportunityWithBuilding.Building__c = building1.Id;
        opportunityWithBuilding.StageName = 'Closing';
        opportunities.add(opportunityWithBuilding);

        insert opportunities;

        Contact contactForContactRole = TestingUtility.createContact(account.Id, 'Test Last Name', true);

        OpportunityContactRole oppConRole = new OpportunityContactRole();
        oppConRole.OpportunityId = opportunityWithBuilding.Id;
        oppConRole.ContactId = contactForContactRole.Id;
        oppConRole.Role = 'Billing Contact';
        oppConRole.IsPrimary = true;
        insert oppConRole;


        Opportunity cancelOpportunity = new Opportunity(Id= opportunities.get(1).Id);
        cancelOpportunity.Replacement_Opportunity__c = opportunities.get(0).Id;
        update cancelOpportunity;

        Referral__c oppReferral = UtilReferral.constructReferral(new Map<String, Object>{ 'Opportunity__c' => opportunities.get(0).Id });
        insert oppReferral;
        Opportunity_Reservable__c oppReservable = new Opportunity_Reservable__c(Opportunity__c = opportunities.get(0).Id,
                                                                                Commitment_Start_Date__c = Date.newInstance(2021, 04, 25));
        insert oppReservable;

        insert new Task(
            WhatId = opportunities.get(0).Id,
            Subject = 'Follow up',
            Status = 'In Progress',
            Type = 'Other'
        );

        insert new OpportunityTeamMember(
            OpportunityId = opportunities.get(1).Id, 
            UserId = UserInfo.getUserId(), 
            TeamMemberRole = 'Account Manager'
        );
        
    }

    @isTest
    static void testGetCancellationOpportunities() {
        Opportunity replacementOpportunity = [SELECT Id FROM Opportunity WHERE Amendment_Opportunity_Type__c ='Replacement' LIMIT 1];
        Set<Id> closedReplacementOppIds = new set<Id>{replacementOpportunity.Id};
        List<Opportunity> opportunities = opportunitySelector.getCancellationOpportunities('Cancellation',closedReplacementOppIds,'Closed Won');
        System.assert(!opportunities.isEmpty(), 'Opportunities not retrieved');
    }

    @isTest
    public static void testGetOpportinitiesWithRefs() {
        Id opportunityId = [SELECT Id FROM Opportunity LIMIT 1].Id;
        Test.startTest();
        Opportunity opp = opportunitySelector.getOppsWithRelatedReferrals(new Set<Id>{opportunityId})[0];
        Test.stopTest();
        System.assert(!opp.Referrals__r.isEmpty(), ' Related referrals list must not be empty');
    }

    @isTest
    public static void testGetOpportunitiesWithTeamMembers() {
        Id opportunityId = [SELECT Id FROM Opportunity WHERE Amendment_Opportunity_Type__c ='Cancellation' LIMIT 1].Id;
        Test.startTest();
        Opportunity resOpp = opportunitySelector.getOpportunitiesWithTeamMembers(new Set<Id>{opportunityId})[0];
        Test.stopTest();
        System.assert(!resOpp.OpportunityTeamMembers.isEmpty(), ' Related OpportunityTeamMembers must not be empty');
    }

    @isTest
    public static void testGetOpportunitiesWithRelatedActivities() {
        Id opportunityId = [SELECT Id FROM Opportunity WHERE Amendment_Opportunity_Type__c ='Replacement' LIMIT 1].Id;
        Test.startTest();
        Opportunity resOpp = opportunitySelector.getOpportunitiesWithRelatedActivities(new Set<Id>{opportunityId})[0];
        Test.stopTest();
        System.assert(!resOpp.Tasks.isEmpty(), ' Related Tasks must not be empty');
    }

    @isTest  
    public static void testGetOpportunityLocationFieldsById() {
        Id opportunityId = [SELECT Id FROM Opportunity WHERE StageName = 'Closed Won' LIMIT 1].Id;
        Test.startTest();
        List<Opportunity> resOpps = opportunitySelector.getOpportunityLocationFieldsById(opportunityId);
        Test.stopTest();
        System.assert(!resOpps.isEmpty(), 'Opportunities list must not be empty');
        System.assertEquals([SELECT Id FROM Building__c WHERE Name = 'testbuild-001'].Id, resOpps[0].Building__c, 'Building filed on Opportunity must lookup into Building created');
    }

    @isTest
    static void testGetOpportunitiesWithContactRolesByBuildIds(){
        Map<Id, Building__c> buildings = new Map<Id, Building__c>([SELECT Id FROM Building__c WHERE Name = 'testbuild-002']);

        Test.startTest();
        List<Opportunity> opps = opportunitySelector.getOpportunitiesWithContactRolesByBuildIds(
            buildings.keySet(),
            new List<String>{ GlobalConstants.OPP_CLOSED_WON_STAGE_NAME, GlobalConstants.OPP_CLOSED_LOST_STAGE_NAME }
        );
        Test.stopTest();

        System.assert(!opps.isEmpty(), 'Opportunities should be returned');
        System.assert(!opps[0].OpportunityContactRoles.isEmpty(), 'OpportunityContactRoles should be returned');
    }

    @isTest
    static void getOppParentAccount_test_positive() {
        Map<String, Object> ultimateAccountFieldValues = new Map<String, Object> {'Name' => 'Ultimate Account','Account_Type__c' => 'Org'};
        Account ultimateAccount = TestingUtility.createAccount(ultimateAccountFieldValues, true);
        Account parentAccount = TestingUtility.createAccount('Parent Account', false);
        parentAccount.ParentId = ultimateAccount.Id;
        parentAccount.Account_Type__c = 'Org';
        insert parentAccount;
        Opportunity opportunityRecord = TestingUtility.createOpportunity(parentAccount.Id, true);
        Opportunity oppResult = opportunitySelector.getOppParentAccount(opportunityRecord.Id);
        System.assertEquals(parentAccount.Id, oppResult.AccountId);
    }
    
    @isTest
    static void getOppParentAccount_test_negative() {
        Opportunity oppResult = opportunitySelector.getOppParentAccount(null);
        System.assertEquals(null, oppResult);
    }

    @isTest
    static void testGetSelfServeOppsByAccountIds(){
        Account acc = [SELECT Id FROM Account LIMIT 1];
        List<Opportunity> opps = [SELECT Id, AccountId, Lead_Source_Detail__c FROM Opportunity LIMIT 2];
        opps[0].AccountId = acc.Id;
        opps[1].AccountId = acc.Id;
        opps[0].Lead_Source_Detail__c = 'Self Serve';
        opps[1].Lead_Source_Detail__c = 'Self Serve';
        update opps;

        Test.startTest();
        List<Opportunity> oppsNew = opportunitySelector.getSelfServeOppsByAccountIds(new Set<Id>{acc.Id});
        Test.stopTest();
        System.assertNotEquals(null, oppsNew, 'Result Ids Opportunities must not be null');
        System.assertEquals(2, oppsNew.size(), 'The number of Opportunitie Ids should be 2');
    }
}