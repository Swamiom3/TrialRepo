/************************************************************************************************************************************
    Author       :  Shubham Nandwana   
    @Description :  Test class for OpportunityContactRole OppConRoleRestrictionsTrH
    Issue No     :  TWSPG-2928
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION     DATE                AUTHOR              ISSUE NO        DETAIL
    1           27 August 2021      Shubham Nandwana    TWSPG-2928      Initial Developement              
**************************************************************************************************************************************/
@isTest
public class OppConRoleRestrictionsTrHTest {
	@testSetup
    static void makeData(){
        Account account = TestingUtility.createAccount('test', true);
        Contact con = TestingUtility.createContact(account.Id, 'testContact', true);
        Opportunity opp = TestingUtility.createOpportunity(new Map<String, Object> 
                                                           {'Name' => 'Test Opportunity',
                                                               'Primary_Member__c' => con.Id,
                                                               'AccountId' => account.Id,
                                                               'Type__c' => GlobalConstants.WEWORK,
                                                               'closeDate' => System.today(),
                                                               'Contract_Stage__c' => 'Contract Sent',
                                                               'Referrer__c' => con.Id,
                                                               'Do_Not_Create_Opportunity_Role__c' => false},
                                                           true);
        List<OpportunityContactRole> ocrRecords = [SELECT Id,Role,OpportunityId
                                                   FROM OpportunityContactRole
                                                   WHERE opportunityId =: opp.Id];
        System.assertEquals(1, ocrRecords.size(), '1 OCR record is created');
        System.assertEquals('Main Contact', ocrRecords.get(0).Role, '1 OCR record is created');
    }
    	
    @isTest
    public static void oppConRoleRestricts_test_positive(){
        Test.startTest();
        List<Opportunity> opps = [SELECT id,name,Primary_Member__c,AccountId,Account.Primary_Contact__c FROM Opportunity];
        Contact con1 = TestingUtility.createContact(new Map<String, Object>{
            'FirstName' => 'First Name Test Contact',
            'LastName' => 'Test Contact',
            'Email' => 'TestEmail@test.com',
            'AccountId' => opps.get(0).accountId
        },true);
        OpportunityContactRole oppConRole = new OpportunityContactRole();
        oppConRole.OpportunityId = opps.get(0).Id;
        oppConRole.ContactId = con1.Id;
        oppConRole.Role = 'Business User';
        oppConRole.IsPrimary = true;
        insert oppConRole;
        List<OpportunityContactRole> ocrRecords = [SELECT Id,Role,OpportunityId
                                                   FROM OpportunityContactRole
                                                   WHERE opportunityId =: opps.get(0).Id];
        System.assertEquals(2, ocrRecords.size(), '2 OCR record should be created');
        Test.stopTest();
    }
    
    @isTest
    public static void oppConRoleRestricts_test_negative(){
        Test.startTest();
        try{
            List<Opportunity> opps = [SELECT id,name,Primary_Member__c,AccountId,Account.Primary_Contact__c FROM Opportunity];
            Contact con1 = TestingUtility.createContact(new Map<String, Object>{
                'FirstName' => 'First Name Test Contact',
                'LastName' => 'Test Contact',
                'Email' => 'TestEmail@test.com',
                'AccountId' => opps.get(0).accountId
            },true);
            OpportunityContactRole oppConRole = new OpportunityContactRole();
            oppConRole.OpportunityId = opps.get(0).Id;
            oppConRole.ContactId = con1.Id;
            oppConRole.Role = 'Business User';
            oppConRole.IsPrimary = true;
            insert oppConRole;
            List<OpportunityContactRole> ocrRecords = [SELECT Id,Role,OpportunityId
                                                       FROM OpportunityContactRole
                                                       WHERE opportunityId =: opps.get(0).Id];
            System.assertEquals(2, ocrRecords.size(), '2 OCR record should be created');
            
            oppConRole.Role = 'Main Contact';
            update oppConRole;
        }catch(Exception ex){
            System.assertEquals('System.DmlException', ex.getTypeName(), 'Error is not returned correctly');
            System.assert(ex.getMessage().contains('FIELD_CUSTOM_VALIDATION_EXCEPTION'), 'Custom error is not returned');
        }
        Test.stopTest();
    }
}