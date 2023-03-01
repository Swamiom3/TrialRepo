@isTest
public class RESTAPISchedulerTimeSlotsV1Test {

    @testSetup 
    static void setup() {
        User testUser = TestUtility.createTestUser('WeWork System Administrator');
        Building__c testTourableBuilding = getTestBuilding(true);
        insert testTourableBuilding;
        OperatingHours testOph = new OperatingHours(Name = 'EDT: Standard 8AM - 6PM Weekday');
        insert testOph;
        TimeSlot testTimeSlot = getTimeSlot(testOph.Id);
        Non_Operating_Hours__c testNoh = getNonOperatingHours(testTourableBuilding.Id);
        WorkType testWorkType = getTestWorkType(testTourableBuilding.Id);
        ServiceResource testAcriveServiceResource = getTestServiceResource(testUser.Id, true, testUser.LastName);
        ServiceTerritory testServiceTerritory = getTestServiceTerritory(testTourableBuilding.Id, testOph.Id, testTourableBuilding.Name);
        WorkTypeGroup testWTG = new WorkTypeGroup(Name = 'In-Person', IsActive = true);
        insert new List<SObject> {testTimeSlot, testNoh, testWorkType, testAcriveServiceResource, testServiceTerritory, testWTG};
        ServiceTerritoryMember testServiceTerritoryMember = getTestServiceTerritoryMember(testServiceTerritory.Id, testAcriveServiceResource.Id, testOph.Id);
        insert testServiceTerritoryMember;
    }

    @isTest
    static void testSuccessfulGetTimeSlots() {
        RESTAPITourModelsV2.GetTimeSlotsRequest body = getFakeBody();
        setAppointmentCandidatesMock();
        setAppointmentSlotsMock();

        Test.startTest();
        RESTAPISchedulerTimeSlotsV1.TimeSlotsResponse response = RESTAPISchedulerTimeSlotsV1.getSlots(body);
        Test.stopTest();

        System.assertNotEquals(null, response, 'Response should not be null');
        System.assert(response.success, 'Call was not successful');
        System.assertEquals(AvailableTimeSlotService.SUCCESS_RESPONSE_MESSAGE, response.message, 'The message does not match what was expected in case of successful call');
        System.assert(!response.timeSlots.isEmpty(), 'No Time Slots was returned');
    }

    @isTest 
    static void testUnsuccessfulGetTimeSlots() {
        WorkType testWorkType = [SELECT Id, Building_Id__c FROM WorkType WHERE Name = 'Test building - In-Person'];
        testWorkType.Building_Id__c = null;
        update testWorkType;
        RESTAPITourModelsV2.GetTimeSlotsRequest body = getFakeBody();
        setAppointmentCandidatesMock();
        setAppointmentSlotsMock();

        Test.startTest();
        RESTAPISchedulerTimeSlotsV1.TimeSlotsResponse response = RESTAPISchedulerTimeSlotsV1.getSlots(body);
        Test.stopTest();

        System.assertNotEquals(null, response, 'Response should not be null');
        System.assert(!response.success, 'Call should be unsuccessful');
        System.assertEquals(
                String.format(AvailableTimeSlotService.ERROR_RESPONSE_MESSAGE_NO_WORK_TYPE_FOUND, new List<String>{ body.building_id }),
                response.message,
                'The message does not match what was expected in case of unsuccessful call'
        );
        System.assertEquals(null, response.timeSlots, 'Time Slots should be null');
    }

    static RESTAPITourModelsV2.GetTimeSlotsRequest getFakeBody() {
        RESTAPITourModelsV2.GetTimeSlotsRequest body = new RESTAPITourModelsV2.GetTimeSlotsRequest();
        body.building_id = 'c7aeb13f-b08f-4698-1234-qwertyuiopas';
        body.start_time = '2022-02-02T09:00:00.000Z';
        body.end_time = '2022-02-27T12:00:00.000Z';
        body.tour_format = 'In-Person';
        return body;
    }

    static void setAppointmentCandidatesMock() {
        AvailableTimeSlotService.GetAppointmentCandidatesOutput output = new AvailableTimeSlotService.GetAppointmentCandidatesOutput();
        output.startTime = System.now();
        output.endTime = System.now().addHours(8);
        output.territoryId = TestUtility.getFakeId(ServiceTerritory.SObjectType);
        output.resources = new List<Id>{ [SELECT Id FROM ServiceResource LIMIT 1][0].Id };
        lxscheduler.SchedulerResources.setAppointmentCandidatesMock(JSON.serialize(new List<AvailableTimeSlotService.GetAppointmentCandidatesOutput>{ output }));
    }

    static void setAppointmentSlotsMock() {
        AvailableTimeSlotService.GetAppointmentSlotsOutput output = new AvailableTimeSlotService.GetAppointmentSlotsOutput();
        output.startTime = DateTime.newInstance(2022, 2, 11, 11, 30, 0);
        output.endTime = DateTime.newInstance(2022, 2, 11, 12, 00, 0);
        output.territoryId = TestUtility.getFakeId(ServiceTerritory.SObjectType);
        output.remainingAppointments = 1;
        lxscheduler.SchedulerResources.setAppointmentSlotsMock(JSON.serialize(new List<AvailableTimeSlotService.GetAppointmentSlotsOutput>{ output }));
    }

    static Building__c getTestBuilding( Boolean isTourable) {
        Building__c testBuilding = new Building__c();
        testBuilding.Name = 'TestBuilding';
        testBuilding.UUID__c = 'c7aeb13f-b08f-4698-1234-qwertyuiopas';
        testBuilding.Email__c = 'building@example.com'; 
        testBuilding.Is_Tourable__c = isTourable;
        testBuilding.Time_Zone__c = 'America/Chicago';
        return testBuilding;
    }

    static TimeSlot getTimeSlot(Id OperatingHoursId) {
        TimeSlot testTimeSlot = new TimeSlot();
        testTimeSlot.OperatingHoursId = OperatingHoursId;
        testTimeSlot.DayOfWeek = 'Monday';
        testTimeSlot.StartTime = Time.newInstance(16, 0, 0, 0);
        testTimeSlot.EndTime = Time.newInstance(17, 0, 0, 0);
        return testTimeSlot;
    }

    static Non_Operating_Hours__c getNonOperatingHours (Id buildingId) {
        Non_Operating_Hours__c noh = new Non_Operating_Hours__c();
        noh.Start_Time__c = DateTime.newInstance(2022, 2, 11, 9, 0, 0);
        noh.End_Time__c = DateTime.newInstance(2022, 2, 11, 11, 0, 0);
        noh.Building_Id__c = buildingId;
        noh.Closure_Type__c = 'One-Off';
        return noh;
    }

    static WorkType getTestWorkType(Id buildingId) {
        WorkType testWorkType = new WorkType();
        testWorkType.Name = 'Test building - In-Person';
        testWorkType.Building_Id__c = buildingId;
        testWorkType.Tour_Format__c = 'In-Person';
        testWorkType.EstimatedDuration = 30;
        return testWorkType;
    }

    static ServiceResource getTestServiceResource(Id testUserId, Boolean isActive, String testUserLastName) {
        ServiceResource testServiceResource = new ServiceResource();
        testServiceResource.RelatedRecordId = testUserId;
        testServiceResource.Name = testUserLastName;
        testServiceResource.IsActive = isActive;
        testServiceResource.ResourceType = 'T';
        return testServiceResource;
    }

    static ServiceTerritory getTestServiceTerritory(ID buildingId, Id OperatingHoursId, String buildingName ) {
        ServiceTerritory testServiceTerritory = new ServiceTerritory();
        testServiceTerritory.Building_Id__c = buildingId;
        testServiceTerritory.Name = buildingName;
        testServiceTerritory.OperatingHoursId = OperatingHoursId;
        testServiceTerritory.IsActive = true;
        return testServiceTerritory;
    }

    static ServiceTerritoryMember getTestServiceTerritoryMember (Id ServiceTerritoryId, Id ServiceResourceId, Id OperatingHoursId) {
        ServiceTerritoryMember testServiceTerritoryMember = new ServiceTerritoryMember();
        testServiceTerritoryMember.ServiceTerritoryId = ServiceTerritoryId;
        testServiceTerritoryMember.ServiceResourceId = ServiceResourceId;
        testServiceTerritoryMember.Role = 'Reassigned Host';
        testServiceTerritoryMember.EffectiveStartDate = System.now();
        testServiceTerritoryMember.EffectiveEndDate = null;
        testServiceTerritoryMember.OperatingHoursId = OperatingHoursId;
        testServiceTerritoryMember.TerritoryType = 'P';
        return testServiceTerritoryMember;
    }
}