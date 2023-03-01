/********************************************************************************************************************
   Name              : OppCustomPathTest
   Description       :  test for OppCustomPath.

   Revision History  :-
   Created/Modified by                     Created/Modified Date       Requested by                  Technical Design Proposal
   ---------------------------------------------------------------------------------------------------------------------
   1. Rashad Saeed (initial implementation)      22 SEP 2019               WeWork                           CSI-2274

   ---------------------------------------------------------------------------------------------------------------------
********************************************************************************************************************/
@isTest
public class OppCustomPathTest {
    @isTest
    static void oppCustomPathTest() {
        List <Account> testAccounts = UtilAccount.GetNewAccounts(1, true);
        List <Opportunity> testOpportunities = UtilOpportunity.GetNewOpportunity(1, testAccounts[0], true);
        opportunity theOpp = [select id,recordTypeId from Opportunity limit 1];
        Map<String,List<Opportunity_Stage_Required_Fields__mdt>> getOppField = new Map<String,List<Opportunity_Stage_Required_Fields__mdt>>();
        getOppField = OppCustomPath.getOppField('Qualifying', 'Closing', false, false, theOpp.Id, theOpp.recordTypeId);
        // the map should not contains  (Moving Backward) key.
        System.assertEquals(false, getOppField.containsKey('Moving Backward'));
        getOppField = OppCustomPath.getOppField('Closing', 'Qualifying', false, false, theOpp.Id, theOpp.recordTypeId);
        // the map should contains  (Moving Backward) key.
        System.assertEquals(true, getOppField.containsKey('Moving Backward'));
    }
}