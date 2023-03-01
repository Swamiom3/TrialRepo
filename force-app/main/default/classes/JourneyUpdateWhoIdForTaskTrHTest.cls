/*********************************************************************************************************
	Author        :  Shobhit Gahlot
	Description   :  Test class for JourneyUpdateWhoIdForTaskTrH
	Issue No.     :  ST-8957
	History       :
-----------------------------------------------------------------------------------------------------------
	VERSION        DATE            AUTHOR             DETAIL
	1          09-Sept-2021      Shobhit Gahlot    Trigger Refactor Test
**********************************************************************************************************/
@isTest
public class JourneyUpdateWhoIdForTaskTrHTest {
    @testSetup
    private static void setup() {
        Test.startTest();
        Lead testLead = getInsertedLead();
        TestingUtility.insertWithAssert(testLead);
        Account testAccount = UtilAccount.GetNewAccounts(1, true)[0];
        Contact testContact = UtilContact.GetNewContacts(1, testAccount, true)[0];
        Journey__c testJourney = getInsertedContactJournies(1, testLead)[0];
        TestingUtility.insertWithAssert(testJourney);
        List<Task> testTask = new List<Task>();
        testTask.add(new Task(whatId = testJourney.Id, Subject = 'FastCall Outbound Call', Status = 'Not Started'));
        TestingUtility.insertListWithAssert(testTask); 
        Test.stopTest();
    }
    
    @isTest
    private static void journeyUpdateWhoIdForTaskUpdateTest() { 
        Contact contacts = [SELECT Id FROM Contact LIMIT 1];  
        Journey__c journey = [SELECT Id FROM journey__c WHERE Primary_Lead__r.Email = 'johntest4@example.com' LIMIT 1];
        journey.Primary_Lead__c = null;
        journey.Primary_Contact__c = contacts.Id;
        update journey;
        Task taskRecord = [SELECT Id, WhoId FROM Task WHERE whatId =:journey.Id LIMIT 1];
        System.assert(journey.Primary_Contact__c == taskRecord.WhoId, 'WhoId for task is not mapped correctly');
    }
  
    private static Lead getInsertedLead(){
        return new Lead(LastName = 'test',
                        FirstName = 'john',
                        Email = 'johntest4@example.com',
                        Phone = '1234567891',
                        Company = 'Test Company',
                        LeadSource= 'Broker',
                        Generate_Journey__c = false
                       ); 
    }
    
    private static List<Journey__c> getInsertedContactJournies(Integer size, lead testLead){
        List<Journey__c> testJourney = new List<Journey__c>();
        for(Integer i = 0; i < size ; i++){
            testJourney.add(new Journey__c(
                                           Name = 'Test Journey' + i, 
                                           Primary_Lead__c = testLead.Id,
                                           Primary_Lead__r = testLead,
                                           NMD_Next_Contact_Date__c = Date.today(),
                                           Lead_Source__c = 'WeWork.cn',
                                           LeadSource_Sub_Type__c = 'Chat',
                                           Status__c = 'Known'
                                          ));
        }
        return testJourney;
    }
}