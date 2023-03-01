/*********************************************************************************************************
	Author        :  Shobhit Gahlot
	Description   :  Test class for JourneyWeekendCadenceTrH
	Issue No.     :  ST-8957
	History       :
-----------------------------------------------------------------------------------------------------------
	VERSION        DATE            AUTHOR             DETAIL
	1          09-Sept-2021      Shobhit Gahlot    Trigger Refactor Test
**********************************************************************************************************/
@isTest
public class JourneyWeekendCadenceTrHTest {
    @isTest
    private static void insertJourneyWeekendCadenceUserTest() {  
        Lead testLeads = getInsertedLeads();
        List<Journey__c> testJournies = getInsertedJourneys(testLeads);
        JourneyWeekendCadenceTrH weekCad = new JourneyWeekendCadenceTrH();
        System.assertEquals(weekCad.newJourneys, null, 'List should be null');
        weekCad = new JourneyWeekendCadenceTrH(testJournies, new Map<Id, Journey__c> (testJournies));
        System.assert(!weekCad.newJourneys.isEmpty(), 'List should not be empty');
        weekCad.afterInsert();
        weekCad.weekendCadence();
        for (Journey__c journey : weekCad.journeysToUpdate){
            Date myDate = Date.today();
            Date sunday = myDate.toStartofWeek();
            Date monday = sunday.addDays(1);
            Date saturday = sunday.addDays(-1);
            Date friday = sunday.addDays(-2);
            if(myDate == sunday ||  myDate == saturday || myDate == friday){
                System.assertEquals(monday, journey.NMD_Next_Contact_Date__c, 'Monday following date should be Inserted');
            }
        }
    }
    
    @isTest
    private static void insertJourneyWeekendCadenceGroupTest() {
        Group assignedGroup = [SELECT Id FROM Group WHERE Type = 'Queue' LIMIT 1];
        Lead testLeads = getInsertedLeads();
        QueueSobject mappingObject = new QueueSobject(QueueId = assignedGroup.Id, SobjectType = 'Journey__c');
        System.runAs(new User(Id = UserInfo.getUserId()))
		{insert mappingObject;}
        
        List<Journey__c> testJourniesGroup = getInsertedGroupJournies(testLeads, assignedGroup);
        JourneyWeekendCadenceTrH weekCadGroup = new JourneyWeekendCadenceTrH(testJourniesGroup, new Map<Id, Journey__c> (testJourniesGroup));
        Test.startTest();
        weekCadGroup.afterInsert();
        weekCadGroup.weekendCadence();
        Test.stopTest();
        for (Journey__c journey : weekCadGroup.journeysToUpdate){
            Date myDate = Date.today();
            Date sunday = myDate.toStartofWeek();
            Date monday = sunday.addDays(1);
            Date saturday = sunday.addDays(-1);
            Date friday = sunday.addDays(-2);
            if(myDate == sunday ||  myDate == saturday || myDate == friday){
                System.assertEquals(monday, journey.NMD_Next_Contact_Date__c, 'Monday following date should be Inserted');
            }
        }
    }
    
    @IsTest
    private static void shouldGetNextContactDate(){
        Lead leads = getInsertedLeads();
        List<Journey__c> journeys = getInsertedJourneys(leads);
        TimeZone userTimeZone = UserInfo.getTimeZone();
        String businessHoursZone;
        JourneyWeekendCadenceTrH handlerInstance;
        User journeyOwner;

        Test.startTest();
        handlerInstance = new JourneyWeekendCadenceTrH();
        System.assertNotEquals(journeys[0].OwnerId, null, 'Journey should have an owner');
        journeyOwner = [SELECT Id, Name, TimeZoneSidKey
                        FROM User
                        WHERE Id =:journeys[0].OwnerId
                        LIMIT 1];
        handlerInstance.usersMap.put(journeyOwner.Id, journeyOwner);
        handlerInstance.prepareBusinessHoursMap();
        System.assert(!handlerInstance.businessHoursMap.isEmpty(), 'Business Hours map should not be empty');
        businessHoursZone = handlerInstance.businessHoursMap.values()[0].Name;
        handlerInstance.getNextContactDate(businessHoursZone, userTimeZone, journeys[0], 'User');
        Test.stopTest();

        System.assert(!handlerInstance.journeysToUpdate.isEmpty(), 'Journeys to update should be added');
    }

    @IsTest
    private static void shouldPopulateUsersMap(){
        JourneyWeekendCadenceTrH handlerInstance;
        Id userId = UserInfo.getUserId();

        Test.startTest();
        handlerInstance = new JourneyWeekendCadenceTrH();
        handlerInstance.populateUsersMapForUsersIds(new Set<Id>{ userId });
        Test.stopTest();

        System.assert(!handlerInstance.usersMap.isEmpty(), 'User should be added to map');
    }

    @IsTest
    private static void shouldProceedWithUpdateAndAvoidRecursion(){
        JourneyWeekendCadenceTrH handlerInstance;
        Lead leads = getInsertedLeads();
        List<Journey__c> journeys = getInsertedJourneys(leads);

        Test.startTest();
        handlerInstance = new JourneyWeekendCadenceTrH();
        handlerInstance.journeysToUpdate = journeys;
        handlerInstance.updateJourneysAvoidingRecursion();
        Test.stopTest();

        System.assert(AvoidRecurssion.isExecute, 'Should be in isExecute scope');
    }
    
    private static Lead getInsertedLeads(){
        Lead testLead = UtilLead.getNewLeads(1, false)[0];
        testLead.Generate_Journey__c = false;
        TestingUtility.insertWithAssert(testLead);
        return testLead;
    }
    
    private static List<Journey__c> getInsertedJourneys(Lead testLeads){
        List<Journey__c> journeysToInsert = new List<Journey__c>();
        journeysToInsert.add(new Journey__c(Name = 'journey2', Primary_Lead__c = testLeads.Id, Status__c = 'Known', NMD_Next_Contact_Date__c = Date.today()));
        TestingUtility.insertListWithAssert(journeysToInsert);
        Set<Id> journeysIds = new Map<Id, Journey__c>(journeysToInsert).keySet();
        List<Journey__c> journeys = [SELECT Id, Name, Primary_Lead__c, Status__c, NMD_Next_Contact_Date__c, CreatedDate, OwnerId
                                     FROM Journey__c
                                     WHERE Id IN: journeysIds];
        return journeys;
    }
    private static List<Journey__c> getInsertedGroupJournies(Lead testLeads, Group assignedOwner){
        List<Journey__c> journeysToInsert = new List<Journey__c>();
        journeysToInsert.add(new Journey__c(Name = 'journey3', OwnerId = assignedOwner.Id, Primary_Lead__c = testLeads.Id, Status__c = 'Known', NMD_Next_Contact_Date__c = Date.today()));
        TestingUtility.insertListWithAssert(journeysToInsert);
        Set<Id> journeysIds = new Map<Id, Journey__c>(journeysToInsert).keySet();
        List<Journey__c> journeys = [SELECT Id, Name, Primary_Lead__c, Status__c, NMD_Next_Contact_Date__c, CreatedDate, OwnerId
                                     FROM Journey__c
                                     WHERE Id IN: journeysIds];
        return journeys;
    }
}