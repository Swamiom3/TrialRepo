/************************************************************************************************************************************
    Author      :   Vaishnavi Khandar 
    Description :   This class contains the unit test logic for ScheduledBatchForREAPIntergration class.
    History     :
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION     DATE                AUTHOR                  DETAIL
    1           18 Novemeber 2021   Vaishnavi Khandar        Initial Developement
**************************************************************************************************************************************/
@isTest
public class ScheduledBatchForREAPIntergrationTest {
    @testSetup
    static void initData(){
        Test.startTest();
        REAPIntegrationUtilsTest.testSetupHelper();
        Test.stopTest();
    }
    @isTest
    static void testschedule() {
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponeGeneratorForREAPAPI());
        ScheduledBatchForREAPIntergration testschedule = new ScheduledBatchForREAPIntergration();
        System.schedule('REAP Integration API', '0 0 5 * * ?', testschedule); 
        Test.stopTest();
    }
}