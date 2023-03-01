/************************************************************************************************************************************
Author         :     Mikolaj Juras
Description    :     Test clas for AsyncTourSetWorldTour
History        :
----------------------------------------------------------------------------------------------------------------------------------
VERSION        DATE                AUTHOR                    DETAIL
1            12 May 2021         Mikolaj Juras             Initial Development     
**************************************************************************************************************************************/
@isTest
public class AsyncTourSetWorldTourTest {

    @testSetup
    static void makeData() {      
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

        ServiceAppointment sa2 = new ServiceAppointment();
        sa2.ContactId = con.Id;
        sa2.ParentRecordId = acc.Id;
        sa2.Status = 'None';
        sa2.SchedStartTime = system.today().addDays(5);
        sa2.Building_Id__c = testBuilding.Id;
        sa2.Product_Interests__c = 'Dedicated Desk;Hot Desk';
        sa2.Tour_Outcome_Notes__c = 'Test Notes';
        insert new List<ServiceAppointment>{sa1, sa2};
    }

    @isTest
    public static void testSetWorldTour() {
        System.assertEquals(2, [SELECT count() FROM ServiceAppointment ], 'Two Service Appointments are present');
        System.assertEquals(0, [SELECT count() FROM ServiceAppointment WHERE World_Tour__c = true], 'No World Tour should be present');

        Test.startTest();
        ServiceAppointment sa2 = [SELECT Id,ContactId,Status, CreatedDate,  Portfolio_Name__c FROM ServiceAppointment WHERE Status= 'None'];
        sa2.Status = 'Scheduled';
        update sa2;
        Test.stopTest();

        System.assertEquals(2, [SELECT count() FROM ServiceAppointment ], 'Total number of ServiceAppointment equal 2');
        System.assertEquals(2, [SELECT count() FROM ServiceAppointment WHERE World_Tour__c = true], 'Two Service Appointments with World Tours are present');
    }

    @isTest
    public static void testSetWorldTourSchedulable() {
        System.assertEquals(2, [SELECT count() FROM ServiceAppointment ], 'Two Tours should be present');
        System.assertEquals(0, [SELECT count() FROM ServiceAppointment WHERE World_tour__c = true], 'No Tours marked as word Tour should be present');

        Set<String> portfolioNames = new Set<String>();
        Set<Id> primaryMembersIds = new Set<Id>();
        portfolioNames.add('Mumbai1');
        primaryMembersIds.add([SELECT Id FROM Contact Limit 1].Id);
        Test.startTest();
        AsyncTourSetWorldTour asyncTour = new AsyncTourSetWorldTour(portfolioNames, primaryMembersIds);
        asyncTour.execute(null);
        Test.stopTest();

        System.assertEquals(2, [SELECT count() FROM ServiceAppointment ], 'Total number of Tours equal 2');
        System.assertEquals(0, [SELECT count() FROM ServiceAppointment WHERE World_tour__c = true], 'Both Tours should marked as word Tour');
    }
}