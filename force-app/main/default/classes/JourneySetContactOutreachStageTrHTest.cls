/*********************************************************************************************************
	Author        :  Vipul Chaudahari
	Description   :  Test class for JourneySetContactOutreachStageTrH
	Issue No.     :  ST-8958
-----------------------------------------------------------------------------------------------------------
	VERSION        DATE             AUTHOR             DETAIL
	1          09-Sept-2021     Vipul Chaudhari     Trigger Refactor
**********************************************************************************************************/
@isTest
public class JourneySetContactOutreachStageTrHTest {
    @testSetup
    public static void setup() {
        List<Account> accounts = UtilAccount.GetNewAccounts(1, true);
        List<Contact> contacts = UtilContact.GetNewContacts(3, accounts[0], true);
    }
    
    @isTest
    public static void contactOutreachStageInsertTest() {
        JourneySetContactOutreachStageTrH setContactOutreachStage = new JourneySetContactOutreachStageTrH();
        List<Contact> contacts =[SELECT Id FROM Contact];
        List<Journey__c> testJourneys = getInsertedJourney(3,contacts);
        insert testJourneys;
        Map<Id,Contact> contact = new Map<Id,Contact>([SELECT Id,Outreach_Stage__c FROM Contact]);
        for(Journey__c journeyRecord : testJourneys){
            if(journeyRecord.Outreach_Stage__c == 'call 1'){
                System.assertNotEquals(contact.get(journeyRecord.Primary_Contact__c).Outreach_Stage__c, journeyRecord.Outreach_Stage__c);  
            }
            else{
                System.assertEquals(contact.get(journeyRecord.Primary_Contact__c).Outreach_Stage__c, journeyRecord.Outreach_Stage__c);
            }
        }
        testJourneys[2].Outreach_Stage__c = 'Manual Outreach';
        update testJourneys[2];
        Contact contactRecord = [SELECT Id,Outreach_Stage__c FROM Contact WHERE Id =:testJourneys[2].Primary_Contact__c LIMIT 1]; 
        System.assertEquals(contactRecord.Outreach_Stage__c, testJourneys[2].Outreach_Stage__c);
    }
    
    private static List<Journey__c> getInsertedJourney(Integer size,List<Contact>contacts){
        List<Journey__c> testJourney = new List<Journey__c>();
        List<String> journeyStage = new List<String>{'Manual Outreach','NMD Drip','Call 1'};
            for(Integer i = 0 ; i<size; i++){
                testJourney.add(new Journey__c(
                    Name = 'journey' +i,
                    Outreach_Stage__c = journeyStage[i],
                    Primary_Contact__c = contacts[i].Id,
                    Status__c = 'Known',
                    NMD_Next_Contact_Date__c = System.Date.Today().addDays(1)
                ));    
            }
        return testJourney;
    }   
    
}