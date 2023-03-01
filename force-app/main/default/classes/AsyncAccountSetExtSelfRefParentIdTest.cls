/************************************************************************************************************************************
    Author      :   Mikolaj Juras
    @Description :  Test class for AsyncAccountSetExtSelfRefParentId and
    Issue No    :     ST-7574
    History        :
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION     DATE                AUTHOR              ISSUE NO        DETAIL
    1         28 January 2021       Mikolaj Juras       ST-7574         Initial Developement
    2         5 Feb      2021       Mikolaj Juras       ST-7693         Fix too many quables issue
    3         18 Feb     2021       Mikołaj Juras       ST-7781         fix future from futre error
**************************************************************************************************************************************/
@isTest
public class AsyncAccountSetExtSelfRefParentIdTest {

    private static final Integer NUMBER_OF_ACCOUNTS_TO_INSERT = 150;

    @testSetup
    static void makeData() {
        //execute without trigger not to poulate the External_Parent_Org_Id__c with AsyncAccountSetExtSelfRefParentId class
        MetadataDrivenTriggerHandler.disableExecution();
        List<Account> accounts = (List<Account>)TestingUtility.getRecords(
                new Map<String, Object>{'objName' => 'Account', 'numberOfRecords' => NUMBER_OF_ACCOUNTS_TO_INSERT, 'doInsert' => true}
        );
        MetadataDrivenTriggerHandler.enableExecution();
    }

    @isTest
    public static void executePopulateLongParentOrgIdBatchFutureTest() {
        System.assertEquals([SELECT count() FROM Account WHERE External_Parent_Org_Id__c = null], NUMBER_OF_ACCOUNTS_TO_INSERT,'External_Parent_Org_Id__c should be empty now as triggers are off');

        Test.startTest();
        AsyncAccountSetExtSelfRefParentId asyncAccountSetExtSelfRefParentId = new AsyncAccountSetExtSelfRefParentId();
        asyncAccountSetExtSelfRefParentId.setExtSelfRefParentOrgId(new Map<Id, Account>([SELECT Id FROM Account]).keySet());
        Test.stopTest();

        System.assert([SELECT Id FROM Account WHERE External_Parent_Org_Id__c = null].isEmpty(),'After Async job the External_Parent_Org_Id__c field should be populated');
        System.assertEquals([SELECT count() FROM Account WHERE External_Parent_Org_Id__c != null], NUMBER_OF_ACCOUNTS_TO_INSERT,'External_Parent_Org_Id__c must be populated');
    }

    @isTest
    public static void executePopulateLongParentOrgIdBatchQueueableTest() {
        System.assertEquals([SELECT count() FROM Account WHERE External_Parent_Org_Id__c = null], NUMBER_OF_ACCOUNTS_TO_INSERT,'External_Parent_Org_Id__c should be empty now as triggers are off');

        Test.startTest();
        AsyncAccountSetExtSelfRefParentId asyncAccountSetExtSelfRefParentId = new AsyncAccountSetExtSelfRefParentId();
        asyncAccountSetExtSelfRefParentId.setExtSelfRefParentOrgIdQueueable(new Map<Id, Account>([SELECT Id FROM Account]).keySet());
        Test.stopTest();

        System.assert([SELECT Id FROM Account WHERE External_Parent_Org_Id__c = null].isEmpty(),'After Async job the External_Parent_Org_Id__c field should be populated');
        System.assertEquals([SELECT count() FROM Account WHERE External_Parent_Org_Id__c != null], NUMBER_OF_ACCOUNTS_TO_INSERT,'External_Parent_Org_Id__c must be populated');
    }
}