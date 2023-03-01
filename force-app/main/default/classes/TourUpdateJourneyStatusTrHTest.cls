/*********************************************************************************************************
	Author        :  Ishwar Shinde
	Description   :  Test class for TourUpdateJourneyStatusTrH
	Issue No.     :  TWSPG-10524
	History       :
-----------------------------------------------------------------------------------------------------------
	VERSION        DATE            AUTHOR             DETAIL
	1          02-May-20221      Ishwar Shinde    Initial Developemen
**********************************************************************************************************/
@isTest
public class TourUpdateJourneyStatusTrHTest {
    @TestSetup
    static void initData(){
        Lead testLead = getInsertedLead();
        TestingUtility.insertWithAssert(testLead);
        Account account = new Account(name='test acc',phone='9494146144', Number_of_Full_Time_Employees__c = 10);
        insert account;
        Account assignAccount = [SELECT Id, Name FROM Account LIMIT 1];
        List<Contact> testContacts = getInsertedContacts(1, assignAccount);
        Journey__c testJourney = getInsertedContactJourneys(1, testContacts[0])[0];
        TestingUtility.insertWithAssert(testJourney);
        
    	List<SObject> tourRecords = TestingUtility.getRecords(new Map<String, Object>{'objName' => 'Tour', 'numberOfRecords' => 1, 'doInsert' => false});
		
        List<Opportunity> opportunitiesToInsert = new List<Opportunity>();
        List<ServiceAppointment> toursToInsert = new List<ServiceAppointment>();
        for (SObject singleRecord : tourRecords) {
            if (String.valueOf(singleRecord.getSObjectType()).toLowerCase() == 'opportunity') {
                opportunitiesToInsert.add((Opportunity)singleRecord);
            } else {
                toursToInsert.add((ServiceAppointment)singleRecord);
            }
        }
        
        toursToInsert[0].Journey_Id__c = [SELECT Id FROM Journey__c][0].Id;
        toursToInsert[0].ParentRecordId = testLead.Id;
        insert toursToInsert;
    }
    
    @isTest
    public static void updateJourneyStageAfterInsert(){
        Test.startTest();
        String status = [SELECT Status__c FROM Journey__c][0].Status__c;
        Test.stopTest();
        System.assertEquals('Converted', status, 'Journey Status should be update as Converted');
        System.assertNotEquals('Known', status, 'Journey Status should not be Known');
    }
    
    @isTest
    public static void updateJourneyStageAfterUpdate(){
        Test.startTest();
        ServiceAppointment data = [SELECT Id, Journey_Id__c FROM ServiceAppointment][0];  
        data.Status = 'No Show';
        update data;
        Test.stopTest();
        String status = [SELECT Status__c FROM Journey__c][0].Status__c;
        System.assertEquals('Converted', status, 'Journey Status should be update as Converted');
        System.assertNotEquals('Known', status, 'Journey Status should not be Known');
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
    
    private static List<Journey__c> getInsertedContactJourneys(Integer size, Contact contact){
        List<Journey__c> testJourney = new List<Journey__c>();
        for(Integer i = 0; i < size ; i++){
            testJourney.add(new Journey__c(
                                           Name = 'Test Journey' + i, 
                                           Primary_Contact__c = contact.Id,
                                           NMD_Next_Contact_Date__c = Date.today(),
                                           Lead_Source__c = 'WeWork.cn',
                                           LeadSource_Sub_Type__c = 'Chat',
                                           Status__c = 'Known'
                                          ));
        }
        return testJourney;
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
}