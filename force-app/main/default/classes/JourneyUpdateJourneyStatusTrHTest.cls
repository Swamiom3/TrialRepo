/*********************************************************************************************************
	Author        :  Shobhit Gahlot
	Description   :  Test class for JourneyUpdateJourneyStatusTrH
	Issue No.     :  ST-8957
	History       :
-----------------------------------------------------------------------------------------------------------
	VERSION        DATE            AUTHOR             DETAIL
	1          09-Sept-2021      Shobhit Gahlot    Trigger Refactor
**********************************************************************************************************/
@isTest
public class JourneyUpdateJourneyStatusTrHTest {
    @isTest
    public static void updateJourneyStatusTrHTest() {
        List<Journey__c> testJourneys = getJourney(6);
        List<Journey__c> mockedjourneys = new List<Journey__c> {
                new Journey__c(Id = testJourneys[0].Id,Status__c = 'Known', Count_of_Activities__c = 1),
                new Journey__c(Id = testJourneys[1].Id,Status__c = 'Accepted',Count_of_Activities__c = 1),
                new Journey__c(Id = testJourneys[2].Id,Status__c = 'Deferred',Count_of_Activities__c = 1),
                new Journey__c(Id = testJourneys[3].Id,Status__c = 'Known',Count_of_Activities__c = 0),
                new Journey__c(Id = testJourneys[4].Id,Status__c = 'Accepted',Count_of_Activities__c = 0)
        };
        Test.startTest();
        JourneyUpdateJourneyStatusTrH updateJourneyStatus = new JourneyUpdateJourneyStatusTrH();
        updateJourneyStatus.newJourneys = mockedjourneys;
        updateJourneyStatus.beforeUpdate();
        Test.stopTest();
        System.assertEquals('Working', mockedjourneys[0].Status__c, 'status should be updated');
        System.assertEquals('Working', mockedjourneys[1].Status__c, 'status should  be updated');
        System.assertNotEquals('Working', mockedjourneys[2].Status__c, 'status should not be updated');
        System.assertNotEquals('Working', mockedjourneys[3].Status__c, 'status should not be updated');
        System.assertNotEquals('Working', mockedjourneys[4].Status__c, 'status should not be updated');
    }
    private static List<Journey__c> getJourney(Integer size){
        List<Journey__c> testJourney = new List<Journey__c>();
        for(Integer i=0; i<size;i++){
            testJourney.add(new Journey__c(
                Id = TestUtility.getFakeId(Journey__c.getSObjectType()),
                Name = 'journey' +i
            ));
        }
        return testJourney;
    }
}