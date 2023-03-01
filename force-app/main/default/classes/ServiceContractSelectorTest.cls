/*************************************************************************************************************************************
 Author      :   Shubham Nandwana
 Description :   This class is selector implementation of particular SObject (ServiceContract)
 --------------------------------------------------------------------------------------------------------------------------------------
 VERSION         DATE            AUTHOR              DETAIL
 1               11/24/2021      Shubham Nandwana    Initial Deployment
 **************************************************************************************************************************************/
@isTest
public class ServiceContractSelectorTest {
	private static ServiceContractSelector serviceContractSelector = new ServiceContractSelector();
	private static final String BUILDING_UUID = 'a12c41ac-0359-4b93-9b48-425b3ff0082a';
    
    @TestSetup
    static void makeData(){
        List<Account> accounts = UtilAccount.getNewAccounts(1, true);
        Building__c testBuildingWithUuid = new Building__c(Name = 'Test Building1', No_Longer_in_Use__c=false,
                                                   Address__c='123 Mission St', City__c='california',
                                                   Country__c='USA', Postal_Code__c='90168', State__c='california',
                                                   Time_Zone__c='America/New_York', UUID__c = BUILDING_UUID);
        insert testBuildingWithUuid;
        ServiceContract servContract = new ServiceContract();
        servContract.Name = 'Test Contract';
        servContract.Building_Id__c = testBuildingWithUuid.Id;
        insert servContract;
    }
    
    @isTest
    private static void getServiceContractsById(){
        List<ServiceContract> serviceContracts;
        Test.startTest();
        Building__c building = [SELECT Id, Name FROM Building__c limit 1];
        ServiceContract servContract = [SELECT Id, Building_Id__c FROM ServiceContract limit 1];
        serviceContracts = serviceContractSelector.getServiceContractsByIds(new List<Id> {servContract.Id});
        Test.stopTest();
        System.assertEquals(building.Id, serviceContracts.get(0).Building_Id__c, 'Building is not returned correctly');
    }

    @isTest
    private static void testGetServiceContractsMapByIds(){
        Map<Id,ServiceContract> serviceContracts;
        Test.startTest();
        Building__c building = [SELECT Id, Name FROM Building__c limit 1];
        ServiceContract servContract = [SELECT Id, Building_Id__c FROM ServiceContract limit 1];
        serviceContracts = serviceContractSelector.getServiceContractsMapByIds(new List<Id> {servContract.Id});
        Test.stopTest();
        System.assertEquals(building.Id, serviceContracts.get(servContract.Id).Building_Id__c, 'Building is not returned correctly');
    }
}