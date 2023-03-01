/************************************************************************************************************************************
    Author 	    :   Salesforce
    Description :   Test class for OpportunityPricebookUpdateTrH class.
    Issue No    :   TWSPG-5031
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION	    DATE			    AUTHOR          DETAIL
    1		    1 November 2021	    Salesforce      Initial Development
    **************************************************************************************************************************************/
@isTest
public class OpportunityPricebookUpdateTrHTest {
    @testSetup
    static void makeData() {
        List<Account> Accounts = UtilAccount.getNewAccounts(1, true);
        List<Contact> Contacts = UtilContact.getNewContacts(1, Accounts[0], true);
        Id testPricebook = Test.getStandardPricebookId();
        Building__c testBuilding = new Building__c(Name = 'Test Building1', No_Longer_in_Use__c=false,
                                                   Address__c='123 Mission St', City__c='california',
                                                   Country__c='USA', Postal_Code__c='90168', State__c='california',
                                                   Time_Zone__c='America/New_York',Building_Price_Book_Id__c = testPricebook);
        TestingUtility.insertWithAssert(testBuilding, 'Building not inserted');
    }

    @isTest
    private static void updateOpportunityPricebook_test_positive () {
        Test.startTest();
        Building__c building = [SELECT Id,Building_Price_Book_Id__c FROM Building__c LIMIT 1];
        List<Account> Accounts = [SELECT Id,Name FROM Account];
        List<Opportunity> opportunities = UtilOpportunity.GetNewOpportunity(1, Accounts.get(0), false);
        opportunities.get(0).Building__c = building?.Id;
        opportunities.get(0).Interested_in_Number_of_Desks__c = 2;
        opportunities.get(0).Type__c = 'Wework';
        insert opportunities;
        Test.stopTest();
        Opportunity opportunityToVerify = [SELECT Id,Name,Pricebook2Id, CurrencyIsoCode FROM Opportunity
                          WHERE Id =:opportunities.get(0).Id];
        System.assert(opportunityToVerify.Pricebook2Id == building.Building_Price_Book_Id__c,'Pricebook on Opportunity should be same as building');
    }

    @isTest
    private static void updateOpportunityPricebook_test_negative () {
        Test.startTest();
        Building__c building = [SELECT Id,Building_Price_Book_Id__c FROM Building__c LIMIT 1];
        List<Account> Accounts = [SELECT Id,Name FROM Account];
        List<Opportunity> opportunities = UtilOpportunity.GetNewOpportunity(1, Accounts.get(0), false);
        opportunities.get(0).Interested_in_Number_of_Desks__c = 2;
        opportunities.get(0).Type__c = 'Wework';
        insert opportunities;
        Test.stopTest();
        Opportunity opportunityToVerify = [SELECT Id,Name,Pricebook2Id, CurrencyIsoCode FROM Opportunity
                          WHERE Id =:opportunities.get(0).Id];
        System.assert(opportunityToVerify.Pricebook2Id != building.Building_Price_Book_Id__c ,'Pricebook on Opportunity should not be same as building');
    }
}