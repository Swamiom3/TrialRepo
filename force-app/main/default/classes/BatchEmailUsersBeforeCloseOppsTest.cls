/******************************************************************************************************************** 
Name              : BatchEmailUsersBeforeCloseOppsTest  
Description       :  test for BatchEmailUsersBeforeCloseOppsScheduler 100% ,BatchEmailUsersBeforeCloseOpps 100% .
          

Revision History  :-
Created/Modified by                     Created/Modified Date       Requested by                  Technical Design Proposal
---------------------------------------------------------------------------------------------------------------------
1. Rashad Saeed (initial implementation)      27 AUG 2019                WeWork                           CSI-2327
           
---------------------------------------------------------------------------------------------------------------------
********************************************************************************************************************/
@isTest
Public class BatchEmailUsersBeforeCloseOppsTest {
    public static testMethod void testschedule() {
        Test.StartTest();
        List <Account> testAccounts = UtilAccount.GetNewAccounts(1, true);
        List <Opportunity> testOppoertunities = UtilOpportunity.GetNewOpportunity(3, testAccounts[0], true);
        BatchEmailUsersBeforeCloseOppsScheduler testsche = new BatchEmailUsersBeforeCloseOppsScheduler();
        String sch = '0 0 23 * * ?';
        system.schedule('Test status check', sch, testsche);
        Test.stopTest();
    }
}