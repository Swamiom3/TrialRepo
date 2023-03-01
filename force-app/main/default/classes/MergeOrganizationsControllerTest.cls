@isTest
public class MergeOrganizationsControllerTest {
    /************************************************************************************************************************************
        Author 			: Rupesh Patil
        Description 	: This method has setup data for all test methods 
        Created Date	: 28 Nov 2018 
    **************************************************************************************************************************************/

    
    @TestSetup
    static void initData(){         
        //List<Contact> lstContacts = (List<Contact>)TestingUtility.getRecords(new Map<String, Object>{'objName' => 'Contact', 'numberOfRecords' => 4});
        List<Account> lstAccounts = (List<Account>)TestingUtility.getRecords(new Map<String, Object>{'objName' => 'Account', 'numberOfRecords' => 6});
        //List<Building__c> lstBuildings = (List<Building__c>)TestingUtility.getRecords(new Map<String, Object>{'objName' => 'Building__c', 'numberOfRecords' => 1});
        //List<Tour_Outcome__c> lstTours = (List<Tour_Outcome__c>)TestingUtility.getRecords(new Map<String, Object>{'objName' => 'Tour', 'numberOfRecords' => 4});
        Test.startTest(); 
       // List<Geography__c> lstGeographies = (List<Geography__c>)TestingUtility.getRecords(new Map<String, Object>{'objName' => 'Geography__c', 'numberOfRecords' => 2});
        //List<Billing_Account__c> lstBillingAccounts = (List<Billing_Account__c>)TestingUtility.getRecords(new Map<String, Object>{'objName' => 'Billing_Account__c', 'numberOfRecords' => 1, 'doInsert' => true, 'method' => 'simpleBillingAccount'});        
        //List<Opportunity> lstOpportunities = (List<Opportunity>)TestingUtility.getRecords(new Map<String, Object>{'objName' => 'Opportunity', 'numberOfRecords' => 1, 'doInsert' => true, 'mapFieldValues' => new Map<String, List<Object>>{'Contract_Stage__c' => new List<Object>{'Contract Sent'}, 'Billing_Account__c' => new List<Object>{lstBillingAccounts[0].Id}}});       
        //List<Campaign> lstCampaigns = (List<Campaign>)TestingUtility.getRecords(new Map<String, Object>{'objName' => 'Campaign', 'numberOfRecords' => 1});      
        Test.stopTest(); 
    }
    
/************************************************************************************************************************************
        Author 			: Sunil Bhosale
        Description 	: This method verify the merge organization functionality.
        Created Date	: 27 July 2018 
  **************************************************************************************************************************************/
    public static testMethod void verifyValidateAccounts(){
        List<Id> lstAccountIDs = new List<Id>();  
        List<Account> lstAccounts = new List<Account>();        
        Account orgAccount = new Account();
        orgAccount = TestingUtility.createAccount('strAccountName', false);
        orgAccount.Account_Type__c = 'Org'; 
        orgAccount.Unomy_Company_ID__c = 1234 ;
        orgAccount.Cleansed_Account_Name__c = 'test company cleansed';
        lstAccounts.add(orgAccount);
        //insert orgAccount;
       
        Account orgAccount1 = TestingUtility.createAccount('strAccountName1', false);
        orgAccount1.Account_Type__c = 'Org'; 
        orgAccount1.Unomy_Company_ID__c = 12345 ;
        orgAccount1.Cleansed_Account_Name__c = 'test company2 cleansed';
        lstAccounts.add(orgAccount1);
       
        
        Account orgAccount2 = TestingUtility.createAccount('strAccountName2', false); 
        orgAccount2.Account_Type__c = 'Org'; 
        orgAccount2.Unomy_Company_ID__c = 12345 ;
        orgAccount2.Cleansed_Account_Name__c = 'test company2 cleansed';
        lstAccounts.add(orgAccount2); 
        Test.startTest();
        TestingUtility.insertListWithAssert(lstAccounts);        
        lstAccountIDs.add(lstAccounts[0].Id); 
        lstAccountIDs.add(lstAccounts[1].Id);
        lstAccountIDs.add(lstAccounts[2].Id);        
        MergeOrganizationsController.validateAccounts(orgAccount.Id,lstAccountIDs);
        Test.stopTest();
    }
   
    public static testMethod void verifyGetAccounts(){
        List<String> lstQuery = new List<String>();
        List<Account> lstAccount = new List<Account>();
        
        Account masterAcc = new Account();
        masterAcc = TestingUtility.createAccount('AccountName', false);
        masterAcc.Account_Type__c = 'Org';
        masterAcc.Nickname__c='PrinarySalesAcc';
        insert masterAcc;
        
        Account objAccount = TestingUtility.createAccount('AccountName', false);
        objAccount.Account_Type__c = 'Sales';
        objAccount.Nickname__c='PrinarySalesAcc';
        objAccount.ParentId = masterAcc.id;
        lstAccount.add(objAccount);
        Account objAccount2 = TestingUtility.createAccount('AccountName2', false);
        objAccount2.Account_Type__c = 'Sales';
        objAccount2.ParentId = masterAcc.id;
        objAccount2.Nickname__c='SalesAcc2';
       	lstAccount.add(objAccount2);
        Test.startTest();
        insert lstAccount;
        lstQuery.add('SELECT Id FROM Account');
        lstQuery.add('SELECT Id FROM Account');
        System.debug('MergeOrganizationsControllerTest.verifyGetAccounts SOQL LIMIT: '+Limits.getLimitQueries());
        MergeOrganizationsController.getAccountsToDisplay(lstQuery);
        Test.stopTest();
    }
    
    /************************************************************************************************************************************
        Author 			: Krishana Tupe
        Description 	: This method verify the merge organization functionality.
        Created Date	: 27 July 2018 
		Last Modified By: Rupesh Patil
		Last Modified Date : 28 Nov 2018
  **************************************************************************************************************************************/
    public static testMethod void verifyMergeAccounts(){
        List<Account> lstAccounts = [SELECT Id, Name, Account_Type__c, Nickname__c FROM Account LIMIT 7];
        List<Id> lstAccountIDs = new List<Id>{lstAccounts[0].Id, lstAccounts[1].Id, lstAccounts[2].Id};
        String result;
        Map<String, List<Account>> mapAccountsToMerge = new Map<String, List<Account>>();
        mapAccountsToMerge  = (Map<String, List<Account>>)MergeOrganizationsController.validateMergeAccounts(lstAccounts[0].Id, lstAccountIDs).data;        
        System.assert(mapAccountsToMerge.get('masterRecord') != null);
        System.assert(mapAccountsToMerge.get('lstMergedAccount') != null);
        LightningComponentController.ReturnValidResults objResults = new LightningComponentController.ReturnValidResults();
        Test.startTest();
        result  = (String)MergeOrganizationsController.mergeAccountsToMaster(mapAccountsToMerge.get('masterRecord')[0], mapAccountsToMerge.get('lstMergedAccount')).data;
        Map<String, Object> mapResult = (Map<String, Object>)JSON.deserializeUntyped(result);   
        System.assertEquals(true, mapResult.get('isSuccess'));
        System.assert(String.valueOf(mapResult.get('message')).equalsIgnoreCase('Accounts merged successfully. Redirecting you to the Primary Account'));
        
        //Insert three Sales accounts under one Org Account ,one is primary account and two Sales account for merge 
        Account orgAcc1 = TestingUtility.createAccount('orgAcc1', false);
        orgAcc1.Account_Type__c = 'Org';
        orgAcc1.Nickname__c='ParentOrg';
        insert orgAcc1;
        
        List<Account> lstSalesAcount = new  List<Account>();
        Account salesAcc1 = TestingUtility.createAccount('salesAcc1', false);
        salesAcc1.Account_Type__c = 'Sales';
        salesAcc1.Nickname__c='ParentSales';
        salesAcc1.ParentId = orgAcc1.Id;
        insert salesAcc1;
        Account salesAcc2 = TestingUtility.createAccount('salesAcc2', false);
        salesAcc2.Account_Type__c = 'Sales';
        salesAcc2.Nickname__c='SalesNic1';
        salesAcc2.ParentId = orgAcc1.Id;
        insert salesAcc2;
        Account salesAcc3 = TestingUtility.createAccount('salesAcc3', false);
        salesAcc3.Account_Type__c = 'Sales';
        salesAcc3.Nickname__c='SalesNic2';
        salesAcc3.ParentId = orgAcc1.Id;
        insert salesAcc3;
       
        lstAccountIDs = new List<Id>{salesAcc1.Id, salesAcc2.Id, salesAcc3.Id};
        mapAccountsToMerge  = (Map<String,List<Account>>)MergeOrganizationsController.validateMergeAccounts(salesAcc1.Id, lstAccountIDs).data;        
        System.assert(mapAccountsToMerge.get('masterRecord') != null);
        System.assert(mapAccountsToMerge.get('lstMergedAccount') != null);  
        result  = (String)MergeOrganizationsController.mergeAccountsToMaster(mapAccountsToMerge.get('masterRecord')[0], mapAccountsToMerge.get('lstMergedAccount')).data;
        Test.stopTest();      
        mapResult = (Map<String, Object>)JSON.deserializeUntyped(result);      
        System.assertEquals(true, mapResult.get('isSuccess'));
        System.assert(String.valueOf(mapResult.get('message')).equalsIgnoreCase('Accounts merged successfully. Redirecting you to the Primary Account'));       
        DatabaseResult result2 = MergeOrganizationsController.mergeAccountsToMaster(lstAccounts[5], mapAccountsToMerge.get('lstMergedAccount'));
        System.assert(result2.success);
    }
}