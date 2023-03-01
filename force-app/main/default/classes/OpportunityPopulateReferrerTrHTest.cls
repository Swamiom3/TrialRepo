@isTest
public class OpportunityPopulateReferrerTrHTest {
    @TestSetup
    static void makeData(){
        User assignedUser = [SELECT Id, Name, Email FROM User LIMIT 1];
        Account account = new Account(name='test acc', phone='9494146144', Number_of_Full_Time_Employees__c = 10);
        insert account;
        Account assignAccount = [SELECT Id, Name FROM Account LIMIT 1];
        List<Contact> testContacts = getInsertedContacts(1, assignAccount);
        List<Journey__c> testJournies = getInsertedJournies(1, testContacts[0]);
    }
    
    @isTest
    private static void testInsertOpportunityReferrer(){
        Contact testContacts = [SELECT Id, Email,LastName FROM Contact];
        List<Journey__c> testJourniesWithContact = [Select Id, Referrer__c FROM Journey__c];
        Test.startTest();
        List<Opportunity> testOpportunities = getInertedOpportunities(1, testContacts, testJourniesWithContact);
        TestingUtility.insertListWithAssert(testOpportunities);
        Test.stopTest();
        List<Journey__c> testJournies = [SELECT Id,  Referrer__c, Primary_Contact__c, Primary_Email__c FROM Journey__c];
        List<Opportunity> testOppo = [SELECT Id, Referrer__c FROM Opportunity];
        System.assertEquals(testJournies[0].Referrer__c, testOppo[0].Referrer__c);
    }
    
    private static List<Contact> getInsertedContacts (Integer size, Account assignedAccount){
        List<Contact> testContacts = new List<Contact>();
        for(Integer i = 0 ; i < size ; i++){
            testContacts.add(new Contact(FirstName = 'name' + i,
                                         LastName = 'test' + i,
                                         Email = 'wetestwork' + i + '@' + i + 'example.com',
                                         Account = assignedAccount,
                                         Contact_Lead_Status__c = 'Engaged'
                                        ));
        }
        TestingUtility.insertListWithAssert(testContacts);
        return testContacts;
    }
    private static List<Opportunity> getInertedOpportunities (Integer size, Contact assignedContact, List<Journey__c> assignedJourney){
        List<Opportunity> testOpportunities = new LIst<Opportunity>();
        for(Integer i = 0 ; i < size ; i++){
            testOpportunities.add(new Opportunity(Name = 'test' +i, 
                                                  Primary_Member__c = assignedContact.Id, 
                                                  StageName = 'Qualifying', 
                                                  CloseDate = system.today()+3,
                                                  Journey__c = assignedJourney[i].Id, 
                                                  Opportunity_Creation_Source__c = 'From Add Opportunity'));
        }
        return testOpportunities;
    }
    
    private static List<Journey__c> getInsertedJournies(Integer size, Contact assignedcontacts){
        List<Journey__c> testJournies = new List<Journey__c>();
        for(Integer i = 0; i < size ; i++){
            testJournies.add(new Journey__c(Name = 'Test Journey' + i, 
                							Primary_Contact__c = assignedcontacts.Id,
                							Primary_Contact__r = assignedcontacts,
                							NMD_Next_Contact_Date__c = Date.today(),
                							Lead_Source__c = 'Referral',
                							LeadSource_Sub_Type__c = 'Broker Referral',
                							Status__c = 'Known', 
                							Referrer__c = assignedcontacts.Id, 
                							Creation_Source__c = 'Inbound Lead'
            ));
        }
        TestingUtility.insertListWithAssert(testJournies);
        return testJournies;
    }
}