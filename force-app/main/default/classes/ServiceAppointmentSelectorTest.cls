@isTest
public with sharing class ServiceAppointmentSelectorTest {

    @testSetup
    private static void setup() {
        Map<String,String> testBuildingInput = new Map<String,String>();
        testBuildingInput.put('Name','TestBuilding1');
        testBuildingInput.put('CurrencyIsoCode','USD');
        testBuildingInput.put('Address__c','Banner');
        testBuildingInput.put('City__c','Boston');
        testBuildingInput.put('UUID__c','4eb8144b-f461-4849-8b81-b5fa344fb978');
        testBuildingInput.put('Portfolio_Name__c','Mumbai1');
        testBuildingInput.put('Time_Zone__c','America/Chicago');
        Building__c testBuilding = TestingUtility.createBuilding(testBuildingInput, true);
        
        Account acc = TestingUtility.createAccount(new Map<String, Object>{
            'OwnerId' => TestUtility.createTestUser().Id
        }, true);
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
        sa1.World_Tour__C = true;
        insert sa1;
    }

    @isTest
    public static void getServiceAppForContactsAndPortfoliosFilteredByWhereTest(){
        ServiceAppointmentSelector selector = new ServiceAppointmentSelector();
        System.assert(!selector.getServiceAppForContactsAndPortfoliosFilteredByWhere(new Set<String> {'Mumbai1'}, 
                                                                                     new Set<Id> {[SELECT contactId FROM ServiceAppointment LIMIT 1].contactId}).isEmpty(), 'list should not be empty');
    }

    @isTest
    public static void getServiceAppForCurrentConatactTest(){
        ServiceAppointmentSelector selector = new ServiceAppointmentSelector();
        System.assert(!selector.getServiceAppForCurrentConatact([SELECT contactId FROM ServiceAppointment LIMIT 1].contactId,
                                                                 System.now(),
                                                                 'Mumbai1').isEmpty(),'list should not be empty');
    }
}