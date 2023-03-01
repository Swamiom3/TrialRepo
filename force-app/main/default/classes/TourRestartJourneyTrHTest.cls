/************************************************************************************************************************************
Author      :   Tomasz Sadowski
Description :   This class will contain test methods of TourRestartJourneyTrH class.
History:
----------------------------------------------------------------------------------------------------------------------------------
VERSION     DATE              AUTHOR                  DETAIL
1.0         6 Oct 2021        Tomasz Sadowski         Test coverage
            24 Feb 2022       Oleksandr Liesnik       Refactor to work with Q2C envirorment
*************************************************************************************************************************************/
@isTest
public class TourRestartJourneyTrHTest {

    @TestSetup
    static void initData(){
        WeWorkValidatorHelper.createTerritoryStructure();
        Test.startTest();
        List<SObject> toursAndOpportunities = TestingUtility.getRecords(new Map<String, Object>{'objName' => 'Tour', 'numberOfRecords' => 3, 'doInsert' => true});
        List<Profile> profiles = [SELECT Id FROM Profile WHERE Name = 'WeWork System Administrator'];
        Map<String, Object> usersData = new Map<String, Object>();
        usersData.put('LastName', 'testweworkuser1');
        usersData.put('Username', 'wework' + TestingUtility.createStringValue() + '@example.com');
        usersData.put('Email', 'test@mail.com');
        usersData.put('IsActive', true);
        User insertedUser = TestingUtility.insertUserWithAssert(profiles[0].Id, usersData, true);
        UserUtility.refreshUsers();
        List<Opportunity> opportunitiesToUpdate = new List<Opportunity>();
        List<ServiceAppointment> toursToUpdate = new List<ServiceAppointment>();
        for (SObject singleRecord : toursAndOpportunities) {
            if (String.valueOf(singleRecord.getSObjectType()).toLowerCase() == 'opportunity') {
                opportunitiesToUpdate.add((Opportunity)singleRecord);
            } else {
                toursToUpdate.add((ServiceAppointment)singleRecord);
            }
        }
        System.assert(!toursToUpdate.isEmpty(), 'List of tours to insert should not be empty.');
        Integer count = 0;
        for (Opportunity opportunityRecord: opportunitiesToUpdate) {
            opportunityRecord.Assignment_Status__c = 'Completed';
            if (count == 0) {
                opportunityRecord.OwnerId = insertedUser.Id;
            }
            count++;
        }
        TestingUtility.updateListWithAssert(opportunitiesToUpdate);
        
        for (count = 0; count < opportunitiesToUpdate.size(); count++){
            toursToUpdate[count].Opportunity_Id__c = opportunitiesToUpdate[count].Id;
        }
        TestingUtility.updateListWithAssert(toursToUpdate);
        Test.stopTest();
    }
    
    @isTest
    public static void restartJourneyTest() {
        Map<String, ServiceAppointment> toursByUuids = new Map<String, ServiceAppointment>();
        List<ServiceAppointment> tours = TourTriggersTest.getTourRecords(toursByUuids);
        for (ServiceAppointment tour : tours) {
            tour.Status = GlobalConstants.TOUR_NO_SHOW;
        }
        Test.startTest();
        update tours;
        Test.stopTest();
        
        List<Journey__c> journeysAfter = [SELECT Id FROM Journey__c WHERE Restart_Journey_Reason__c = :GlobalConstants.TOUR_NO_SHOW];
        System.assertEquals(3, journeysAfter.size(), 'Number of restarted journeys does not match.');
    }
    
    @isTest
    public static void restartJourneyNegativeCaseTest() {
        Map<String, ServiceAppointment> toursByUuids = new Map<String, ServiceAppointment>();
        List<ServiceAppointment> tours = TourTriggersTest.getTourRecords(toursByUuids);
        for (ServiceAppointment tour : tours) {
            tour.Status = GlobalConstants.TOUR_CANCELLED;
        }
        Test.startTest();
        update tours;
        Test.stopTest();
        
        List<Journey__c> journeysAfter = [SELECT Id FROM Journey__c WHERE Restart_Journey_Reason__c = :GlobalConstants.TOUR_NO_SHOW];
        System.assertEquals(0, journeysAfter.size(), 'No journeys should have been restarted.');
    }
}