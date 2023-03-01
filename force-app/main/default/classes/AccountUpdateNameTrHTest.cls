@isTest
public class AccountUpdateNameTrHTest {
    private static final String PARENT1_UUID = 'parent-UUID-001';
    private static final String PARENT2_UUID = 'parent-UUID-002';
    @testSetup 
    private static void setupTestData(){      
        
        List<Account> parentOrgAccounts = new List<Account>();
        parentOrgAccounts.add(TestingUtility.createAccount(new Map<String,Object>{'Name' => 'Parent Account 1', 'BillingCity' => 'Mumbai', 'BillingCountry' => 'India', 'UUID__c' => PARENT1_UUID, 'Account_Type__c' => 'Org'}, false));
        parentOrgAccounts.add(TestingUtility.createAccount(new Map<String,Object>{'Name' => 'Parent Account 2', 'BillingCountry' => 'India', 'UUID__c' => PARENT2_UUID, 'Account_Type__c' => 'Org'}, false));
        Test.startTest();
        insert parentOrgAccounts;
        List<Account> salesAccounts = new List<Account>(); 
        salesAccounts.add(TestingUtility.createAccount(new Map<String,Object>{'ParentId' => parentOrgAccounts[0].Id, 'Name' => 'Sales Account 1',  'UUID__c' => 'sales-UUID-001', 'Account_Type__c' => 'Sales', 'Nickname__c' => 'sales-UUID-001'}, false));       
        salesAccounts.add(TestingUtility.createAccount(new Map<String,Object>{'ParentId' => parentOrgAccounts[1].Id, 'Name' => 'Sales Account 2', 	'UUID__c' => 'sales-UUID-002', 'Account_Type__c' => 'Sales', 'Nickname__c' => 'sales-UUID-002'}, false));
        insert salesAccounts;
        Test.stopTest();
        List<Account> insertedAccounts = getSalesAccounts();
        System.assert(insertedAccounts.size() == 2, 'Only 2 accounts should be created');
        checkSalesAccountNamingConvertionAssertions(insertedAccounts);
    }
    
    @isTest
    private static void verifySalesAccountNameOnUpdate(){
        List<Account> parentOrgAccounts = [SELECT Id, UUID__c FROM Account WHERE Account_Type__c = 'Org' AND UUID__c = :PARENT1_UUID];
        List<Account> insertedSalesAccounts = getSalesAccounts();
        for(Account salesAccount : insertedSalesAccounts){
            if(salesAccount.Parent.UUID__c == PARENT1_UUID){
                salesAccount.ParentId =  parentOrgAccounts[0].Id;
            }
        }
        Test.startTest(); 
        update insertedSalesAccounts;  
        Test.stopTest();
        List<Account> insertedAccounts = getSalesAccounts();
        System.assert(insertedAccounts.size() == 2, 'Only 2 accounts should be created');
        checkSalesAccountNamingConvertionAssertions(insertedAccounts);
    }
    
    private static List<Account> getSalesAccounts(){
        return [SELECT Id, Name, Account_Type__c, Parent.UUID__c, ParentId, Nickname__c FROM Account WHERE Account_Type__c = 'Sales'];
    }
    
    private static void checkSalesAccountNamingConvertionAssertions(List<Account> accounts){
        for(Account newAccount :accounts){
            if(newAccount.Account_Type__c != 'Sales'){
                continue;
            }
            if(newAccount.Parent.UUID__c == PARENT1_UUID){
                System.assertEquals(newAccount.Name, 'Parent Account 1:'+newAccount.Nickname__c, 'Account name should be Parent Account 1:Nickname');
            }else if(newAccount.Parent.UUID__c == PARENT2_UUID){               
                System.assertEquals(newAccount.Name, 'Parent Account 2:'+newAccount.Nickname__c, 'Account name should be Parent Account 2:Nickname');  
            }
        }
    }
    
}