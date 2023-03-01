/*********************************************************************************************************
	Author        :  Shobhit Gahlot
	Description   :  Test class for JourneyChangeRelatedLeadStatusTrH
	Issue No.     :  ST-8957
	History       :
-----------------------------------------------------------------------------------------------------------
	VERSION        DATE            AUTHOR             DETAIL
	1          09-Sept-2021      Shobhit Gahlot    Trigger Refactor Test 
**********************************************************************************************************/
@isTest
public class JourneyChangeRelatedLeadStatusTrHTest {
    @testSetup
    static void initData() {
        Profile standardProfile = [SELECT Id FROM Profile WHERE Name='WeWork System Administrator' LIMIT 1];
        User assignedUser = new User(Alias = 'old', Email='oldUser@testorg.com',
        EmailEncodingKey='UTF-8', LastName='OldUser', LanguageLocaleKey='en_US',
        LocaleSidKey='en_US', ProfileId = standardProfile.Id,
        TimeZoneSidKey='America/Los_Angeles', UserName = 'OldUser@testweworkuser.com');
        insert assignedUser;
        Account a = new Account(name='test acc',phone='9494146144', Number_of_Full_Time_Employees__c = 10);
        insert a;
        Account assignAccount = [SELECT Id, Name FROM Account LIMIT 1];
        List<Lead> testLeads = getInsertedLeads(1, assignedUser);
        List<Contact> testContacts = getInsertedContacts(1, assignAccount);
        List<Journey__c> testJourniesWithLead = getInsertedLeadJournies(6, testLeads, assignedUser);
        List<Journey__c> testJourniesWithcontact = getInsertedContactJournies(6, testContacts, assignedUser);
    }
    @isTest
    public static void journeyChangeRelatedLeadStatusTest(){
        List<Journey__c> testJournies = [SELECT Id,  Status__c FROM Journey__c WHERE Primary_Lead__c != null LIMIT 6];
        testJournies[0].Status__c = 'MQL';
        testJournies[1].Status__c = 'Working';
        testJournies[2].Status__c = 'Converted';
        testJournies[3].Status__c = 'Known';
        testJournies[4].Status__c = 'Accepted';
        testJournies[5].Status__c = 'Engaged';
        Test.startTest();
        update testJournies;
        Test.stopTest();
        verifyAssertLead();
    }
    private static void verifyAssertLead() {
        List<Lead> leadRecords = [SELECT Id, Status FROM Lead LIMIT 1];
        System.assertEquals('Converted', leadRecords[0].Status); 
    }
    @isTest
    public static void journeyChangeRelatedContactStatusTest(){
        List<Journey__c> testJournies = [SELECT Id,  Status__c FROM Journey__c WHERE Primary_Contact__c != null LIMIT 6];
        testJournies[0].Status__c = 'MQL';
        testJournies[1].Status__c = 'Working';
        testJournies[2].Status__c = 'Engaged';
        testJournies[3].Status__c = 'Accepted';
        testJournies[4].Status__c = 'Converted';
        testJournies[5].Status__c = 'Known';
        Test.startTest();
        update testJournies;
        Test.stopTest();
        verifyAssertContact();
    }
    private static void verifyAssertContact() {
        List<Contact> contactRecords = [SELECT Id, Contact_Lead_Status__c FROM Contact LIMIT 1];
        System.assertEquals('Converted', contactRecords[0].Contact_Lead_Status__c);
    }
    private static List<Lead> getInsertedLeads (Integer size, User assignedUser){
        List<Lead> testLeads = new List<Lead>();
        for(Integer i = 0 ; i < size ; i++){
                testLeads.add(new Lead(
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
        TestingUtility.insertListWithAssert(testLeads);
        return testLeads;
    }
    private static List<Contact> getInsertedContacts (Integer size, Account assignedAccount){
        List<Contact> testContacts = new List<Contact>();
        for(Integer i = 0 ; i < size ; i++){
                testContacts.add(new Contact(
                    FirstName = 'First Name Test',
                    LastName = 'test' + i,
                    Email = 'wetestwork' + i + '@' + i + 'example.com',
                    Account = assignedAccount,
                    Contact_Lead_Status__c = 'Known'
                ));
        }
        TestingUtility.insertListWithAssert(testContacts);
        return testContacts;
    }
    private static List<Journey__c> getInsertedLeadJournies(Integer size, List<Lead> testLeads, User assignedUser){
        List<Journey__c> testJourney = new List<Journey__c>();
        for(Integer i = 0; i < size ; i++){
            testJourney.add(new Journey__c(
                                           Name = 'Test Journey' + i, 
                                           OwnerId = assignedUser.Id,
                                           Primary_Lead__c = testLeads[0].Id,
                                           Primary_Lead__r = testLeads[0],
                                           NMD_Next_Contact_Date__c = Date.today(),
                                           Lead_Source__c = 'WeWork.cn',
                                           LeadSource_Sub_Type__c = 'Chat',
                                           Status__c = ''
                                          ));
        }
        TestingUtility.insertListWithAssert(testJourney);
        return testJourney;
    }
    private static List<Journey__c> getInsertedContactJournies(Integer size, List<Contact> testContacts, User assignedUser){
        List<Journey__c> testJourney = new List<Journey__c>();
        for(Integer i = 0; i < size ; i++){
            testJourney.add(new Journey__c(
                                           Name = 'Test Journey' + i, 
                                           OwnerId = assignedUser.Id,
                                           Primary_Contact__c = testContacts[0].Id,
                                           Primary_Contact__r = testContacts[0],
                                           NMD_Next_Contact_Date__c = Date.today(),
                                           Lead_Source__c = 'WeWork.cn',
                                           LeadSource_Sub_Type__c = 'Chat',
                                           Status__c = 'Known'
                                          ));
        }
        TestingUtility.insertListWithAssert(testJourney);
        return testJourney;
    }
}