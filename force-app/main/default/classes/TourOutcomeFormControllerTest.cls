@isTest
public class TourOutcomeFormControllerTest{
    @testSetup
    static void testDataSetup() {
        Account acc = new Account();
        acc.Name = 'Test John';
        insert acc;
        Map<String, Object> mapContactFieldValues = new Map<String, Object>();
        List<Contact> lstContacts = new List<Contact>();
        mapContactFieldValues.put('firstname', 'test');
        mapContactFieldValues.put('lastname', 'Contact');
        mapContactFieldValues.put('AccountId', acc.Id);
        mapContactFieldValues.put('email', 'joinus@wework.com');
        mapContactFieldValues.put('Status__c', 'active');
        mapContactFieldValues.put('UUID__c', 'UUID1');
        lstContacts.add((Contact)TestingUtility.createTestRecords(Contact.sObjectType,mapContactFieldValues,false));
        mapContactFieldValues.put('firstname', 'test');
        mapContactFieldValues.put('lastname', 'Contact1');
        mapContactFieldValues.put('email', 'testUser@wework.com');
        mapContactFieldValues.put('Status__c', 'active');
        mapContactFieldValues.put('UUID__c', 'UUID2');
        lstContacts.add((Contact)TestingUtility.createTestRecords(Contact.sObjectType, mapContactFieldValues, false));
        mapContactFieldValues.put('firstname', 'ABCBroker');
        mapContactFieldValues.put('lastname', 'Test');
        mapContactFieldValues.put('email', 'ABCBrokerTest@weworktest.com');
        mapContactFieldValues.put('Status__c', 'active');
        mapContactFieldValues.put('UUID__c', 'ABCBroker2');
        mapContactFieldValues.put('Type__c', 'Broker');
        lstContacts.add((Contact)TestingUtility.createTestRecords(Contact.sObjectType, mapContactFieldValues, false));
        TestingUtility.insertListWithAssert(lstContacts);

        List<Building__c> lstBuildings = new List<Building__c>();
        Map<String, Object> mapBuildingFieldValues = new Map<String, Object>();
        mapBuildingFieldValues.put('Name', 'building1');
        mapBuildingFieldValues.put('uuid__c', 'UUID3');
        lstBuildings.add((Building__c)TestingUtility.createTestRecords(Building__c.sObjectType, mapBuildingFieldValues, false));
        TestingUtility.insertListWithAssert(lstBuildings);

        List<ServiceAppointment> lstTourOutcomes = new List<ServiceAppointment>();
        ServiceAppointment appointment = new ServiceAppointment();
        appointment.ContactId = lstContacts[0].Id;
        appointment.ParentRecordId = acc.Id;
        appointment.Status = 'Scheduled';
        appointment.SchedStartTime = system.today().addDays(3);
        appointment.Tour_Outcome__c = 'Tour Interested';
        appointment.Target_Move_In_Date__c = system.today().addDays(4);
        appointment.Product_Interests__c = 'Dedicated Desk;Hot Desk';
        appointment.Tour_Outcome_Notes__c = 'Test Notes';
        appointment.Objections__c = 'Too Expensive;Other';
        insert appointment;

        Profile weworkSystemAdmin = [SELECT Id FROM Profile WHERE Name = 'WeWork System Administrator'];
        Map<String,Object> userRecordMap = new Map<String,Object>();
        userRecordMap.put('LastName', 'Last Name');
        userRecordMap.put('Username', TestingUtility.createStringValue()+'username@user.com');
        userRecordMap.put('Email', 'testUser@wework.com');
        User testUser = TestingUtility.insertUserWithAssert(weworkSystemAdmin.Id, userRecordMap, true);

        TourOutcomeFormController.Headers headers = new TourOutcomeFormController.Headers();
        headers.Authorization = 'Token token=[FAKE_TOKEN]';

        TourOutcomeFormController.ReservableAvailabilityAPI reservAvailApi = new TourOutcomeFormController.ReservableAvailabilityAPI();
        reservAvailApi.headers = headers;
        reservAvailApi.url = 'https://sales-api-staging.wework.com/v2/office_availabilities/search';

        TourOutcomeFormController.CreateTourOutcomes tourOutcomes = new TourOutcomeFormController.CreateTourOutcomes();
        tourOutcomes.headers = headers;
        tourOutcomes.url = 'https://sales-api-staging.wework.com/v1/tour_outcomes';

        TourOutcomeFormController.NoShow noShow = new TourOutcomeFormController.NoShow();
        noShow.headers = headers;
        noShow.url = 'https://sales-api-staging.wework.com/v1/tours/tour_uuid/no_show';

        TourOutcomeFormController.Reasons reasons = new TourOutcomeFormController.Reasons();
        reasons.headers = headers;
        reasons.url = 'https://sales-api-staging.wework.com/v1/reasons';

        TourOutcomeFormController.HowHeards howHeards = new TourOutcomeFormController.HowHeards();
        howHeards.headers = headers;
        howHeards.url = 'https://sales-api-staging.wework.com/v2/how_heards';

        TourOutcomeFormController.Urgencies urgencies = new TourOutcomeFormController.Urgencies();
        urgencies.headers = headers;
        urgencies.url = 'https://sales-api-staging.wework.com/v2/urgencies';

        TourOutcomeFormController.ReservableTourBuildingAvailabilitiesAPI reservTour = new TourOutcomeFormController.ReservableTourBuildingAvailabilitiesAPI();
        reservTour.headers = headers;
        reservTour.url = 'https://sales-api-staging.wework.com/v2/available_tour_times';

        TourOutcomeFormController.ReservableRescheduleAPI reservReschedule = new TourOutcomeFormController.ReservableRescheduleAPI();
        reservReschedule.headers = headers;
        reservReschedule.url = 'https://sales-api-staging.wework.com/v1/tours/:id/reschedule';

        TourOutcomeFormController.TourOutcomeFormSettings tourOutcomeFormSetting = new TourOutcomeFormController.TourOutcomeFormSettings();

        tourOutcomeFormSetting.RestrictedProfiles = new set<String>{'WeWork NMD Admin', 'WeWork Inside Sales', 'WeWork NMD User - Outbound'};

        tourOutcomeFormSetting.reservableAvailabilityAPI = reservAvailApi;
        tourOutcomeFormSetting.createTourOutcomes = tourOutcomes;
        tourOutcomeFormSetting.howHeards = howHeards;
        tourOutcomeFormSetting.noShow = noShow;
        tourOutcomeFormSetting.reasons = reasons;
        tourOutcomeFormSetting.reservableRescheduleAPI = reservReschedule;
        tourOutcomeFormSetting.reservableTourBuildingAvailabilitiesAPI = reservTour;
        tourOutcomeFormSetting.urgencies = urgencies;
    }

    @isTest
    static void getFormDataTest(){
        List<ServiceAppointment> lstTourOutcomes = [SELECT Id FROM ServiceAppointment];
        List<User> lstUsers = [SELECT Id, Name,Email FROM User Where Email = 'testUser@wework.com'];
        List<Contact> lstContacts = [SELECT Id, Name, email, UUID__c FROM Contact];
        Map<String, Object> parameters = new Map<String, Object>{'IdOrUUID' => lstTourOutcomes[0].Id, 'label' => 'TourDetails'};
        String result = (String)TourOutcomeFormController.getFormData(parameters).data;
        Map<String, Object> formData = (Map<String, Object>)JSON.deserializeUntyped(result);

        List<object> tourRecord = (List<object>)formData.get('tourRecord');
        Map<String, Object> tourCompletedBy = (Map<String, Object>)formData.get('tourCompletedBy');
        Map<String, Object> setting = (Map<String, Object>)formData.get('setting');
        System.assertNotEquals(null, formData);
        Map<String, Object> mapResult = (Map<String, object>)tourRecord[0];
        System.assertEquals(lstTourOutcomes[0].Id, mapResult.get('Id'));
        System.assertEquals(userInfo.getUserId(), formData.get('loggedInUser'));
        System.assertEquals(lstContacts[0].Id, tourCompletedBy.get('Id'));
        System.runAs(lstUsers[0]){
            string userContextData = (string)TourOutcomeFormController.getFormData(parameters).data;
            Map<String, Object> userContextFormData = (Map<String, Object>)JSON.deserializeUntyped(userContextData);
            Map<String, Object> userContextTourCompletedBy = (Map<String, Object>)userContextFormData.get('tourCompletedBy');
            System.assertEquals(lstContacts[1].Id, userContextTourCompletedBy.get('Id'));
        }
        TestingUtility.deleteListWithAssert(lstContacts);
        System.runAs(lstUsers[0]){
            String userContextData = (String)TourOutcomeFormController.getFormData(parameters).data;
            Map<String, Object> userContextFormData = (Map<String, Object>)JSON.deserializeUntyped(userContextData);
            Map<String, Object> userContextTourCompletedBy = (Map<String, Object>)userContextFormData.get('tourCompletedBy');
            System.assertEquals(null, userContextTourCompletedBy.get('Id'));
        }
        try{
            DatabaseResult result1  = TourOutcomeFormController.getFormData(null);
        } catch(Exception exc){
            System.assertNotEquals(null, exc);
        }
    }

    @isTest
    static void getUserContactInfoTest(){
        List<User> lstUsers = [SELECT Id, Name FROM User Where Email = 'testUser@wework.com'];
        List<Contact> lstContacts = [SELECT Id, Name, email, UUID__c FROM Contact];
        System.runAs(lstUsers[0]){
            String contact = TourOutcomeFormController.getUserContactInfo();
            Map<String, Object> contactMap = (Map<String, Object>)JSON.deserializeUntyped(contact.substringBetween('[', ']'));
            System.assertEquals(lstContacts[1].Id, contactMap.get('Id'));
        }
    }

    @isTest
    static void searchReferrerContactsTest(){
        List<Contact> testContacts = [SELECT Id, Name, email, UUID__c FROM Contact WHERE Email = 'ABCBrokerTest@weworktest.com' limit 1];
        Id [] fixedSearchResults = new Id[1];
        fixedSearchResults[0] = testContacts[0].Id;
        Test.setFixedSearchResults(fixedSearchResults);
        List<Contact> returnedContacts = TourOutcomeFormController.searchReferrerContacts('Test');
        System.assertEquals(false, returnedContacts.isEmpty(), 'Referrer Contacts found');
    }

}