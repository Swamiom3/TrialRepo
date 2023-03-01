/*********************************************************************************************************
	Author        :  Ishwar Shinde
	Description   :  Test class for JourneyStatusUpdateOwnerChangeTrH
	Issue No.     :  TWSPG-12475
	History       :
-----------------------------------------------------------------------------------------------------------
	VERSION        DATE            AUTHOR             DETAIL
	1          15-June-2022      Ishwar Shinde     Initial Developement
**********************************************************************************************************/
@isTest
public class JourneyStatusUpdateOwnerChangeTrHTest {
    @isTest
    public static void statusUpdateOwnerChangePositiveTest(){
        User assignedUser = [SELECT Id, Name, Email FROM User LIMIT 1];
        Group assignedGroup = [SELECT Id FROM Group WHERE Type = 'Queue' LIMIT 1];
        List<Lead> testLeads = getInsertedLeads(1, assignedUser);
        QueueSobject mappingObject = new QueueSobject(QueueId = assignedGroup.Id, SobjectType = 'Journey__c');
        System.runAs(new User(Id = UserInfo.getUserId()))
		{insert mappingObject;}
        List<Journey__c> testJournies = getInsertedUserJournies(1, testLeads, assignedUser);
        List<Journey__c> testJourniesGroup = getInsertedGroupJournies(testLeads[0], assignedGroup);
        JourneyStatusUpdateOwnerChangeTrH handlePositive = new JourneyStatusUpdateOwnerChangeTrH(testJourniesGroup, null);
        Map<Id, Journey__c> oldJourniesMap = new Map<Id, Journey__c>(testJourniesGroup.deepClone(true));
        testJourniesGroup[0].OwnerId = testJournies[0].OwnerId;
        handlePositive = new JourneyStatusUpdateOwnerChangeTrH(testJourniesGroup, oldJourniesMap);
        
        Test.startTest();
        handlePositive.beforeUpdate();
        System.assertEquals('Accepted', JourneyStatusUpdateOwnerChangeTrH.STATUS_FOR_TEST, 'Status should updated on Journey');
        Test.stopTest();
    }
    
    @isTest
    public static void statusUpdateOwnerChangeNegativeTest(){
        User assignedUser = [SELECT Id, Name, Email FROM User LIMIT 1];
        Group assignedGroup = [SELECT Id FROM Group WHERE Type = 'Queue' LIMIT 1];
        List<Lead> testLeads = getInsertedLeads(1, assignedUser);
        QueueSobject mappingObject = new QueueSobject(QueueId = assignedGroup.Id, SobjectType = 'Journey__c');
        System.runAs(new User(Id = UserInfo.getUserId()))
		{insert mappingObject;}
        List<Journey__c> testJournies = getInsertedUserJournies(1, testLeads, assignedUser);
        List<Journey__c> testJourniesGroup = getInsertedGroupJournies(testLeads[0], assignedGroup);
        
        JourneyStatusUpdateOwnerChangeTrH handleNegative = new JourneyStatusUpdateOwnerChangeTrH(testJournies, null);
        Map<Id, Journey__c> oldJourniesMapTwo = new Map<Id, Journey__c>(testJournies.deepClone(true));
        testJournies[0].OwnerId = testJourniesGroup[0].OwnerId;
        handleNegative = new JourneyStatusUpdateOwnerChangeTrH(testJournies, oldJourniesMapTwo);
        
        Test.startTest();
        handleNegative.beforeUpdate();
        System.assertNotEquals('Accepted', JourneyStatusUpdateOwnerChangeTrH.STATUS_FOR_TEST, 'Status should updated on Journey');
        Test.stopTest();
    }
    private static List<Lead> getInsertedLeads (Integer size, User assignedUser){
        List<Lead> testLeads = new List<Lead>();
        for(Integer i = 0 ; i < size ; i++){
                testLeads.add(new Lead(
                                       Id = TestUtility.getFakeId(Lead.SObjectType),
                                       OwnerId = assignedUser.Id,
                                       LastName = 'Test ' + i,
                                       Email = 'Test'+ i + '@test.com',
                                       Status = 'Known',
                                       Company = 'Test Pvt Ltd',
                                       Phone = '(777) 648-222' + i,
                                       LeadSource = 'Other',
                                       Generate_Journey__c = true
                                      ));
        }
        return testLeads;
    }
    private static List<Journey__c> getInsertedUserJournies(Integer size, List<Lead> testLeads, User assignedUser){
        List<Journey__c> testUserJourney = new List<Journey__c>();
        for(Integer i = 0; i < size ; i++){
            testUserJourney.add(new Journey__c(Id = TestUtility.getFakeId(Journey__c.SObjectType),
                                               Name = 'Test Journey' + i, 
                                               OwnerId = assignedUser.Id,
                                               Primary_Lead__c = testLeads[i].Id,
                                               Primary_Lead__r = testLeads[i],
                                               NMD_Next_Contact_Date__c = Date.today(),
                                               Lead_Source__c = 'WeWork.cn',
                                               LeadSource_Sub_Type__c = 'Chat',
                                               Status__c = 'Known'
                                              ));
        }
        return testUserJourney;
    }
    private static List<Journey__c> getInsertedGroupJournies(Lead testLeads, Group assignedOwner){
        List<Journey__c> testGroupJourney = new List<Journey__c>();
            testGroupJourney.add(new Journey__c(Id = TestUtility.getFakeId(Journey__c.SObjectType), 
                                                Name = 'journey3', 
                                                OwnerId = assignedOwner.Id, 
                                                Primary_Lead__c = testLeads.Id, 
                                                Status__c = 'Known', 
                                                NMD_Next_Contact_Date__c = Date.today()
                                               ));
        return testGroupJourney;
    }
}