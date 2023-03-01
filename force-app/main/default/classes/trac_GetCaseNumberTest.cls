/**
 * @description unit tests for the trac_GetCaseNumber class
 * @name trac_GetCaseNumberTest
 * @author Daniel Labonte, Traction on Demand
 * @date 2019-10-24
 */

@IsTest
private class trac_GetCaseNumberTest {
    static final TLTestFactory factory = new TLTestFactory();

    @IsTest
    static void testGetCaseNumber() {
        //Case cs = (Case) factory.createSObject(new Case(),true);
        BusinessHours hours = [SELECT ID
        FROM BusinessHours
        WHERE Name='India (Asia/Kolkata)'];
        Case testCase = new Case();
        testCase.SuppliedEmail = 'test@test.test';
        testCase.Status='Solved';
        testCase.RecordTypeId=(Schema.SObjectType.Case.getRecordTypeInfosByName().get('Enterprise Finance & Strategy').getRecordTypeId());
        testCase.Origin = 'Email';
        testCase.BusinessHoursId = hours.Id;
        testCase.First_Response_Time__c = System.now();
        testCase.CreatedDate = System.now();
        insert testCase;
        trac_GetCaseNumber.Inputs inputs = new trac_GetCaseNumber.Inputs();
        inputs.caseId = testCase.Id;

        List<String> caseNumber = trac_GetCaseNumber.getCaseNumber(new List<trac_GetCaseNumber.Inputs>{inputs});
        System.assert(caseNumber != null, 'The case number was not retrieved');
        
        inputs.caseId = null;
        List<String> caseNumber1 = trac_GetCaseNumber.getCaseNumber(new List<trac_GetCaseNumber.Inputs>{inputs});
    }
 }