/*********************************************************************************************************
	Author        :  Vipul Chaudahari
	Description   :  Test class for JourneyUpdateActiveReferrerTrH
	Issue No.     :  ST-8958
-----------------------------------------------------------------------------------------------------------
	VERSION        DATE             AUTHOR             DETAIL
	1          09-Sept-2021     Vipul Chaudhari     Trigger Refactor
**********************************************************************************************************/
@isTest
private class JourneyUpdateActiveReferrerTrHTest {
	@TestSetup
    static void makeData(){
        User assignedUser = [SELECT Id, Name, Email FROM User LIMIT 1];
        Account account = new Account(name='test acc', phone='9494146144', Number_of_Full_Time_Employees__c = 10);
        insert account;
        Account assignAccount = [SELECT Id, Name FROM Account LIMIT 1];
        List<Contact> testContacts = getInsertedContacts(1, assignAccount);
        List<Referral__c> testReferrals = getInsertedReferrals(1, assignedUser, testContacts);
        List<Lead> testLeads = getInsertedLeads(1, assignedUser);
    }

    @isTest
    private static void insertJourneyActiveReferrerForContact() {
        Test.startTest();
        User assignedUser = [SELECT Id, Name, Email FROM User LIMIT 1];
        List<Contact> testContacts = [SELECT Id, Email,LastName FROM Contact]; 
        List<Journey__c> testJourniesWithContact = getInsertedContactJournies(1, testContacts, assignedUser);
        ReferenceHandler.clearAlreadyQueriedEmailsForTest();
        TestingUtility.insertListWithAssert(testJourniesWithContact);
        Test.stopTest();
	    List<Journey__c> testJournies = [SELECT Id,  Referrer__c, Primary_Contact__c, Primary_Email__c FROM Journey__c];
        List<Referral__c> testReferral = [SELECT Id, Referral_Email__c, Referrer__c FROM Referral__c];
        System.assertEquals(testJournies[0].Referrer__c, testReferral[0].Referrer__c);
    }
    
    @isTest
    private static void insertJourneyReferrerForLead() {
        Test.startTest();
        User assignedUser = [SELECT Id, Name, Email FROM User LIMIT 1];
        List<lead> testLeads = [SELECT Id, Email, LastName, Company, Status, LeadSource, Phone FROM Lead]; 
        List<Journey__c> testJourniesWithLead = getInsertedLeadJournies(1, testLeads, assignedUser);
        ReferenceHandler.clearAlreadyQueriedEmailsForTest();
        TestingUtility.insertListWithAssert(testJourniesWithLead);
        Test.stopTest();
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
                                       Generate_Journey__c = false
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
                    Contact_Lead_Status__c = 'Engaged'
                ));
        }
        TestingUtility.insertListWithAssert(testContacts);
        return testContacts;
    }

    private static List<Journey__c> getInsertedLeadJournies(Integer size, List<Lead> testLeads, User assignedUser){
        List<Journey__c> testJourney = new List<Journey__c>();
        for(Integer i = 0; i < size ; i++){
            testJourney.add(new Journey__c(Name = 'Test Journey' + i,
                                           OwnerId = assignedUser.Id,
                                           Primary_Lead__c = testLeads[i].Id,
                                           Primary_Lead__r = testLeads[i],
                                           NMD_Next_Contact_Date__c = Date.today()
                                          ));
        }
        return testJourney;
    }

    private static List<Journey__c> getInsertedContactJournies(Integer size, List<Contact> testContacts, User assignedUser){
        List<Journey__c> testJourney = new List<Journey__c>();
        for(Integer i = 0; i < size ; i++){
            testJourney.add(new Journey__c(Name = testContacts[i].LastName,
                                           OwnerId = assignedUser.Id,
                                           Primary_Contact__c = testContacts[i].Id,
                                           Primary_Contact__r = testContacts[i],
                						   Primary_Email__c = testContacts[i].Email,
                                           NMD_Next_Contact_Date__c = Date.today(),
                                           Lead_Source__c = 'WeWork.cn',
                                           LeadSource_Sub_Type__c = 'Chat',
                                           Status__c = 'Known'
                                          ));
        }
        return testJourney;
    }

    private static List<Referral__c> getInsertedReferrals (Integer size, User assignedUser, List<Contact> testContacts){
        List<Referral__c> testReferrals = new List<Referral__c>();
        for(Integer i = 0 ; i < size ; i++){
            testReferrals.add(new Referral__c (OwnerId = assignedUser.Id,
                                               Referral_Email__c = 'wetestwork' + i + '@' + i + 'example.com',
                                               Name = 'test' + i,
                							   Referrer__c = testContacts[i].Id
            ));
        }
        TestingUtility.insertListWithAssert(testReferrals);
        return testReferrals;
    }
}