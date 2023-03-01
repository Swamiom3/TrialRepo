@isTest
public class FieldPickerControllerTest {
    
    @isTest
    public static void canGetPicklistValues() {
        String accountString = 'Account';
        String fieldName = 'Type';
        List<FieldPickerController.Member> memberList = FieldPickerController.getPicklistValues(accountString, fieldName);
        System.assertNotEquals(null, memberList,'Member List should not be Blank');
    
    }

    @isTest
    public static void canGetObjectValues() {
        String accountString = 'Account';
        String fieldName = 'Type';
        List<String> objectNames = new List<String>();
        objectNames.add(accountString);
        List<FieldPickerController.Member> memberList = FieldPickerController.getObjects(objectNames);
        System.assertNotEquals(null, memberList,'Member List should not be Blank');
    
    }
}