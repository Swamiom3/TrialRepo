@isTest
public class ServiceAppRelatedWorldToursCtrlTest {
    
    @testSetup
    public static void initData() {
        Map<String,String> testBuildingInput = new Map<String,String>();
        testBuildingInput.put('Name','TestBuilding1');
        testBuildingInput.put('CurrencyIsoCode','USD');
        testBuildingInput.put('Address__c','Banner');
        testBuildingInput.put('City__c','Boston');
        testBuildingInput.put('UUID__c','4eb8144b-f461-4849-8b81-b5fa344fb978');
        testBuildingInput.put('Portfolio_Name__c','Mumbai1');
        testBuildingInput.put('Time_Zone__c','America/Chicago');
        Building__c testBuilding = TestingUtility.createBuilding(testBuildingInput, true);
        
        User user = TestUtility.createTestUser('WeWork System Administrator');
        Account acc = TestingUtility.createAccount(new Map<String, Object>{
            'OwnerId' => TestUtility.createTestUser().Id
        }, true);
        Opportunity opp = TestingUtility.createOpportunity(new Map<String, Object>(), true);
        Contact con = TestingUtility.createContact(new Map<String, Object>{
            'Email' => 'user@unit-test.com',
            'AccountId' => acc.Id
        }, true);
        ServiceAppointment sa1 = new ServiceAppointment();
        sa1.ContactId = con.Id;
        sa1.ParentRecordId = acc.Id;
        sa1.Status = 'Scheduled';
        sa1.SchedStartTime = system.today().addDays(3);
        sa1.Building_Id__c = testBuilding.Id;
        sa1.Product_Interests__c = 'Dedicated Desk;Hot Desk';
        sa1.Tour_Outcome_Notes__c = 'Test Notes';
        sa1.World_Tour__c = true;
        
        ServiceAppointment sa2 = new ServiceAppointment();
        sa2.ContactId = con.Id;
        sa2.ParentRecordId = acc.Id;
        sa2.Status = 'Scheduled';
        sa2.SchedStartTime = system.today().addDays(5);
        sa2.Building_Id__c = testBuilding.Id;
        sa2.Product_Interests__c = 'Dedicated Desk;Hot Desk';
        sa2.Tour_Outcome_Notes__c = 'Test Notes';
        sa2.World_Tour__c = true;

        ServiceAppointment sa3 = new ServiceAppointment();
        sa3.ContactId = con.Id;
        sa3.ParentRecordId = acc.Id;
        sa3.Status = 'Scheduled';
        sa3.SchedStartTime = system.today().addDays(5);
        sa3.Building_Id__c = testBuilding.Id;
        sa3.Product_Interests__c = 'Dedicated Desk;Hot Desk';
        sa3.Tour_Outcome_Notes__c = 'Test Notes';
        sa3.World_Tour__c = true;

        ServiceAppointment sa4 = new ServiceAppointment();
        sa4.ContactId = con.Id;
        sa4.ParentRecordId = acc.Id;
        sa4.Status = 'None';
        sa4.SchedStartTime = system.today().addDays(5);
        sa4.Building_Id__c = testBuilding.Id;
        sa4.Product_Interests__c = 'Dedicated Desk;Hot Desk';
        sa4.Tour_Outcome_Notes__c = 'Test Notes';
        sa4.World_Tour__c = true;

        ServiceAppointment sa5 = new ServiceAppointment();
        sa5.ContactId = con.Id;
        sa5.ParentRecordId = acc.Id;
        sa5.Status = 'None';
        sa5.SchedStartTime = system.today().addDays(5);
        sa5.Building_Id__c = testBuilding.Id;
        sa5.Product_Interests__c = 'Dedicated Desk;Hot Desk';
        sa5.Tour_Outcome_Notes__c = 'Test Notes';
        sa5.World_Tour__c = true;
        
        insert new List<ServiceAppointment>{sa1, sa2, sa3, sa4, sa5};

        Test.setCreatedDate(sa3.Id, System.now().addDays(-5));
        Test.setCreatedDate(sa5.Id, System.now().addDays(-5));
    }
    @isTest
    public static void testGetServiceAppointmentsMarkedAsWorldTour() {
        System.assertEquals(0, ServiceAppRelatedWorldToursCtrl.getServiceAppointmentsMarkedAsWorldTour(TestUtility.getFakeId(Contact.SObjectType), System.now(),'Mumbai1').size(), 'No appointments should be present for fake Id');
        System.assertEquals(2, ServiceAppRelatedWorldToursCtrl.getServiceAppointmentsMarkedAsWorldTour([SELECT Id FROM Contact LIMIT 1].Id, System.now(),'Mumbai1').size(), 'Two appointments should be present');
        System.assertEquals(1, ServiceAppRelatedWorldToursCtrl.getServiceAppointmentsMarkedAsWorldTour([SELECT Id FROM Contact LIMIT 1].Id, System.now().addDays(-5),'Mumbai1').size(), 'One appointments should be present');
    }
}