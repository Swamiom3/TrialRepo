/************************************************************************************************************************************
Author      :   Maciej Miłosz
Description :   Test for DatabaseResult class
----------------------------------------------------------------------------------------------------------------------------------
VERSION     DATE                AUTHOR                  DETAIL
1           01 Feb 2022         Maciej Miłosz           Initial Developement
**************************************************************************************************************************************/
@isTest
public class DatabaseResultTest {

    public static testMethod void constructorsTest(){
        String tempData = 'temp';
        DatabaseResult testByObject = new DatabaseResult(tempData);

        System.assertEquals(true, testByObject.success, 'For constructor that is using object as input, success should be alwyes true');
        System.assertEquals('', testByObject.message, 'For constructor that is using object as input, message should be alwyes empty');
        System.assertEquals(tempData, (String) testByObject.data, 'For constructor that is using object as input, input object should be castable back to original type');

        DatabaseResult testByData = new DatabaseResult(false, tempData, 'Custom message');
        System.assertEquals(false, testByData.success, 'For constructor that is using all data, success should be alwyes as passed');
        System.assertEquals('Custom message', testByData.message, 'For constructor that is using all data, message should be alwyes as passed');
        System.assertEquals(tempData, (String) testByData.data, 'For constructor that is using all data, input object should be castable back to original type');

        StringException ex = new StringException();
        ex.setMessage('Exception');
        DatabaseResult testByException = new DatabaseResult(ex);
        System.assertEquals(false, testByException.success, 'For constructor that is using exception, success is alwyes false');
        System.assertEquals(ex.getMessage(), testByException.message, 'For constructor that is using exception, message should be as exception message');
        System.assertEquals(null, testByException.data, 'For constructor that is using exception, input object should be null');
    }
}