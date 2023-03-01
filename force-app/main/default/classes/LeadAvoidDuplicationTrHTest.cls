/*********************************************************************************************************
Author        :  Onkar Swami
Description   :  Test class for LeadAvoidDuplicationOnSameDayTrH
Issue No.     :  
History       :
-----------------------------------------------------------------------------------------------------------
VERSION        DATE            AUTHOR             DETAIL
1          28--Feb-2023      Onkar Swami          Handler
**********************************************************************************************************/

@isTest
public class LeadAvoidDuplicationTrHTest {
    @testSetup
    static void setup() {
        List<Lead> leads = new List<Lead>();
        Lead duplicateLead = new Lead(FirstName = 'Duplicate1', LastName = 'User11', Email = 'testuser11@test.com');
        leads.add(duplicateLead); // Add newLead to the list
        insert leads;
        
        List<Lead> yesterdayLeads = new List<Lead>();
        Lead yesterdayLead = new Lead(FirstName = 'YeasterDay', LastName = 'TestData', Email = 'yesterday@TestData.com', CreatedDate = Date.today().addDays(-1));
        yesterdayLeads.add(yesterdayLead); // Add newLead to the list
        insert yesterdayLeads;
    }
    @isTest
    private static void testAvoidDuplicationLead() {
        List<Lead> newLeads = getInsertedLeads();
        Test.startTest();
        LeadAvoidDuplicationOnSameDayTrH handler = new LeadAvoidDuplicationOnSameDayTrH();
        handler.newLead = newLeads;
        Test.stopTest();
        // Verify that the second lead was not inserted and has an error message
        List<Lead> leads = [SELECT Id, LastName, Email FROM Lead WHERE LastName = 'User11' AND Email = 'testuser11@test.com' AND CreatedDate = TODAY];
        
        System.assertEquals(1, leads.size(), 'only one should be inserted');
        System.assertNotEquals(2, leads.size(), 'only one should be inserted');
        System.assertNotEquals(newLeads[0].ID, leads[0].ID, 'The two leads should have different IDs');
    }
    @isTest
    private static void negativeTestCase(){
        List <Lead> getLeads = getInsertedTwoDifferentRecords();
        Test.startTest();
        LeadAvoidDuplicationOnSameDayTrH handler = new LeadAvoidDuplicationOnSameDayTrH();
        handler.newLead = getLeads;
        Test.stopTest();
        List<Lead> updatedLeads = [select id, LastName from Lead where CreatedDate = TODAY];
        System.AssertNotEquals(1 , updatedLeads.size(),'there will two records');
        System.AssertNotEquals(updatedLeads[0].LastName, updatedLeads[1].LastName, 'two different lastenames in this test method' );
    }
    @isTest
    private static void yesterdatDataTestCase(){
        List <Lead> getLeads = setDataLikeYesterdayForTestClass();
        Test.startTest();
        LeadAvoidDuplicationOnSameDayTrH handler = new LeadAvoidDuplicationOnSameDayTrH();
        handler.newLead = getLeads;
        Test.stopTest();
        List<Lead> leads = [SELECT Id, LastName, Email FROM Lead WHERE LastName = 'Yesterday' AND Email = 'yesterday@yesterday.com'];
        System.AssertNotEquals(1 , leads.size(), 'there is two data which is inserted yesterday and today');
    }
    
    //data for positive test case
    private static List<Lead> getInsertedLeads(){
        List<Lead> leads = new List<Lead>();
        Lead duplicateLead = new Lead(FirstName = 'Duplicate1', LastName = 'User11', Email = 'testuser11@test.com');
        leads.add(duplicateLead); // Add newLead to the list
        Database.insert(leads, false);
        return leads;
    }  
    //data insert as like yesteday data
    private static List<Lead> setDataLikeYesterdayForTestClass(){
        List<Lead> yesterdayLeads = new List<Lead>();
        Lead yesterdayLead = new Lead(
            FirstName = 'YeasterDay',
            LastName = 'TestData',
            Email = 'yesterday@TestData.com',
            Company = 'XYZ'
        );
        yesterdayLeads.add(yesterdayLead); // Add newLead to the list
        insert yesterdayLeads;
        return yesterdayLeads;
    }
     //data for Negative test case
    private static List<Lead> getInsertedTwoDifferentRecords(){
        List<Lead> leads = new List<Lead>();
        Lead lead1 = new Lead(FirstName = 'Duplicate1', LastName = 'User11', Email = 'testuser11@test.com');
        Lead lead2 = new Lead(FirstName = 'Duplicate2', LastName = 'Test2', Email = 'test21@test.com');
        leads.add(lead1);
        leads.add(lead2);
        Database.insert(leads, false);
        return leads;
    }
}