@isTest
public class trac_SupportRequestBatchScheduleTest {
    @isTest
    public static void tracSupportReqBatchSchedule(){
        trac_SupportRequestBatchSchedule tracsch = new trac_SupportRequestBatchSchedule();
        SchedulableContext sc ;
        Test.startTest();
        tracsch.execute(sc);
        Test.stopTest();
    }
}