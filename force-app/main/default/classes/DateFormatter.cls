/********************************************************************************************************************
   Name              : DateFormatter.cls
   Description       : Core class for custom date formatter  .

   Revision History  :-
   Created/Modified by                     Created/Modified Date       Requested by                  Technical Design Proposal
   ---------------------------------------------------------------------------------------------------------------------
   1. Rashad Saeed (initial implementation)     2 April 2019              WeWork                            CSI-1827
   ---------------------------------------------------------------------------------------------------------------------
 *********************************************************************************************************************/
public class DateFormatter {

    public static Map <integer, string> getMonthAsString = new Map <integer, String> {
        1 => 'January',
        2 => 'February',
        3 => 'March',
        4 => 'April',
        5 => 'May',
        6 => 'June',
        7 => 'July',
        8 => 'August',
        9 => 'September',
        10 => 'October',
        11 => 'November',
        12 => 'December'
    };

    //{21 March, 2019}
    public static String dayMonthNameYear(Date dateInstance) {
        if (dateInstance == null) {
            return null;
        }
        String result = String.valueOf (dateInstance.day() + ' ');
        result += getMonthAsString.get(dateInstance.month()) + ', ';
        result += String.valueOf(dateInstance.year());
        return result;
    }

    //Oct 05, 2020 MMM dd, yyyy
    public static String monthDayYear(Date dateInstance) {
        return DateUtilities.getDateTime(dateInstance).format('MMM dd, yyyy');
    }
}