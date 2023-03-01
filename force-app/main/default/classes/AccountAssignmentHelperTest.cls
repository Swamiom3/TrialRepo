@isTest 
public class AccountAssignmentHelperTest {    
    @isTest 
    public static void accountAssignHelper(){
        Test.startTest();
        AccountAssignmentHelper accAssHel = New AccountAssignmentHelper();
        Integer stringArray = AccountAssignmentHelper.getLowerSize('5');
        AccountAssignmentHelper.getLowerSize('');
        Account acc = New Account();
        acc.name = 'Test Account';
        acc.Number_of_Full_Time_Employees__c = 10;
        acc.RecordTypeId = [SELECT Id FROM recordtype WHERE developername =:'Business_Account'].Id;
        insert acc;
        
        Integer intVal = AccountAssignmentHelper.getCompanySizeFromAccount(acc);
        ID cmpId = AccountAssignmentHelper.getApiUserId('Integer');
        AccountAssignmentHelper.getGlobalDescribe();
        AccountAssignmentHelper.getRecordTypeNameById('Account',acc.RecordTypeid);
        AccountAssignmentHelper.getRecordTypeNameById('',acc.RecordTypeid);
        
        Id userId = [SELECT Id
                     FROM User
                     WHERE IsActive =: true
                           AND Profile.Name != null
                     LIMIT 1].Id;
        
        AccountAssignmentHelper.checkValidUserForAssignment(userId);
        AccountAssignmentHelper.checkValidUserForAssignment(null);
        AccountAssignmentHelper.isValidProfileAndUserForAssignment(userId);
        AccountAssignmentHelper.isValidProfileAndUserForAssignment('');
        AccountAssignmentHelper.isApiUser('Id', userId);
        AccountAssignmentHelper.getApiUserId('Id');
        AccountAssignmentHelper.getCompanySizeFromAccount(acc);
        AccountAssignmentHelper.getLowerSize('7');
        Test.stopTest();
        try{
            AccountAssignmentHelper.getRecordTypeIdFromCompanySize(acc);
            System.assert(false);
        }catch(Exception e){            
            System.assertEquals('System.NullPointerException', e.getTypeName(),'Attempt to de-reference a null object');
        } 
    }
}