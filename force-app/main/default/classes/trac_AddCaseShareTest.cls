/**
 * @description Unit tests for the trac_AddCaseShare class
 * @see trac_AddCaseShare
 * @author Daniel Labonte, Traction on Demand
 * @date 2020-04-08
 */

@IsTest
private class trac_AddCaseShareTest {

    static final TLTestFactory FACTORY = new TLTestFactory();

    @IsTest
    static void testCreateCaseShare() {
        User user = TLTestUtils.createUsers('Read Only',1,true)[0];
        Case cs = (Case) FACTORY.createSObject(new Case(),true);

        trac_AddCaseShare.Inputs input = new trac_AddCaseShare.Inputs();
        input.accessLevel = 'Edit';
        input.rowCause = 'Manual';
        input.caseId = cs.Id;
        input.userId = user.Id;

        Test.startTest();
        trac_AddCaseShare.insertShareRecord(new List<trac_AddCaseShare.Inputs>{input});
        Test.stopTest();

        List<CaseShare> shares = [SELECT Id FROM CaseShare WHERE CaseId = :cs.Id AND UserOrGroupId = :user.Id];
        System.assert(shares.size() == 1, 'A Case Share record should have been inserted');
    }


    @IsTest
    static void testBadCaseShare() {
        User user = TLTestUtils.createUsers(1,true)[0];
        Case cs = (Case) FACTORY.createSObject(new Case(),true);

        trac_AddCaseShare.Inputs input = new trac_AddCaseShare.Inputs();
        input.accessLevel = 'Edet'; // bad input
        input.rowCause = 'Manual';
        input.caseId = cs.Id;
        input.userId = user.Id;

        Test.startTest();
        try {
            trac_AddCaseShare.insertShareRecord(new List<trac_AddCaseShare.Inputs>{input});
            System.assert(false, 'An error should have been thrown here because of bad access level input');
        } catch (Exception e) {
            System.assert(true, 'An error should be thrown here because of bad access level input');
        }
        Test.stopTest();
    }
}