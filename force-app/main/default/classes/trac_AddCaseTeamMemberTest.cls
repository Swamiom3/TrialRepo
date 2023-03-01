@isTest
public class trac_AddCaseTeamMemberTest {
    static final TLTestFactory factory = new TLTestFactory();
   @isTest
    public static void testAddCaseTeamMember(){
        List<Case> cases = (List<Case>) factory.createSObjects(new Case(SuppliedEmail = 'test@test.test'), 2, false);
        insert cases[0];
        List<trac_AddCaseTeamMember.Inputs> inp1 = new List<trac_AddCaseTeamMember.Inputs>();
        trac_AddCaseTeamMember.Inputs inp2 = new trac_AddCaseTeamMember.Inputs();
        inp2.caseId = cases[0].Id;
        inp2.userId = userinfo.getUserId();
        inp1.add(inp2);
        Test.startTest();
        trac_AddCaseTeamMember.getCaseNumber(inp1);
        Test.stopTest();
    }
}