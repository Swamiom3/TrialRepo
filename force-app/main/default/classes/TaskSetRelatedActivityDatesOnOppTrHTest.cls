/************************************************************************************************************************************
    Author       :   Mikolaj Juras    
    @Description :   test for TaskSetRelatedActivityDatesOnOppTrH
    Issue No     :   ST-8334
    History      :
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION     DATE                AUTHOR              ISSUE NO        DETAIL
    1         7 Jun 2021       Mikolaj Juras           ST-8334         Initial Developement               
**************************************************************************************************************************************/
@isTest
public class TaskSetRelatedActivityDatesOnOppTrHTest {

    @isTest
    public static void testHandeler() {
        Task testTask1 = new Task(
            Id = TestUtility.getFakeId(Task.getSObjectType()),
            Subject = 'test task',
            WhatId = TestUtility.getFakeId(Opportunity.getSObjectType())
        );

        Task testTask2 = new Task(
            Id = TestUtility.getFakeId(Task.getSObjectType()),
            Subject = 'test task',
            WhatId = TestUtility.getFakeId(Opportunity.getSObjectType())
        );

        Test.startTest();
        TaskSetRelatedActivityDatesOnOppTrH taskHandler = new TaskSetRelatedActivityDatesOnOppTrH(new List<Task>{testTask1, testTask2}, null);
        System.assertEquals(2, taskHandler.opportunityIds.size(), 'realted opp Ids set size should equal 2');

        taskHandler.afterInsert();
        System.assert(taskHandler.oppRelatedActivitiesManger.oppsIdToUpdate.containsAll(new List<Id>{testTask1.WhatId, testTask2.WhatId}), 
                    'Opportunity Id is passed to OpportunityRelatedActivitiesManager');

        TaskSetRelatedActivityDatesOnOppTrH taskHandler2 = new TaskSetRelatedActivityDatesOnOppTrH(new List<Task>{testTask1, testTask2}, null);
        taskHandler2.afterUpdate();
        System.assert(taskHandler2.oppRelatedActivitiesManger.oppsIdToUpdate.containsAll(new List<Id>{testTask1.WhatId, testTask2.WhatId}),
                    'Opportunity Id is passed to OpportunityRelatedActivitiesManager');
        Test.stopTest();
    }
}