/********************************************************************************************************************
   Name              : DateFormatterTest
   Description       : test for DateFormatter class.

   Revision History  :-
   Created/Modified by                     Created/Modified Date       Requested by                  Technical Design Proposal
   ---------------------------------------------------------------------------------------------------------------------
   1. Rashad Saeed (initial implementation)     24 Mar 2019               WeWork                           CSI-1827

   ---------------------------------------------------------------------------------------------------------------------
********************************************************************************************************************/
@isTest
public class DateFormatterTest {
    @isTest
    static void testDayMonthNameYear() {
        Date tdate = Date.newinstance(1984, 1, 16);
        DateFormatter.dayMonthNameYear(null);
        System.assertEquals('16 January, 1984', DateFormatter.dayMonthNameYear(tdate));
    }

    @isTest
    static void testMonthDayYear() {
        Date tdate = Date.newinstance(1984, 1, 16);
        System.assertEquals('Jan 16, 1984', DateFormatter.monthDayYear(tdate));
    }
}