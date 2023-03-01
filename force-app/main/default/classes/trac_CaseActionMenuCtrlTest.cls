@isTest
public class trac_CaseActionMenuCtrlTest {
     static final TLTestFactory factory = new TLTestFactory();
    @isTest
    public static void testCaseActionMenu(){
        Map<String,Boolean> testMapdata = new Map<String,Boolean>();
        Boolean boolvalue ;
        List<Case> cases = (List<Case>) factory.createSObjects(new Case(SuppliedEmail = 'test@test.test'), 2, false);
        insert cases[0];
        
        Test.startTest();
        testMapdata =trac_CaseActionMenuController.loadButtonInfo(cases[0].Id) ;
        boolvalue = trac_CaseActionMenuController.assignCaseToUser(cases[0].Id);
        Test.stopTest();
    }

}