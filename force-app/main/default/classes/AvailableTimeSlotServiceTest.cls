@isTest
public class AvailableTimeSlotServiceTest {
    private static AvailableTimeSlotService serviceInstance = new AvailableTimeSlotService();

    @isTest
    static void testGetServiceResourceIdsWithNoCandidates() {
        serviceInstance.appointmentCandidates = new List<AvailableTimeSlotService.GetAppointmentCandidatesOutput>();
        String exMessage;

        Test.startTest();
        try {
            serviceInstance.getServiceResourceIds();
        } catch (Exception ex) {
            exMessage = ex.getMessage();
        }
        Test.stopTest();

        System.assert(serviceInstance.appointmentCandidates.isEmpty(), 'AppointmentCandidates List should be empty');
        System.assertEquals(AvailableTimeSlotService.ERROR_RESPONSE_MESSAGE_NO_AVAILABLE_RESOURCES, exMessage, 'The error messages do not match');
    }

    @isTest
    static void testGetServiceResourceIdsWithCandidates() {
        serviceInstance.appointmentCandidates = new List<AvailableTimeSlotService.GetAppointmentCandidatesOutput>();
        AvailableTimeSlotService.GetAppointmentCandidatesOutput fakeCandidate = new AvailableTimeSlotService.GetAppointmentCandidatesOutput();
        fakeCandidate.startTime = DateTime.newInstance(2022, 2, 11, 9, 0, 0);
        fakeCandidate.endTime = DateTime.newInstance(2022, 2, 11, 11, 0, 0);
        fakeCandidate.resources = new List<String>{'0Hn1F000000CuHDSA0'};
        fakeCandidate.territoryId = '0Hh000000000001CAA';
        serviceInstance.appointmentCandidates.add(fakeCandidate);

        Test.startTest();
        serviceInstance.getServiceResourceIds();
        Test.stopTest();

        System.assert(!serviceInstance.appointmentCandidates.isEmpty(), 'AppointmentCandidates List should not be empty');
        System.assert(!serviceInstance.resourceIds.isEmpty(), 'List of ResourceIds should not be empty');
        System.assertEquals('0Hn1F000000CuHDSA0', serviceInstance.resourceIds[0], 'List of ResourceIds should contain id of fake candidate');
    }

    @isTest
    static void testRemoveNonOperatingHoursFromSlotsWithEmptySlots() {
        RESTAPITourModelsV2 instance = new RESTAPITourModelsV2(); 
        List<AvailableTimeSlotService.GetAppointmentSlotsOutput> fakeSlots = new List<AvailableTimeSlotService.GetAppointmentSlotsOutput>();
        AvailableTimeSlotService.GetAppointmentSlotsOutput fakeSlotUnsuitable = new AvailableTimeSlotService.GetAppointmentSlotsOutput();
        fakeSlotUnsuitable.startTime = DateTime.newInstance(2022, 2, 7, 6, 0, 0);
        fakeSlotUnsuitable.endTime = DateTime.newInstance(2022, 2, 7, 7, 0, 0);
        fakeSlotUnsuitable.remainingAppointments = 1;
        fakeSlotUnsuitable.territoryId = '0Hh000000000001CAA';
        fakeSlots.add(fakeSlotUnsuitable);
        Building__c fakeBuilding = getFakeBuilding(true);
        List<Non_Operating_Hours__c> fakeNonOperatingHours = new List<Non_Operating_Hours__c>{ getFakeNonOperatingHours(fakeBuilding.Id) };
        List<String> fakeResourceIds = new List<String>{'0Hn1F000000CuHDSA0'};

        Test.startTest();
        List<RESTAPITourModelsV2.AvailableTimeSlot> fakeAvailableSlots = AvailableTimeSlotService.removeNonOperatingHoursFromSlots(fakeSlots, fakeNonOperatingHours, fakeBuilding.Time_Zone__c, fakeResourceIds);
        Test.stopTest();

        System.assert(fakeAvailableSlots.isEmpty(), 'Available Slots List should be empty');
    }

    @isTest
    static void testRemoveNonOperatingHoursFromSlotsWithSlots() {
        RESTAPITourModelsV2 instance = new RESTAPITourModelsV2();
        List<AvailableTimeSlotService.GetAppointmentSlotsOutput> fakeSlots = new List<AvailableTimeSlotService.GetAppointmentSlotsOutput>();
        AvailableTimeSlotService.GetAppointmentSlotsOutput fakeSlotSuitable = new AvailableTimeSlotService.GetAppointmentSlotsOutput();
        fakeSlotSuitable.startTime = DateTime.newInstance(2022, 2, 7, 5, 0, 0);
        fakeSlotSuitable.endTime = DateTime.newInstance(2022, 2, 7, 6, 0, 0);
        fakeSlotSuitable.remainingAppointments = 1;
        fakeSlotSuitable.territoryId = '0Hh000000000001CAA';
        fakeSlots.add(fakeSlotSuitable);

        AvailableTimeSlotService.GetAppointmentSlotsOutput fakeSlotUnsuitable = new AvailableTimeSlotService.GetAppointmentSlotsOutput();
        fakeSlotUnsuitable.startTime = DateTime.newInstance(2022, 2, 7, 6, 0, 0);
        fakeSlotUnsuitable.endTime = DateTime.newInstance(2022, 2, 7, 7, 0, 0);
        fakeSlotUnsuitable.remainingAppointments = 1;
        fakeSlotUnsuitable.territoryId = '0Hh000000000001CAA';
        fakeSlots.add(fakeSlotUnsuitable);

        Building__c fakeBuilding = getFakeBuilding(true);
        List<Non_Operating_Hours__c> fakeNonOperatingHours = new List<Non_Operating_Hours__c>{ getFakeNonOperatingHours(fakeBuilding.Id) };
        List<String> fakeResourceIds = new List<String>{'0Hn1F000000CuHDSA0'};

        Test.startTest();
        List<RESTAPITourModelsV2.AvailableTimeSlot> fakeAvailableSlots = AvailableTimeSlotService.removeNonOperatingHoursFromSlots(fakeSlots, fakeNonOperatingHours, fakeBuilding.Time_Zone__c, fakeResourceIds);
        Test.stopTest();

        System.assert(!fakeAvailableSlots.isEmpty(), 'Available Slots List should not be empty');
        System.assertEquals(1, fakeAvailableSlots.size(), 'List of Available Slots should contain only one suitable slot');

    }

    static Building__c getFakeBuilding( Boolean isTourable) {
        Building__c fakeBuilding = new Building__c();
        fakeBuilding.Id = TestUtility.getFakeId(Building__c.SObjectType);
        fakeBuilding.Name = 'FakeBuilding';
        fakeBuilding.UUID__c = 'c7aeb13f-b08f-4698-1234-qwertyuiopas';
        fakeBuilding.Email__c = 'building@example.com'; 
        fakeBuilding.Is_Tourable__c = isTourable;
        fakeBuilding.Time_Zone__c = 'America/Chicago';
        return fakeBuilding;
    }

    static Non_Operating_Hours__c getFakeNonOperatingHours (Id buildingId) {
        Non_Operating_Hours__c fakeNoh = new Non_Operating_Hours__c();
        fakeNoh.Id = TestUtility.getFakeId(Non_Operating_Hours__c.SObjectType);
        fakeNoh.Start_Time__c = DateTime.newInstance(2022, 2, 7, 6, 0, 0);
        fakeNoh.End_Time__c = DateTime.newInstance(2022, 2, 7, 7, 0, 0);
        fakeNoh.Building_Id__c = buildingId;
        fakeNoh.Closure_Type__c = 'One-Off';
        return fakeNoh;
    }
}