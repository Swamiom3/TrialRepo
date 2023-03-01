@isTest
public class OpportunityVtsTrHTest {
    
    @testSetup
    static void initData(){
        Account accRec = TestingUtility.createAccount('strAccountName', true);
        Contact conRec1 = new Contact(
            FirstName  = 'John1',
            LastName   = 'Rambq',
            Email     = 'testContactJohnR1@example.com',
            AccountId  = accRec.Id
        );
        Contact conRec2 = new Contact(
            FirstName  = 'John1',
            LastName   = 'Rambo2',
            Email     = 'testContactJohnR2@example.com',
            AccountId  = accRec.Id
        );
        insert new List<Contact>{conRec1, conRec2};
        Map<String,String> testBuildingInput = new Map<String,String>();
        testBuildingInput.put('Name','TestBuilding1');
        testBuildingInput.put('CurrencyIsoCode','USD');
        testBuildingInput.put('Address__c','Banner');
        testBuildingInput.put('City__c','Boston');
        testBuildingInput.put('UUID__c','4eb8144b-f461-4849-8b81-b5fa344fb978');
        testBuildingInput.put('Portfolio_Name__c','Mumbai1');
        testBuildingInput.put('Time_Zone__c','America/Chicago');
        testBuildingInput.put('Agency_Broker__c', conRec1.Id);
        Building__c testBuilding = TestingUtility.createBuilding(testBuildingInput, true);
    }
    
    @isTest
    private static void vtsContactRolesTest(){
        List<Contact> contacts = [SELECT Id, AccountId FROM Contact LIMIT 2];
        Building__c building = [SELECT Id, Agency_Broker__c FROM Building__c LIMIT 1];
        Opportunity opportunityToCreateVTS = TestingUtility.createOpportunity(new Map<String, Object> {
            'Name' => 'Enterprise Opportunity1',
            'Primary_Member__c' => contacts[1].Id, 
            'AccountId' => contacts[1].AccountId,
            'Opportunity_Creation_Source__c' => 'VTS',
            'Building__c' => building.Id,
            'StageName' => 'Qualifying'}, false
        );
        Opportunity opportunityToCreate = TestingUtility.createOpportunity(new Map<String, Object> {
            'Name' => 'Enterprise Opportunity1',
            'Primary_Member__c' => contacts[1].Id,
            'AccountId' => contacts[1].AccountId,
            'Building__c' => building.Id,
            'StageName' => 'Qualifying'}, false
        );
        
        Test.startTest(); 
        TestingUtility.insertListWithAssert(new List<Opportunity> {opportunityToCreate, opportunityToCreateVTS});
        Test.stopTest();

        List<OpportunityContactRole> contactRoles = [SELECT Id 
                                               FROM OpportunityContactRole
                                               WHERE OpportunityId IN (:opportunityToCreate.Id, :opportunityToCreateVTS.Id)];
        System.assertEquals(4, contactRoles.size(), 'Opportunity Contact Roles should be created.');

        List<Referral__c> referrals = [SELECT Id 
                                        FROM Referral__c
                                        WHERE Opportunity__c = :opportunityToCreate.Id];
        System.assertEquals(1, referrals.size(), 'Should be 1 Referral created only.');
        List<Referral__c> referralsVTS = [SELECT Id 
                                        FROM Referral__c
                                        WHERE Opportunity__c = :opportunityToCreateVTS.Id];
        System.assertEquals(1, referralsVTS.size(), 'Should be 1 Referral created only.');
    }
}