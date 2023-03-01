/************************************************************************************************************************************
Author         :     Oleksandr Liesnik
Description    :     Test Class for OppWonEventPublishTrH
----------------------------------------------------------------------------------------------------------------------------------
VERSION        DATE                AUTHOR                    DETAIL
1              25 Nov 2021         Oleksandr Liesnik         Initial Development
**************************************************************************************************************************************/
@isTest
public with sharing class OppWonEventPublishTrHTest {

    private static final String DUMMY_ACC_ID = TestUtility.getFakeId(Account.sObjectType); //NOPMD
    private static final String DUMMY_OPP_ID = TestUtility.getFakeId(Opportunity.sObjectType); //NOPMD

    @isTest
    // Test that event will be triggered on closed won opportunity
    public static void checkIfEventTriggers() {
        // Given opportunity
        Opportunity oldOpp = TestingUtility.createOpportunity(DUMMY_ACC_ID, false); 
        oldOpp.Id = DUMMY_OPP_ID;
        oldOpp.StageName = 'Selling';
        Opportunity newOpp = oldOpp.clone(); 
        newOpp.Id = DUMMY_OPP_ID;
        newOpp.StageName = GlobalConstants.OPP_CLOSED_WON_STAGE_NAME;
        Test.startTest();
        // WHEN Opportunity is closed won
        OppWonEventPublishTrH handler = new OppWonEventPublishTrH(
            new Map<Id, Opportunity>{ DUMMY_OPP_ID => newOpp }, 
            new Map<Id, Opportunity>{ DUMMY_OPP_ID => oldOpp } 
        ); 
        handler.afterUpdate();

        Test.getEventBus().deliver();
        Test.stopTest();
        // THEN
        System.assertEquals(1, OppWonEventPublishTrH.closedWonEventsPublished, 'Expected one event');
    }
}