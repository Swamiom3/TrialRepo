/*********************************************************************************************************
	Author        :  Shobhit Gahlot
	Description   :  Test class for JourneyManageContactAndLeadTrH
	Issue No.     :  ST-8957
	History       :
-----------------------------------------------------------------------------------------------------------
	VERSION        DATE            AUTHOR             DETAIL
	1          09-Sept-2021      Shobhit Gahlot    Trigger Refactor
**********************************************************************************************************/
@isTest
public class JourneyManageContactAndLeadTrHTest {
    @isTest
    private static void journeyManageLeadTest() {  
        User assignedUser = [SELECT Id, Name, Email FROM User LIMIT 1];
        List<Lead> testLeads = getInsertedLeads(1, assignedUser);
        List<Journey__c> testJourneyLead = getInsertedJournies(testLeads[0]);
		
        JourneyManageContactAndLeadTrH manageContactLead = new JourneyManageContactAndLeadTrH(testJourneyLead, null);
        Map<Id, Journey__c> oldJournysMap = new Map<Id, Journey__c>(testJourneyLead.deepClone(true));
        testJourneyLead[0].Status__c = 'MQL';
        manageContactLead = new JourneyManageContactAndLeadTrH(testJourneyLead, oldJournysMap);
        manageContactLead.registerDmlConsolidator(DmlConsolidatorDefault.getInstance());
        manageContactLead.setTriggerContext('after update', true);
        Test.startTest();
        manageContactLead.afterUpdate();
        Test.stopTest();
        verifyAssertLead(manageContactLead);
    }
 
    @isTest
    private static void journeyManageContactTest() {
        User assignedUser = [SELECT Id, Name, Email FROM User LIMIT 1];
        List<Account> assignAccount = getInsertedAccount(1);

        List<Contact> testContacts = getInsertedContacts(1, assignAccount[0]);
        List<Journey__c> testJournies = getInsertedContactJournies(1, testContacts, assignedUser);
        
        JourneyManageContactAndLeadTrH manageContactLead = new JourneyManageContactAndLeadTrH(testJournies, null);
        Map<Id, Journey__c> oldJournysMap = new Map<Id, Journey__c>(testJournies.deepClone(true));
        testJournies[0].Status__c = 'MQL';
        manageContactLead = new JourneyManageContactAndLeadTrH(testJournies, oldJournysMap);
        manageContactLead.registerDmlConsolidator(DmlConsolidatorDefault.getInstance());
        manageContactLead.setTriggerContext('after insert', true);

        Test.startTest();
        manageContactLead.afterInsert();
        Test.stopTest();
        verifyAssertContact(manageContactLead);
    } 

    private static void verifyAssertLead(JourneyManageContactAndLeadTrH manageContactLead) {
        System.assertNotEquals(System.today(), manageContactLead.leadToUpdate.values().Journey_Created_On__c);
        System.assertEquals(System.today(), manageContactLead.leadToUpdate.values().MQL_Identified_On__c);
    }
    private static void verifyAssertContact(JourneyManageContactAndLeadTrH manageContactLead) {
        System.assertEquals(System.today(), manageContactLead.contactToUpdate.values().Journey_Created_On__c);
        System.assertEquals(System.today(), manageContactLead.contactToUpdate.values().MQL_Identified_On__c);
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
                                       Generate_Journey__c = false,
                                       Journey_Created_On__c = Date.today().addDays(-1),
                                       MQL_Identified_On__c = Date.today().addDays(1)
                                      ));
        }
        return testLeads;
    }
    
    private static List<Contact> getInsertedContacts (Integer size, Account assignedAccount){
        List<Contact> testContacts = new List<Contact>();
        for(Integer i = 0 ; i < size ; i++){
                testContacts.add(new Contact(Id = TestUtility.getFakeId(Contact.SObjectType),
                                             FirstName = 'Test',
                                             LastName = 'test' + i,
                                             Email = 'wetestwork' + i + '@' + i + 'example.com',
                                             Account = assignedAccount,
                                             MQL_Identified_On__c = Date.newInstance(2021, 2, 17),
                                             Journey_Created_On__c = Date.newInstance(2021, 2, 20)
                                            ));
        }
        return testContacts;
    }
    
    private static List<Account> getInsertedAccount (Integer size){
        List<Account> testAccounts = new List<Account>();
        for(Integer i = 0 ; i < size ; i++){
                testAccounts.add(new Account(Id = TestUtility.getFakeId(Account.SObjectType),
                                             Name='test acc',
                                             Phone='9494146144', 
                                             Number_of_Full_Time_Employees__c = 10
                                            ));
        }
        return testAccounts;
    }
    
    private static List<Journey__c> getInsertedJournies(Lead testLeads){
        List<Journey__c> journeysToInsert = new List<Journey__c>();
            journeysToInsert.add(new Journey__c(Id = TestUtility.getFakeId(Journey__c.SObjectType),
                                                Name = 'journey2', 
                                                Primary_Lead__c = testLeads.Id, 
                                                Status__c = 'Known', 
                                                NMD_Next_Contact_Date__c = Date.today()
                                               )); 
        return journeysToInsert;
    }
    
    private static List<Journey__c> getInsertedContactJournies(Integer size, List<Contact> testContacts, User assignedUser){
        List<Journey__c> testJourney = new List<Journey__c>();
        for(Integer i = 0; i < size ; i++){
            testJourney.add(new Journey__c(Id = TestUtility.getFakeId(Journey__c.SObjectType),
                                           Name = 'Test Journey' + i, 
                                           OwnerId = assignedUser.Id,
                                           Primary_Contact__c = testContacts[i].Id,
                                           Primary_Contact__r = testContacts[i],
                                           NMD_Next_Contact_Date__c = Date.today(),
                                           Lead_Source__c = 'WeWork.cn',
                                           LeadSource_Sub_Type__c = 'Chat',
                                           Status__c = 'Known'
                                          ));
        }
        return testJourney;
    }
}