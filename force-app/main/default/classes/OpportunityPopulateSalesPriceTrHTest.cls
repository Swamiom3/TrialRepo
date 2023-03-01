/************************************************************************************************************************************
    Author 		: 	Shubham Nandwana
    Description : 	Test class for OpportunityPopulateSalesPriceTrH class.
    Issue No    :   TWSPG-5410
	----------------------------------------------------------------------------------------------------------------------------------
	VERSION		DATE				AUTHOR					DETAIL
    1			22 October 2021	    Shubham Nandwana     	Initial Development	 
**************************************************************************************************************************************/
@isTest
public class OpportunityPopulateSalesPriceTrHTest {
    private static final String BUILDING_UUID = 'a12c41ac-0359-4b93-9b48-425b3ff0082a';
    @testSetup
    static void makeData() {
        List<Account> accRecords = UtilAccount.getNewAccounts(1, true);
        List<Contact> lstContact = UtilContact.getNewContacts(1, accRecords[0], true);
        String pricebookId = Test.getStandardPricebookId();
        Building__c testBuildingWithUuid = new Building__c(Name = 'Test Building1', No_Longer_in_Use__c=false,
                                                   Address__c='123 Mission St', City__c='california',
                                                   Country__c='USA', Postal_Code__c='90168', State__c='california',
                                                   Time_Zone__c='America/New_York', Building_Price_Book_Id__c = pricebookId,
                                                   UUID__c = BUILDING_UUID);
        TestingUtility.insertWithAssert(testBuildingWithUuid, 'Building not inserted');
        Building__c testBuildingWithoutUuid = new Building__c(Name = 'Test Building2', No_Longer_in_Use__c=false,
                                                   Address__c='123 Mission St', City__c='california', 
                                                   Country__c='USA', Postal_Code__c='90168', State__c='california',
                                                   Building_Price_Book_Id__c = pricebookId,
                                                   Time_Zone__c='America/New_York', UUID__c = 'InvalidUUID');
        TestingUtility.insertWithAssert(testBuildingWithoutUuid, 'Building not inserted');
        
    }
	
    @isTest
    private static void checkWeWorkProductTest_test_positive () {
        Test.startTest();
        String pricebookId = Test.getStandardPricebookId();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponeGeneratorForRevstarAPI());
        Building__c building = [SELECT Id,UUID__c FROM Building__c WHERE UUID__c =: BUILDING_UUID];
        List<Account> accRecords = [SELECT Id,Name FROM Account];
        List<Opportunity> oppRecords = UtilOpportunity.GetNewOpportunity(1, accRecords.get(0), false);
        oppRecords.get(0).Building__c = building?.Id;
        oppRecords.get(0).Interested_in_Number_of_Desks__c = 2;
        oppRecords.get(0).Type__c = 'Wework';
        oppRecords.get(0).Pricebook2Id = pricebookId;
        oppRecords.get(0).LeadSource = null;
        insert oppRecords; 
        Test.stopTest();
        oppRecords = [SELECT Id,Name,Sales_Price__c, CurrencyIsoCode,Pricebook2Id FROM Opportunity 
                          WHERE AccountId =: accRecords.get(0).Id];
        System.assert(oppRecords.get(0).Sales_Price__c != null ,'Sales Price should not be null');
        System.assertEquals(450, oppRecords.get(0).Sales_Price__c,
                               'Sales Price should be custom and not default USD 500 OR USD 0 for correct UUID');
        System.assertEquals('EUR', oppRecords.get(0).CurrencyIsoCode, 'Currency is not populated correctly');
        System.assertEquals(oppRecords.get(0).Pricebook2Id, pricebookId, 'Pricebook should be restored');
    }
    
    @isTest
    private static void checkAllAccessTest_test_positive () {
        Test.startTest();
        String pricebookId = Test.getStandardPricebookId();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponeGeneratorForRevstarAPI());
        Building__c building = [SELECT Id,UUID__c FROM Building__c WHERE UUID__c =: BUILDING_UUID];
        List<Account> accRecords = [SELECT Id,Name FROM Account];
        List<Opportunity> oppRecords = UtilOpportunity.GetNewOpportunity(1, accRecords.get(0), false);
        oppRecords.get(0).Building__c = building?.Id;
        oppRecords.get(0).Interested_in_Number_of_Desks__c = 3;
        oppRecords.get(0).Type__c = GlobalConstants.ALL_ACCESS;
        oppRecords.get(0).Pricebook2Id = pricebookId;
        oppRecords.get(0).LeadSource = null;
        insert oppRecords; 
        Test.stopTest();
        oppRecords = [SELECT Id,Name,Sales_Price__c, CurrencyIsoCode,Pricebook2Id FROM Opportunity 
                          WHERE AccountId =: accRecords.get(0).Id];
        System.assert(oppRecords.get(0).Sales_Price__c != null ,'Sales Price should not be null');
        System.assertEquals(0, oppRecords.get(0).Sales_Price__c,
                               'Sales Price should be 0 as standard pricebook');
        System.assertEquals('USD', oppRecords.get(0).CurrencyIsoCode, 'Currency is not populated correctly');
        System.assertEquals(oppRecords.get(0).Pricebook2Id, pricebookId, 'Pricebook should be restored');
    }
    
    @isTest
    private static void checkProductTest_test_negative () {
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponeGeneratorForRevstarAPI());
        Building__c building = [SELECT Id,UUID__c FROM Building__c
                                WHERE Name =: 'Test Building2'];
        List<Account> accRecords = [SELECT Id,Name FROM Account];
        List<Opportunity> oppRecords = UtilOpportunity.GetNewOpportunity(1, accRecords.get(0), false);
        oppRecords.get(0).Building__c = building?.Id;
        insert oppRecords;
        Test.stopTest();
        oppRecords = [SELECT Id,Name,Sales_Price__c, CurrencyIsoCode FROM Opportunity 
                          WHERE AccountId =: accRecords.get(0).Id];
        System.assert(oppRecords.get(0).Sales_Price__c != null ,'Sales Price should not be null');
        System.assertEquals(0, oppRecords.get(0).Sales_Price__c,
                               'Sales Price should be default USD 0 for invalid UUID');
    } 
}