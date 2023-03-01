@isTest
public class trac_DuplicateCaseControllerTest {
     static final TLTestFactory factory = new TLTestFactory();
    @isTest
    public static void testDuplicateCaseControllerTest(){
        List<Case> cases = (List<Case>) factory.createSObjects(new Case(SuppliedEmail = 'test@test.test',subject='Testdata'), 2, false);
        insert cases;
        List<Case> cases1;
        List<String> fieldsupd= new List<String>();
        fieldsupd.add('Location__c');
        fieldsupd.add('Subject');
        Duplicate_Case_Setting__c settings = new Duplicate_Case_Setting__c ();
        settings.Fields_to_Match__c = 'Location__c';
        settings.Match_Number_Days_Old__c =10;
        settings.Subject_Match__c = 5;
        insert settings;
        
        Test.startTest();
        trac_DuplicateCaseController.getFields();
        Double testdata = trac_DuplicateCaseController.similarity('Test1', 'Test2');
        String testdata1 = trac_DuplicateCaseController.prepareString('Test3');
        cases1 = trac_DuplicateCaseController.getDuplicateCases(cases[0].id,fieldsupd);
        Test.stopTest();
    }

}