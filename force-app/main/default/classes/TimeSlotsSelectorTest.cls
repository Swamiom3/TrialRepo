/*************************************************************************************************************************************
Author      :   Salesforce
Description :   This class provides sufficient test coverage for TimeSlotsSelector class
--------------------------------------------------------------------------------------------------------------------------------------
VERSION         DATE            AUTHOR              DETAIL
1               11/22/2021       Salesforce         Initial Deployment
**************************************************************************************************************************************/
@isTest
public class TimeSlotsSelectorTest {
    private static TimeSlotsSelector timeSlotsSelector = new TimeSlotsSelector();

    @testSetup
    static void initData() {
        OperatingHours operatingHour = new OperatingHours(Name = 'EDT: Standard 9AM - 5PM Weekday');
        insert operatingHour;
        insert new TimeSlot (OperatingHoursId = operatingHour.Id, DayOfWeek = 'Monday', StartTime = Time.newInstance(9, 0, 0, 0), EndTime = Time.newInstance(17, 0, 0, 0));
    }

    @isTest
    static void getTimeSlotsByOPeratingHoursIdsTest() {
        OperatingHours operatingHour = [SELECT Id FROM OperatingHours LIMIT 1];
        TimeSlot timeSlot = [SELECT Id FROM TimeSlot LIMIT 1];
        Test.startTest();
        List<TimeSlot> timeSlots = timeSlotsSelector.getTimeSlotsByOPeratingHoursIds(new List<Id> { operatingHour.Id });
        List<TimeSlot> timeSlotsNegative = timeSlotsSelector.getTimeSlotsByOPeratingHoursIds(new List<Id> { timeSlot.Id });
        List<TimeSlot> timeSlotsEmpty = timeSlotsSelector.getTimeSlotsByOPeratingHoursIds(new List<Id>());
        Test.stopTest();
        System.assert(!timeSlots.isEmpty(), 'Time Slots not retrived successfully');
        System.assert(timeSlotsNegative.isEmpty(), 'Time Slots retrived');
        System.assert(timeSlotsEmpty.isEmpty(), 'Time Slots retrived');
    }
}