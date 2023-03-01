@isTest
public with sharing class RESTAPISchedulerNewTourV1Test {

    @testSetup
    static void makeData(){
        Building__c building = ((List<Building__c>) TestingUtility.getRecords(new Map<String, Object>{ 'objName' => 'Building__c', 'numberOfRecords' => 1 }))[0];
        User testUser = ((List<User>) TestingUtility.getRecords(new Map<String, Object>{ 'objName' => 'User', 'doInsert' => true, 'numberOfRecords' => 1 }))[0];
        OperatingHours oh = new OperatingHours(Name = 'EDT: Standard 9AM - 5PM Weekday');
        insert oh;
        TimeSlot ts = new TimeSlot(OperatingHoursId = oh.Id,
                                    DayOfWeek = 'Monday',
                                    StartTime = Time.newInstance(9, 0, 0, 0),
                                    EndTime = Time.newInstance(17, 0, 0, 0));
        ServiceTerritory st = new ServiceTerritory(Building_Id__c = building.Id,
                                                    Name = building.Name,
                                                    OperatingHoursId = oh.Id,
                                                    IsActive = true);
        ServiceResource sr = new ServiceResource(RelatedRecordId = testUser.Id,
                                                    Name = testUser.LastName,
                                                    ResourceType = 'T',
                                                    IsActive = true);
        WorkTypeGroup wtg = new WorkTypeGroup(Name = ServiceAppointmentConstants.TOUR_FORMAT_IN_PERSON,
                                                IsActive = true);
        WorkType wt = new WorkType(Name = 'Test building - In-Person',
                                    OperatingHoursId = oh.Id,
                                    Tour_Format__c = ServiceAppointmentConstants.TOUR_FORMAT_IN_PERSON,
                                    Building_Id__c = building.Id,
                                    EstimatedDuration = 30);
        Account acc = new Account(Name = 'Tony Montana');
        insert new List<SObject>{ ts, st, sr, wtg, wt, acc };
        insert new ServiceTerritoryMember(ServiceTerritoryId = st.Id,
                                            ServiceResourceId = sr.Id,
                                            Role = 'Reassigned Host',
                                            EffectiveStartDate = System.now(),
                                            EffectiveEndDate = null,
                                            OperatingHoursId = oh.Id,
                                            TerritoryType = 'P');
        ServiceAppointment tour = new ServiceAppointment(WorkTypeId = wt.Id, ServiceTerritoryId = st.Id, ParentRecordId = acc.Id);
        insert tour;
    }

    @isTest
    static void testScheduleNewTour() {
        MetadataDrivenTriggerHandler.disableExecution();
        setAppointmentCandidatesMock();
        Test.startTest();
        RESTAPITourModelsV2.Response response = RESTAPISchedulerNewTourV1.scheduleTour(prepareBasePayload());
        Test.stopTest();
        System.assertEquals('Tony Montana', [SELECT Name FROM Contact][0].Name, 'Contact must be created based on payload data');
        System.assertEquals(5, [SELECT Interested_in_Number_of_Desks__c FROM Opportunity][0].Interested_in_Number_of_Desks__c, 'Opportunity must be created with correct Interested number of desks value');
        System.assertNotEquals(null, response, 'Response should not be null');
        System.assert(response.success, 'Response should be successful');
        System.assert(String.isNotBlank(response.payload), 'Payload must not be blank');
        ServiceAppointmentEndpointService.ScheduleServiceAppointmentRequest ssar = (ServiceAppointmentEndpointService.ScheduleServiceAppointmentRequest) JSON.deserialize(response.payload, ServiceAppointmentEndpointService.ScheduleServiceAppointmentRequest.class);
        System.assertEquals(null, ssar.serviceAppointmentId, 'Service Appointment Id field must be empty for new tour booking request');
        System.assert(!ssar.serviceAppointment.extendedFields.isEmpty(), 'Fields in payload must be populated');
    }

    @isTest
    static void testRescheduleTour() {
        RESTAPITourModelsV2.Input payload = prepareBasePayload();
        Id tourId = [SELECT Id FROM ServiceAppointment][0].Id;
        payload.tour_id = tourId;
        setAppointmentCandidatesMock();
        Test.startTest();
        RESTAPITourModelsV2.Response response = RESTAPISchedulerNewTourV1.scheduleTour(payload);
        Test.stopTest();
        System.assertNotEquals(null, response, 'Response should not be null');
        System.assert(response.success, 'Response should be successful');
        System.assert(String.isNotBlank(response.payload), 'Payload must not be blank');
        ServiceAppointmentEndpointService.ScheduleServiceAppointmentRequest ssar = (ServiceAppointmentEndpointService.ScheduleServiceAppointmentRequest) JSON.deserialize(response.payload, ServiceAppointmentEndpointService.ScheduleServiceAppointmentRequest.class);
        System.assertEquals(tourId, ssar.serviceAppointmentId, 'Service Appointment Id must contain existing tour Id');
        System.assert(!ssar.serviceAppointment.extendedFields.isEmpty(), 'Fields in payload must be populated');
    }

    @isTest
    static void testScheduleTourBuildingNotValid() {
        RESTAPITourModelsV2.Input payload = prepareBasePayload();
        payload.building_id = 'bad_building_uuid';
        setAppointmentCandidatesMock();
        Test.startTest();
        RESTAPITourModelsV2.Response response = RESTAPISchedulerNewTourV1.scheduleTour(payload);
        Test.stopTest();
        System.assertNotEquals(null, response, 'Response should not be null');
        System.assert(!response.success, 'Response should not be successful');
        System.assertEquals(response.message, 'Invalid building Id provided', 'Error must be fired because of invalid building UUID');
        System.assert(String.isBlank(response.payload), 'Payload must be blank');
    }

    static RESTAPITourModelsV2.Input prepareBasePayload() {
        Id service_resource_id = [SELECT Id FROM ServiceResource LIMIT 1][0].Id;
        RESTAPITourModelsV2.Input input = new RESTAPITourModelsV2.Input();
        input.building_id = 'buildingUUID1';
        input.email = 'test.email@ww.com';
        input.start_time = '2022-01-25T10:00:00.000+0300';
        input.end_time = '2022-01-25T10:30:00.000+0300';
        input.number_of_desks = '5';
        input.tour_format = ServiceAppointmentConstants.TOUR_FORMAT_IN_PERSON;
        input.first_name = 'Tony';
        input.last_name = 'Montana';
        input.service_resource_id = service_resource_id;
        return input;
    }

    static void setAppointmentCandidatesMock() {
        TourBookingService.AppointmentCandidatesOutput out = new TourBookingService.AppointmentCandidatesOutput();
        out.startTime = System.now();
        out.endTime = System.now().addHours(8);
        out.territoryId = TestUtility.getFakeId(ServiceTerritory.SObjectType);
        out.resources = new List<Id>{ [SELECT Id FROM ServiceResource LIMIT 1][0].Id };
        lxscheduler.SchedulerResources.setAppointmentCandidatesMock(JSON.serialize(new List<TourBookingService.AppointmentCandidatesOutput>{ out }));
    }
}