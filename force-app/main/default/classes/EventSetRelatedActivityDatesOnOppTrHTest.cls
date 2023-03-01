/************************************************************************************************************************************
    Author       :   Mikolaj Juras    
    @Description :   test for EventSetRelatedActivityDatesOnOppTrH
    Issue No     :   ST-8334
    History      :
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION     DATE                AUTHOR              ISSUE NO        DETAIL
    1         7 Jun 2021       Mikolaj Juras           ST-8334         Initial Developement               
**************************************************************************************************************************************/
@isTest
public class EventSetRelatedActivityDatesOnOppTrHTest {

    @isTest
    public static void testHandler() {
        Event testEvent1 = new Event(
            Id = TestUtility.getFakeId(Event.getSObjectType()),
            WhatId = TestUtility.getFakeId(Opportunity.getSObjectType())
        );

        Event testEvent2 = new Event(
            Id = TestUtility.getFakeId(Event.getSObjectType()),
            WhatId = TestUtility.getFakeId(Account.getSObjectType())
        );

        Test.startTest();
        EventSetRelatedActivityDatesOnOppTrH eventHandler = new EventSetRelatedActivityDatesOnOppTrH(new List<Event>{testEvent1, testEvent2}, null);
        System.assertEquals(1, eventHandler.opportunityIds.size(), 'realted opp Ids set size should equal 1');

        eventHandler.afterInsert();
        System.assert(eventHandler.oppRelatedActivitiesManger.oppsIdToUpdate.contains(testEvent1.WhatId), 
        'Opportunity Id is passed to OpportunityRelatedActivitiesManager');

        EventSetRelatedActivityDatesOnOppTrH eventHandler2 = new EventSetRelatedActivityDatesOnOppTrH(new List<Event>{testEvent1, testEvent2}, null);
        eventHandler2.afterUpdate();
        System.assert(eventHandler2.oppRelatedActivitiesManger.oppsIdToUpdate.contains(testEvent1.WhatId), 
        'Opportunity Id is passed to OpportunityRelatedActivitiesManager');
        Test.stopTest();
    }
}