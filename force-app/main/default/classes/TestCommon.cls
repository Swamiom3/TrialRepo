@isTest
public class TestCommon {
    @isTest static void testCommonTest() {
        String InputString1 = 'Test';
        String[] splitStringList = Common.splitStringToList(InputString1, ';');
        String getObjectFields = Common.getSobjectFields('Account');
        String InputString2 = 'Test';
        Set<string> setInputString = new Set<string>();
        setInputString = Common.splitStringToSet(InputString2, ';');
    }
    
}