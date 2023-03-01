/*************************************************************************************************************************************
    Author      :    Sudhanshu Patil
    Description :    This class provides sufficient test coverage for LookupControllerClass
    --------------------------------------------------------------------------------------------------------------------------------------
    VERSION    DATE            AUTHOR             DETAIL
    1          08 Dec, 2021    Sudhanshu Patil    Initial Deployment
**************************************************************************************************************************************/

@isTest
public class LookupControllerTest {
    @isTest 
    static void searchTest() {
        
        Account createAccount = new Account();
        createAccount.LastName = 'TestLastName';
        insert createAccount;
        
        String searchTerm = 'TestLastName';
        String myObject = 'Account'; 
        String filter = 'LastName=\'TestLastName\''; 
        Test.startTest();
        List<sObject> result = LookupController.search(searchTerm,myObject,filter);
        List<sObject> allAccountResult = LookupController.search('',myObject,'');
        Test.stopTest();
        System.assertEquals([SELECT Id,Name FROM Account WHERE Id=:createAccount.Id], result, 'List of Accounts are not same');
        System.assertEquals([SELECT Id,Name FROM Account WHERE Id=:createAccount.Id].size(), result.size(), 'Size must be same');
        System.assertEquals([SELECT Id,Name FROM Account ORDER BY Name ASC LIMIT 5], allAccountResult, 'Should get List of top 5 Accounts in ascending order');
        
    }
}