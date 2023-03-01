/************************************************************************************************************************************
    Author       :   Mikolaj Juras    
    Description  :   test for OpportunityRelatedActivitiesManager
    Issue No     :   ST-8334
    History      :
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION     DATE                AUTHOR              ISSUE NO        DETAIL
    1           24 May 2021     Mikolaj Juras       ST-8334         Initial Developement 
**************************************************************************************************************************************/
@isTest
public with sharing class OpportunityRelatedActivitiesManagerTest {

    @isTest
    public static void testHandeler() {
        List<Opportunity> opportunitiesToTest = getFakeOpportunitiesWithActivities();
        OpportunityRelatedActivitiesManager activityManager  = new OpportunityRelatedActivitiesManager(new Set<Id>(new List<Id>{opportunitiesToTest[0].Id}));
        activityManager.opportunitiesToUpdate = opportunitiesToTest;
        activityManager.checkActivityOnOpportunities();
        System.assertEquals(System.today().addDays(-15), 
                            opportunitiesToTest[0].First_Activity_Date__c, 
                            'First_Activity_Date__c should be set to today() -15');
        System.assertEquals(System.today().addDays(-1), 
                            opportunitiesToTest[0].Last_Related_Activity_Modified_Date__c, 
                            'Last_Related_Activity_Modified_Date__c should be set to today() -1');
        System.assertEquals(5, 
                            opportunitiesToTest[0].Total_Number_of_Activities__c, 
                            'Total_Number_of_Activities__c should be set to 5');
    }

    private static List<Opportunity> getFakeOpportunitiesWithActivities() {
        Opportunity testOpportunity = new Opportunity(
            Id = TestUtility.getFakeId(Opportunity.getSObjectType())
        );
       
        Task task1 = createTestTask(((Datetime)System.today().addDays(-10)).formatGmt(GlobalConstants.DATE_FORMAT_GMT), ((Datetime)System.today().addDays(-5)).formatGmt(GlobalConstants.DATE_FORMAT_GMT), 'Other', testOpportunity.Id);
        Task task2 = createTestTask(((Datetime)System.today().addDays(-3)).formatGmt(GlobalConstants.DATE_FORMAT_GMT), ((Datetime)System.today().addDays(-2)).formatGmt(GlobalConstants.DATE_FORMAT_GMT), 'Other', testOpportunity.Id);
        Task task3 = createTestTask(((Datetime)System.today().addDays(-15)).formatGmt(GlobalConstants.DATE_FORMAT_GMT), ((Datetime)System.today().addDays(-2)).formatGmt(GlobalConstants.DATE_FORMAT_GMT), 'Other', testOpportunity.Id);

        Event event1 = createTestEvent(((Datetime)System.today().addDays(-5)).formatGmt(GlobalConstants.DATE_FORMAT_GMT), ((Datetime)System.today().addDays(-1)).formatGmt(GlobalConstants.DATE_FORMAT_GMT), testOpportunity.Id);
        Event event2 = createTestEvent(((Datetime)System.today().addDays(-5)).formatGmt(GlobalConstants.DATE_FORMAT_GMT), ((Datetime)System.today().addDays(-2)).formatGmt(GlobalConstants.DATE_FORMAT_GMT), testOpportunity.Id);

        testOpportunity = (Opportunity) JSON.deserialize(
            JSON.serialize(
                SObjectChildRecordsMockWrapper.addChildRecords(
                    testOpportunity,
                    new Map<String, List<SObject>>{
                        'Events' => new List<SObject>{event1, event2},
                        'Tasks' => new List<SObject>{task1, task2, task3}
                    }
                )
            ),
            Opportunity.class
        );

        return new List<Opportunity>{testOpportunity};
    }

    //TODO create tech debt ticket for generic function to add CreatedDate/LastModifiedDate for SObject
    private static Task createTestTask (String createdDateTime, String lastModifiedDateTime, String type, String opportunityId) {
        return (Task) JSON.deserialize(
            '{"createdDate" : "' + createdDateTime 
            +'","lastModifiedDate" : "' + lastModifiedDateTime 
            +'","Id":"' + TestUtility.getFakeId(Task.getSObjectType()) 
            + '", "Type":"' + type
            +'","WhatId":"'+ opportunityId + '"}',Task.class);
    }

    private static Event createTestEvent (String createdDateTime, String lastModifiedDateTime, String opportunityId) {
        return (Event) JSON.deserialize(
            '{"createdDate" : "' + createdDateTime 
            +'","lastModifiedDate" : "' + lastModifiedDateTime 
            +'","Id":"' + TestUtility.getFakeId(Event.getSObjectType()) 
            +'","WhatId":"'+ opportunityId + '"}',Event.class);
    }
}