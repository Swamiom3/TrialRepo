@isTest
public class AccountPreventDuplicateOrgNameTrHTest {
    private static final String DUPLICATE_ORG_NAME_ERROR_MSG = ' Organization already exists with the same name';
    @testSetup 
    private static void initData(){
        
        List<Account> accountRecords = new List<Account>();
        accountRecords.add(TestingUtility.createAccount(new Map<String,Object>{'Name' => 'Test-Account1',
            'Account_Type__c' => 'Org'}, false));
        accountRecords.add(TestingUtility.createAccount(new Map<String,Object>{'Name' => 'Test-Account2'}, false));
        TestingUtility.insertListWithAssert(accountRecords);
        
        List<Account> childAccountRecs = new List<Account>();
        childAccountRecs.add(TestingUtility.createAccount(new Map<String,Object>{'Name' => 'Sales Account', 
            'Account_Type__c' => 'Sales',
            'Nickname__c' => 'SalesAcc1', 
            'ParentId' => accountRecords[0].Id}, false));
        childAccountRecs.add(TestingUtility.createAccount(new Map<String,Object>{'Name' => 'Sales Account',
            'Account_Type__c' => 'Sales',
            'Nickname__c' => 'SalesAcc2',
            'ParentId' => accountRecords[0].Id}, false));
        TestingUtility.insertListWithAssert(childAccountRecs);
    }
    
    @isTest 
    private static void preventDuplicateOrgName(){
        Test.startTest();
        List<Account> accounts = [SELECT Id, Name, Account_Type__c, UUID__c, Parent_Org_Id__c, Nickname__c 
                                  FROM Account LIMIT 4]; 
        System.assert(!accounts.isEmpty());
        preventDuplicateOrgNameOnInsert(accounts);
        preventDuplicateOrgNameOnUpdate(accounts);
        Test.stopTest();
    }
    
    private static void preventDuplicateOrgNameOnInsert(List<Account> accounts){
        try{
            Account createDuplicateAccount = TestingUtility.createAccount(new Map<String,Object>{'Name' => 'Test-Account1', 'Account_Type__c' => 'Org'}, false);
            TestingUtility.insertWithAssert(createDuplicateAccount);
        }catch(Exception ex){
            System.assert(ex.getMessage().contains(accounts[0].Name + DUPLICATE_ORG_NAME_ERROR_MSG), ex.getMessage());
        }
        try{
            Account newSalesAccount = new Account(Name = 'Sales Account Rec', Account_Type__c = 'Sales', Nickname__c = 'SalesAcc1', ParentId = accounts[0].Id);
            TestingUtility.insertWithAssert(newSalesAccount);
        }catch(Exception ex){
            System.assert(ex.getMessage().contains('Sales Account with same Nickname "'+accounts[2].Nickname__c+'" already exists under the organization. Please choose another nickname.'), ex.getMessage());
        }
    }
    
    private static void preventDuplicateOrgNameOnUpdate(List<Account> accounts){
        try{
            accounts[1].Account_Type__c = 'Org';
            accounts[1].Name = 'Test-Account1';
            TestingUtility.updateWithAssert(accounts[1]);
        }catch(Exception ex){
            System.assert(ex.getMessage().contains(accounts[0].Name + DUPLICATE_ORG_NAME_ERROR_MSG), ex.getMessage());
        }
        try{
            accounts[3].Nickname__c = 'SalesAcc1';
            TestingUtility.updateWithAssert(accounts[3]);
        }catch(Exception ex){
            System.assert(ex.getMessage().contains('Sales Account with same Nickname "'+accounts[2].Nickname__c+'" already exists under the organization. Please choose another nickname.'), ex.getMessage());
        }
    }
}