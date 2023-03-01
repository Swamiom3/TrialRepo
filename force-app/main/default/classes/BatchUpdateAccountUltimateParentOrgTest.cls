/************************************************************************************************************************************
Author      :  Salesforce
Description :  BatchUpdateAccountUltimateParentOrg batch apex test class
Issue No    :  TWSPG-12319

-------------------------------------------------------------------------------------------------------------------------------------
VERSION       DATE             AUTHOR                DETAIL
   1      16-JUNE-2022       Salesforce         Initial Developement
**************************************************************************************************************************************/
@isTest
private with sharing class BatchUpdateAccountUltimateParentOrgTest {
    
    @testSetup
    static void createTestData() {
        MetadataDrivenTriggerHandler.disableExecution();
        List<Account> salesAccountHierarchy = TestingUtility.getSalesAccountsWithHierarchy(3, true);
        MetadataDrivenTriggerHandler.enableExecution();
    }

    @isTest
    static void testBatchUpdateAccountUltimateParentOrgExecute(){
        String query = 'SELECT Id, Account_Type__c, Parent_Org_Id__c, Ultimate_Parent_Org__c FROM Account WHERE Account_Type__c = \'Sales\' AND Ultimate_Parent_Org__c = null';
        BatchUpdateAccountUltimateParentOrg batchUpdateAccounts = new BatchUpdateAccountUltimateParentOrg(query);
        Id batchJobId;
        Test.startTest();
        batchJobId = Database.executeBatch(batchUpdateAccounts, 10);
        Test.stopTest();
        AsyncApexJob resultApexJob = [SELECT Id, Status FROM AsyncApexJob WHERE Id =: batchJobId];
        System.assertEquals('Completed', resultApexJob.Status, 'BatchUpdateAccountUltimateParentOrg apex job is completed');
        Account orgAccount = [SELECT Id FROM Account WHERE Account_Type__c = 'Org' LIMIT 1];
        List<Account> resultSalesAccount = [SELECT Id, Ultimate_Parent_Org__c FROM Account WHERE Account_Type__c = 'Sales' LIMIT 2];
        System.assertEquals(resultSalesAccount[0].Ultimate_Parent_Org__c, orgAccount.Id, 'Updated Sales Account UltimateParentOrg Field Successfully');
        System.assertEquals(resultSalesAccount[1].Ultimate_Parent_Org__c, orgAccount.Id, 'Updated Sales Account UltimateParentOrg Field Successfully');
    }
}