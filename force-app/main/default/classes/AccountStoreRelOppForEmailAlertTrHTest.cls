/**************************************************************************************************************************
Author      :   Neelima
Description :   This is test class for AccountStoreRelOppForEmailAlertTrH
Issue No    :   -
History     :
-------------------------------------------------------------------------------------------------------------------------
VERSION         DATE            AUTHOR              DETAIL
1            01/04/2022        Neelima             Increased the code coverage
*************************************************************************************************************************/
@isTest
public class AccountStoreRelOppForEmailAlertTrHTest {
    @isTest
    public static void accMethod(){
        
        Id businessRecId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Business Account').getRecordTypeId();
        List<User> userList = new List<User>();
        userList = [SELECT Id FROM user WHERE isActive=:TRUE LIMIT 2];
        
        Account acc = new Account();
        acc.name = 'Test Account';
        acc.Number_of_Full_Time_Employees__c = 10;
        acc.RecordTypeId = businessRecId;
        acc.OwnerId = userList.get(0).Id;
        insert acc;
            
        Opportunity opp = new Opportunity(
            Do_Not_Create_Opportunity_Role__c = true,
            AccountId = acc.id,
            LeadSource = 'WeWork.com',
            StageName = 'Qualifying',
            Interested_in_Number_of_Desks__c = 0,
            CloseDate = System.today().addDays(5),OwnerId = UserInfo.getUserId());
        TestingUtility.insertWithAssert(opp);
        
        Test.startTest();        
        Account getAcc = [SELECT Id,OwnerId FROM Account WHERE Id =: acc.Id];
        getAcc.OwnerId = userList.get(1).Id;
        Test.stopTest();
        
        AccountStoreRelOppForEmailAlertTrH ar = new AccountStoreRelOppForEmailAlertTrH(new List<Account>{getAcc}, new Map<Id, Account>{acc.Id => acc});
        
        ar.beforeUpdate();
        
        System.assertEquals(true,AccountStoreRelOppForEmailAlertTrH.accRelatedOpportunityOnAccOwnerChange.containsKey(opp.Id),'Both Opportunity Id should be same');
        System.assertEquals([SELECT AccountId, Id, OwnerId FROM Opportunity WHERE Id=:opp.Id LIMIT 1], AccountStoreRelOppForEmailAlertTrH.accRelatedOpportunityOnAccOwnerChange.get(opp.Id), 'both should have same Opportunity Id');
    
    }
}