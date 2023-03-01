/************************************************************************************************************************************
    Author       :   Mikolaj Juras    
    @Description :  Test class for AccountSetExternalParentOrgIdTrH
    Issue No     :     ST-7574
    History      :
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION     DATE                AUTHOR              ISSUE NO        DETAIL
    1           28 January 2021     Mikolaj Juras       ST-7574         Initial Developement 
    2           18 Feb     2021     Mikołaj Juras       ST-7781         fix future from futre error
**************************************************************************************************************************************/
@IsTest
public class AccountSetExternalParentOrgIdTrHTest  {

    @testSetup
    static void setUp() {
        List<Account> lstAccounts = (List<Account>)TestingUtility.getRecords(new Map<String, Object>{'objName' => 'Account', 'numberOfRecords' => 3});
    }

    @isTest
    public static void testAccountSetExternalParentOrgId() {

        List<Account> accList = [SELECT Id, Parent_Org_Id__c, External_Parent_Org_Id__c FROM Account WHERE ParentId = null LIMIT 2];
        System.assert(accList[0].External_Parent_Org_Id__c == accList[0].Id, 'External_Parent_Org_Id__c should be populated from async call and equal to Id - self referenece');
        accList[1].ParentId = accList[0].Id;
        Test.startTest();
        update accList[1];
        Test.stopTest();
        Account updatedAccount = [SELECT External_Parent_Org_Id__c FROM Account WHERE Id = :accList[1].Id];
        System.assert(updatedAccount.External_Parent_Org_Id__c == accList[0].Id, 'Account Parent Id should be equal external Parent Org Id ');
        System.assertEquals(updatedAccount.External_Parent_Org_Id__c.length(), 18, 'External_Parent_Org_Id__c must be 18 digits');
    }
}