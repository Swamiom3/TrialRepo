/************************************************************************************************************************************
    Author 		:   Shubham Nandwana
    Description : 	This class updates the building from Service Contract when created via CPQ Amendment API 
    Issue No    :   TWSPG-6254
	----------------------------------------------------------------------------------------------------------------------------------
	VERSION		DATE				AUTHOR					DETAIL
    1			19 November 2021	Shubham Nandwana     	Initial Development	 
**************************************************************************************************************************************/
@isTest
public class OppUpdBuildingFromAmendmentTrHTest {
    private static final String BUILDING_UUID = 'a12c41ac-0359-4b93-9b48-425b3ff0082a';
	@testSetup
    static void makeData() {
        List<Account> accounts = UtilAccount.getNewAccounts(1, true);
        Building__c testBuildingWithUuid = new Building__c(Name = 'Test Building1', No_Longer_in_Use__c=false,
                                                   Address__c='123 Mission St', City__c='california',
                                                   Country__c='USA', Postal_Code__c='90168', State__c='california',
                                                   Time_Zone__c='America/New_York', UUID__c = BUILDING_UUID);
        insert testBuildingWithUuid;
    }
    
    @isTest
    private static void updateBuildingFromSerCon_test_positive(){
        Test.startTest();
        Building__c building = [SELECT Id,UUID__c FROM Building__c WHERE UUID__c =: BUILDING_UUID];
        ServiceContract serviceContract = new ServiceContract();
        serviceContract.Name = 'Test Contract';
        serviceContract.Building_Id__c = building.Id;
        insert serviceContract;
        List<Account> accounts = [SELECT Id, Name FROM Account];
        Map<String, Object> opportunityRecordsFieldMappings = new Map<String, Object>{'SBQQSC__AmendedServiceContract__c' => serviceContract.Id,
            									      'Interested_in_Number_of_Desks__c' => 2,
            									      'Type__c' => 'Wework'};
        List<Opportunity> oppRecords = UtilOpportunity.GetNewOpportunityWithFieldMapping(1, accounts[0], opportunityRecordsFieldMappings, true);
        Opportunity oppRecord = oppRecords.get(0);
        Test.stopTest();
        oppRecords = [SELECT Id, Building__c FROM Opportunity];
        System.assertEquals(building.Id, oppRecords.get(0).Building__c, 'Building should be updated on opportunity');
    }
    
    @isTest
    private static void updateBuildingFromSerCon_test_negative(){
        Test.startTest();
        ServiceContract serviceContract = new ServiceContract();
        serviceContract.Name = 'Test Contract';
        List<Account> accounts = [SELECT Id, Name FROM Account];
        Map<String, Object> opportunityRecordsFieldMappings = new Map<String, Object>{'SBQQSC__AmendedServiceContract__c' => serviceContract.Id,
            									      'Interested_in_Number_of_Desks__c' => 2,
            									      'Type__c' => 'Wework'};
        List<Opportunity> oppRecords = UtilOpportunity.GetNewOpportunityWithFieldMapping(1, accounts[0], opportunityRecordsFieldMappings, true);
        Opportunity oppRecord = oppRecords.get(0);
        Test.stopTest();
        oppRecords = [SELECT Id, Building__c FROM Opportunity];
        System.assertEquals(null, oppRecords.get(0).Building__c, 'Building should not be updated on opportunity');
    } 
}