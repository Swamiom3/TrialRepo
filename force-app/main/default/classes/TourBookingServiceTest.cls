@isTest
public with sharing class TourBookingServiceTest {
    @isTest
    static void testConvertDatetimeStringToGMT() {
        RESTAPITourModelsV2.Input testBody = new RESTAPITourModelsV2.Input();
        testBody.start_time = '2022-01-25T09:00:00.000+0100';
        testBody.end_time = '2022-01-25T09:30:00.000+0100';
        TourBookingService tbs = new TourBookingService();
        tbs.body = testBody;
        Building__c building = new Building__c(Time_Zone__c = 'Europe/Amsterdam');
        tbs.tourBuilding = building;
        Test.startTest();
        tbs.convertDatetimeStringToGMT();
        Test.stopTest();
        System.assertEquals('2022-01-25T08:00:00+0000', tbs.startTime, 'Start time must be converted to standard UTC format with GMT time zone');
        System.assertEquals('2022-01-25T08:30:00+0000', tbs.endTime, 'End time must be defaulted to 30 mins after start time and converted to standard UTC format with GMT time zone');
    }

    @isTest
    static void testGetLowerSize() {
        TourBookingService tbs = new TourBookingService();
        System.assertEquals(5, tbs.getLowerSize('5'), 'Parsed company size must be equal to 5');
        System.assertEquals(99, tbs.getLowerSize('99-105'), 'Parsed company size must be equal to 99');
    }
}