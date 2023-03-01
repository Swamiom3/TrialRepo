/*********************************************************************************************************
	Author        :  Ishwar Shinde
	Description   :  Test class for TourStatusUpdateOpportunityStageTrH
	Issue No.     :  TWSPG-9281
	History       :
-----------------------------------------------------------------------------------------------------------
	VERSION        DATE            AUTHOR             DETAIL
	1          11-Apr-2022      Ishwar Shinde    Initial Developement
**********************************************************************************************************/
@isTest
public class TourStatusUpdateOpportunityStageTrHTest {
    @TestSetup
    static void initData(){
        Account account = new Account();
        account.Name = 'Test John';
        insert account;
        Map<String, Object> contactFieldValues = new Map<String, Object>();
        List<Contact> contacts = new List<Contact>();
        contactFieldValues.put('firstname', 'test');
        contactFieldValues.put('lastname', 'Contact');
        contactFieldValues.put('AccountId', account.Id);
        contactFieldValues.put('email', 'joinus@wework.com');
        contactFieldValues.put('Status__c', 'active');
        contactFieldValues.put('UUID__c', 'UUID1');
        contacts.add((Contact)TestingUtility.createTestRecords(Contact.sObjectType,contactFieldValues,false));
        TestingUtility.insertListWithAssert(contacts);
        
        Opportunity testOpportunities = UtilOpportunity.GetNewOpportunity(1, account, true)[0];
        
        ServiceAppointment appointment = new ServiceAppointment();
        appointment.ContactId = contacts[0].Id;
        appointment.ParentRecordId = account.Id;
        appointment.Status = 'None';
        appointment.Opportunity_Id__c = testOpportunities.Id;
        appointment.SchedStartTime = system.today().addDays(3);
        appointment.Tour_Outcome__c = 'Tour Interested';
        appointment.Target_Move_In_Date__c = system.today().addDays(4);
        appointment.Product_Interests__c = 'Dedicated Desk;Hot Desk';
        appointment.Tour_Outcome_Notes__c = 'Test Notes';
        appointment.Objections__c = 'Too Expensive;Other';
        insert appointment;
    }
    
    @isTest
    public static void updateOpportunityStageToSelling() {
        List<ServiceAppointment> tourForUpdate = [SELECT Status FROM ServiceAppointment];
        
        Test.startTest();
        tourForUpdate[0].Status = 'Completed';
        update tourForUpdate;
        List<Opportunity> tourForUpdateOpportunity = [SELECT Id, StageName FROM Opportunity];
        Test.stopTest();

        System.assertEquals('Selling', tourForUpdateOpportunity[0].StageName, 'Should update Opportunity Stage to Selling');
    }
    
    @isTest
    public static void updateOpportunityStageToQualifying() {
        List<ServiceAppointment> tourForUpdate = [SELECT Status FROM ServiceAppointment];
        
        Test.startTest();
        tourForUpdate[0].Status = 'Scheduled';
        update tourForUpdate;
        List<Opportunity> tourForUpdateOpportunity = [SELECT Id, StageName FROM Opportunity];
        Test.stopTest();
        
        System.assertEquals('Qualifying', tourForUpdateOpportunity[0].StageName, 'Should update Opportunity Stage to Qualifying');
    }
}