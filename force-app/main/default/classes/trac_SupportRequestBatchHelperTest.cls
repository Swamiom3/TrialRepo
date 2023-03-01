@isTest
public class trac_SupportRequestBatchHelperTest {
     static final TLTestFactory factory = new TLTestFactory();
    @isTest
    public static void testSupportRequestBatchHelper(){
        List<Case> cases = (List<Case>) factory.createSObjects(new Case(SuppliedEmail = 'test@test.test'), 2, false);
        insert cases;
        Test.startTest();
        trac_SupportRequestBatchHelper.handleWaitingOnSupportRequest24Hrs(cases);
        trac_SupportRequestBatchHelper.handleWaitingOnSupportRequest4Days(cases);
        trac_SupportRequestBatchHelper.handleWaitingOnSupportRequestSubmitter(cases);
        Test.stopTest();
    }

}