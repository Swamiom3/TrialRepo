@IsTest
public class trac_TranslationControllerCaseTest {
    
    static final TLTestFactory factory = new TLTestFactory();
    
    @TestSetup
    static void UnitTest(){
        Case cs = (Case) factory.createSObject(new Case(RecordTypeId = TLOrgConstants.SUPPORT_REQUEST_RECORD_TYPE_ID, Subject = 'Test Case', Description = 'Test description'),true);        
        Case cs1 = (Case) factory.createSObject(new Case(RecordTypeId = TLOrgConstants.SUPPORT_REQUEST_RECORD_TYPE_ID),true);

        Global__c settings = new Global__c();
        settings.Translation_End_Point__c = 'http://example.com/';
        settings.Translation_API_Key__c = 'asdf';
    }
    
    @IsTest
    static void doTranslationMethod(){
        List<Case> lstcases = [SELECT Id FROM Case];
        Test.startTest();
        
        trac_TranslationControllerCase.doTranslation(lstcases[0].Id, 'en');
        trac_TranslationControllerCase.doTranslation(lstcases[1].Id, 'en');
        trac_TranslationControllerCase.getLanguageOptions();
        Test.stopTest();
    }

    @IsTest
    static void testCallout() {
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new trac_TranslateCalloutMock());
        String des = 'Test';
        String sub ='Test';
        trac_TranslationParser tracparse = new trac_TranslationParser();
        trac_TranslationParser.Data tracparsedata = new trac_TranslationParser.Data();
        trac_TranslationParser.Translations tracparsedatatrans = new trac_TranslationParser.Translations();
        List<trac_TranslationParser.Translations> transl = new List<trac_TranslationParser.Translations>();
        tracparsedata.translations = transl;
        tracparsedatatrans.translatedText = 'Test';
        tracparse.data = tracparsedata;
        trac_TranslationControllerCase.TranslationWrapper transWrap = new trac_TranslationControllerCase.TranslationWrapper(des,sub);
        trac_TranslateCallout res = new trac_TranslateCallout();
        res.translateLanguage('Hello','en');
        Test.stopTest();
    }
   
}