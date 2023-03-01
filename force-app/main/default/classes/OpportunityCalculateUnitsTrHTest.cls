/*************************************************************************************************************************************
    Author      :   ---
    Description :   This class provides sufficient test coverage for OpportunityCalculateUnitsTrH class
    --------------------------------------------------------------------------------------------------------------------------------------
    VERSION    DATE            AUTHOR            DETAIL
    2          10 Mar, 2022    Pawel Biszczak    Refactor
**************************************************************************************************************************************/
@isTest
public class OpportunityCalculateUnitsTrHTest {
    @testSetup
    static void initData(){
        List<Account> accountsToCreate = TestingUtility.createAccounts( 1, 'WeWork', false);
        TestingUtility.insertListWithAssert(accountsToCreate);

        List<Contact> contactsToCreate = new List<Contact>();
        contactsToCreate.add(TestingUtility.createContact(
                new Map<String, Object>{
                        'FirstName' => 'Paul',
                        'LastName' => 'enterpriseBoss',
                        'Email' => 'paul@enterpriseBoss.com',
                        'AccountId' => accountsToCreate[0].Id,
                        'UUID__c' => 'xxx123'
                },
                false));
        TestingUtility.insertListWithAssert(contactsToCreate);
    }

    @isTest
    public static void testBasicInsert() {
        Opportunity opportunityToCreate = new Opportunity();
        Contact contactForOpportunity = [SELECT Id, AccountId FROM Contact LIMIT 1];
        opportunityToCreate = TestingUtility.createOpportunity(
                new Map<String, Object>{
                        'Name' => 'Enterprise Opportunity1',
                        'Primary_Member__c' => contactForOpportunity.Id,
                        'AccountId' => contactForOpportunity.AccountId,
                        'closeDate' => System.today(),
                        'Contract_Stage__c' => 'Contract Sent'
                },
                false);

        Test.startTest();
        try {
            TestingUtility.insertListWithAssert(new List<Opportunity> {opportunityToCreate});
            System.assert(true);
        } catch (Exception e) {
            System.assert(false);
        }
        Test.stopTest();
    }

    @isTest
    public static void testUsfToUsmInsert() {
        Opportunity opportunityToCreate = new Opportunity();
        Contact contactForOpportunity = [SELECT Id, AccountId FROM Contact LIMIT 1];
        opportunityToCreate = TestingUtility.createOpportunity(
                new Map<String, Object>{
                        'Name' => 'Enterprise Opportunity1',
                        'Primary_Member__c' => contactForOpportunity.Id,
                        'AccountId' => contactForOpportunity.AccountId,
                        'closeDate' => System.today(),
                        'Contract_Stage__c' => 'Contract Sent'
                },
                false);
        opportunityToCreate.Original_Quantity__c = 100;
        opportunityToCreate.Opportunity_Creation_Source__c = GlobalConstants.OPPORTUNITY_CREATION_SOURCE_VTS;

        Test.startTest();
        TestingUtility.insertListWithAssert(new List<Opportunity> {opportunityToCreate});
        Test.stopTest();

        Opportunity toCheck = [SELECT Id, Interested_in_Number_of_Desks__c FROM Opportunity WHERE Id =: opportunityToCreate.Id];
        System.assertEquals(Integer.valueOf(Math.ceil(100 * CalculateUnitsService.DESK_IN_USF)), toCheck.Interested_in_Number_of_Desks__c);
    }

    @isTest
    public static void testDesksToUsf() {
        Opportunity opportunityToCreate = new Opportunity();
        Contact contactForOpportunity = [SELECT Id, AccountId FROM Contact LIMIT 1];
        opportunityToCreate = TestingUtility.createOpportunity(
                new Map<String, Object>{
                        'Name' => 'Enterprise Opportunity1',
                        'Primary_Member__c' => contactForOpportunity.Id,
                        'AccountId' => contactForOpportunity.AccountId,
                        'closeDate' => System.today(),
                        'Contract_Stage__c' => 'Contract Sent'
                },
                false);
        opportunityToCreate.Original_Quantity__c = 100;
        opportunityToCreate.Opportunity_Creation_Source__c = 'Test';

        Test.startTest();
        TestingUtility.insertListWithAssert(new List<Opportunity> {opportunityToCreate});
        Test.stopTest();

        Opportunity toCheck = [SELECT Id,  Interested_in_Number_of_Desks__c, Original_Quantity__c FROM Opportunity WHERE Id =: opportunityToCreate.Id];
        System.assertEquals(Integer.valueOf(Math.ceil(opportunityToCreate.Original_Quantity__c)) , toCheck.Interested_in_Number_of_Desks__c);
    }
}